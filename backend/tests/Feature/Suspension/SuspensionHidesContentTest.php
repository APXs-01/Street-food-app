<?php

namespace Tests\Feature\Suspension;

use App\Models\Review;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesSocialFixtures;
use Tests\TestCase;

/**
 * Suspending an account hides its public presence at query time. Nothing is
 * deleted, so reactivating brings everything back.
 */
class SuspensionHidesContentTest extends TestCase
{
    use CreatesSocialFixtures;
    use RefreshDatabase;

    private function suspend(User $user): void
    {
        $user->forceFill(['is_active' => false])->save();
    }

    private function reactivate(User $user): void
    {
        $user->forceFill(['is_active' => true])->save();
    }

    private function stall(): Vendor
    {
        return Vendor::factory()->create([
            'name' => 'Raju Kottu',
            'latitude' => 6.9271,
            'longitude' => 79.8612,
        ]);
    }

    private function nearby()
    {
        return $this->getJson('/api/map/nearby?lat=6.9271&lng=79.8612');
    }

    // ---- vendors ----------------------------------------------------------

    public function test_an_active_vendors_stall_is_visible_everywhere(): void
    {
        $stall = $this->stall();
        $item = $stall->menuItems()->create(['name' => 'Kottu', 'price' => 450]);
        Sanctum::actingAs(User::factory()->create());

        $this->nearby()->assertOk()->assertJsonCount(1, 'data');
        $this->getJson('/api/vendors')->assertOk()->assertJsonCount(1, 'data');
        $this->getJson('/api/vendors?q=Raju')->assertOk()->assertJsonCount(1, 'data');
        $this->getJson("/api/vendors/{$stall->id}")->assertOk();
        $this->getJson("/api/vendors/{$stall->id}/hygiene")->assertOk();
        $this->getJson("/api/vendors/{$stall->id}/reviews")->assertOk();
        $this->getJson("/api/menu-items?vendor_id={$stall->id}")->assertOk()->assertJsonCount(1, 'data');
        $this->getJson("/api/menu-items/{$item->id}")->assertOk();
        $this->postJson("/api/vendors/{$stall->id}/follow")->assertOk();
    }

    public function test_a_suspended_vendors_stall_disappears_from_discovery(): void
    {
        $stall = $this->stall();
        $this->suspend($stall->user);
        Sanctum::actingAs(User::factory()->create());

        $this->nearby()->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/vendors')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/vendors?q=Raju')->assertOk()->assertJsonCount(0, 'data');

        // Nothing was deleted.
        $this->assertDatabaseHas('vendors', ['id' => $stall->id]);
    }

    public function test_a_suspended_vendors_stall_is_a_404_by_direct_access(): void
    {
        $stall = $this->stall();
        $item = $stall->menuItems()->create(['name' => 'Kottu', 'price' => 450]);
        $this->suspend($stall->user);
        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/vendors/{$stall->id}")->assertNotFound();
        $this->getJson("/api/vendors/{$stall->id}/hygiene")->assertNotFound();
        $this->getJson("/api/vendors/{$stall->id}/reviews")->assertNotFound();
        $this->getJson("/api/vendors/{$stall->id}/reviews/mine")->assertNotFound();
        $this->postJson("/api/vendors/{$stall->id}/reviews", ['rating' => 5])->assertNotFound();
        $this->postJson("/api/vendors/{$stall->id}/follow")->assertNotFound();
        $this->getJson("/api/menu-items?vendor_id={$stall->id}")->assertNotFound();
        $this->getJson("/api/menu-items/{$item->id}")->assertNotFound();

        $this->assertDatabaseCount('reviews', 0);
    }

    public function test_reactivating_the_owner_brings_the_stall_back_by_itself(): void
    {
        $stall = $this->stall();
        $this->suspend($stall->user);
        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/vendors/{$stall->id}")->assertNotFound();
        $this->nearby()->assertJsonCount(0, 'data');

        $this->reactivate($stall->user);

        $this->getJson("/api/vendors/{$stall->id}")->assertOk()->assertJsonPath('data.name', 'Raju Kottu');
        $this->getJson("/api/vendors/{$stall->id}/hygiene")->assertOk();
        $this->nearby()->assertJsonCount(1, 'data');
        $this->getJson('/api/vendors?q=Raju')->assertJsonCount(1, 'data');
    }

    public function test_a_suspended_stalls_statuses_leave_its_followers_feeds_and_return_with_it(): void
    {
        $stall = $this->stall();
        $follower = User::factory()->create();
        $follower->followedVendors()->attach($stall);
        $this->statusBy($stall->user, 'Fresh batch', ['vendor_id' => $stall->id]);

        Sanctum::actingAs($follower);
        $this->getJson('/api/statuses')->assertJsonCount(1, 'data');

        $this->suspend($stall->user);
        $this->getJson('/api/statuses')->assertJsonCount(0, 'data');

        $this->reactivate($stall->user);
        $this->getJson('/api/statuses')->assertJsonCount(1, 'data');

        // The follow itself was never touched.
        $this->assertSame(1, $follower->followedVendors()->count());
    }

    public function test_a_suspended_stall_cannot_be_tagged_and_existing_tags_stop_showing(): void
    {
        $stall = $this->stall();
        $author = User::factory()->create();
        $friend = User::factory()->create();
        $this->befriend($author, $friend);

        Sanctum::actingAs($author);
        $this->postJson('/api/statuses', ['caption' => 'Loved it', 'vendor_id' => $stall->id])
            ->assertCreated()
            ->assertJsonPath('data.vendor.id', $stall->id);

        $this->suspend($stall->user);

        $this->postJson('/api/statuses', ['caption' => 'Again', 'vendor_id' => $stall->id])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('vendor_id');

        Sanctum::actingAs($friend);
        $this->getJson('/api/statuses')->assertJsonPath('data.0.vendor', null);
    }

    // ---- customers --------------------------------------------------------

    public function test_a_suspended_customers_reviews_stop_counting_and_return_on_reactivation(): void
    {
        $stall = $this->stall();
        $happy = User::factory()->create(['name' => 'Happy Hana']);
        $grumpy = User::factory()->create(['name' => 'Grumpy Gil']);

        Review::create(['vendor_id' => $stall->id, 'user_id' => $happy->id, 'rating' => 5, 'comment' => 'Loved it']);
        $grumpyReview = Review::create(['vendor_id' => $stall->id, 'user_id' => $grumpy->id, 'rating' => 1, 'comment' => 'Not for me']);
        $grumpyReview->photos()->create(['path' => 'reviews/grumpy.jpg']);
        $stall->refreshRatingSnapshot();

        Sanctum::actingAs(User::factory()->create());

        $before = $this->getJson("/api/vendors/{$stall->id}/reviews")->assertOk();
        $before->assertJsonCount(2, 'data')->assertJsonPath('photos.total', 1);
        $this->assertEquals(3.0, $before->json('summary.average'));

        // Suspending updates the stored star rating straight away.
        $this->suspend($grumpy);

        $this->assertSame(1, $stall->fresh()->reviews_count);
        $this->assertEquals(5.0, $stall->fresh()->rating_average);

        $during = $this->getJson("/api/vendors/{$stall->id}/reviews")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.comment', 'Loved it')
            ->assertJsonPath('summary.count', 1)
            ->assertJsonPath('photos.total', 0)
            ->assertDontSee('Grumpy Gil')
            ->assertDontSee('Not for me');
        $this->assertEquals([5 => 1, 4 => 0, 3 => 0, 2 => 0, 1 => 0], $during->json('summary.distribution'));

        // Nothing was deleted, so lifting the suspension restores it.
        $this->assertDatabaseHas('reviews', ['id' => $grumpyReview->id]);
        $this->reactivate($grumpy);

        $this->assertSame(2, $stall->fresh()->reviews_count);
        $this->assertEquals(3.0, $stall->fresh()->rating_average);
        $this->getJson("/api/vendors/{$stall->id}/reviews")->assertJsonCount(2, 'data')->assertJsonPath('photos.total', 1);
    }

    public function test_the_map_pins_star_rating_follows_the_visible_reviews(): void
    {
        $stall = $this->stall();
        $reviewer = User::factory()->create();
        Review::create(['vendor_id' => $stall->id, 'user_id' => $reviewer->id, 'rating' => 2, 'comment' => 'Meh']);
        $stall->refreshRatingSnapshot();

        Sanctum::actingAs(User::factory()->create());

        $this->assertEquals(2.0, $this->nearby()->json('data.0.star_rating'));

        $this->suspend($reviewer);

        // The only review is gone from the count, so the stall is unrated again.
        $this->assertNull($this->nearby()->json('data.0.star_rating'));
    }

    public function test_a_suspended_customers_statuses_vanish_and_return_with_them(): void
    {
        $author = User::factory()->create();
        $friend = User::factory()->create();
        $stranger = User::factory()->create();
        $this->befriend($author, $friend);

        $public = $this->statusBy($author, 'public post');
        $private = $this->statusBy($author, 'friends post', ['audience' => 'friends']);

        Sanctum::actingAs($friend);
        $this->getJson('/api/statuses')->assertJsonCount(2, 'data');

        $this->suspend($author);

        $this->getJson('/api/statuses')->assertJsonCount(0, 'data');
        $this->getJson("/api/statuses/{$private->id}")->assertNotFound();
        $this->postJson("/api/statuses/{$private->id}/like")->assertNotFound();
        $this->postJson("/api/statuses/{$private->id}/comments", ['body' => 'hello'])->assertNotFound();

        Sanctum::actingAs($stranger);
        $this->getJson("/api/statuses/{$public->id}")->assertNotFound();

        $this->reactivate($author);

        $this->getJson("/api/statuses/{$public->id}")->assertOk();
        Sanctum::actingAs($friend);
        $this->getJson('/api/statuses')->assertJsonCount(2, 'data');
    }

    public function test_a_suspended_customers_comments_vanish_from_the_status_and_its_count(): void
    {
        $author = User::factory()->create();
        $suspended = User::factory()->create();
        $status = $this->statusBy($author);

        $status->comments()->create(['user_id' => $author->id, 'body' => 'from the author']);
        $status->comments()->create(['user_id' => $suspended->id, 'body' => 'from someone later suspended']);

        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/statuses/{$status->id}")->assertJsonPath('comments.meta.total', 2);

        $this->suspend($suspended);

        $this->getJson("/api/statuses/{$status->id}")
            ->assertJsonPath('data.comments_count', 1)
            ->assertJsonPath('comments.meta.total', 1)
            ->assertDontSee('from someone later suspended');

        $this->reactivate($suspended);

        $this->getJson("/api/statuses/{$status->id}")->assertJsonPath('comments.meta.total', 2);
    }

    // ---- what suspension does not touch ------------------------------------

    public function test_active_users_content_is_unaffected_by_someone_elses_suspension(): void
    {
        $stall = $this->stall();
        $active = User::factory()->create();
        $suspended = User::factory()->create();
        $this->befriend($active, $suspended);

        Review::create(['vendor_id' => $stall->id, 'user_id' => $active->id, 'rating' => 4, 'comment' => 'Good']);
        $this->statusBy($active, 'still here');
        $stall->refreshRatingSnapshot();

        $this->suspend($suspended);

        Sanctum::actingAs(User::factory()->create());
        $this->getJson("/api/vendors/{$stall->id}/reviews")->assertJsonCount(1, 'data');
        $this->assertEquals(4.0, $stall->fresh()->rating_average);

        $friendOfActive = User::factory()->create();
        $this->befriend($active, $friendOfActive);
        Sanctum::actingAs($friendOfActive);
        $this->getJson('/api/statuses')->assertJsonCount(1, 'data');
    }
}
