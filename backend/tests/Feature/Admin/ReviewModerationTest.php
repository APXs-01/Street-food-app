<?php

namespace Tests\Feature\Admin;

use App\Models\Review;
use App\Models\ReviewReport;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\SignsInAdmin;
use Tests\TestCase;

class ReviewModerationTest extends TestCase
{
    use RefreshDatabase;
    use SignsInAdmin;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function review(?Vendor $vendor = null, array $attributes = [], ?User $author = null): Review
    {
        $vendor ??= Vendor::factory()->create();

        return Review::create($attributes + [
            'vendor_id' => $vendor->id,
            'user_id' => ($author ?? User::factory()->create())->id,
            'rating' => 4,
            'comment' => 'A review',
        ]);
    }

    private function report(Review $review, ?User $reporter = null, string $reason = 'spam', ?string $details = null): ReviewReport
    {
        return ReviewReport::create([
            'review_id' => $review->id,
            'reporter_id' => ($reporter ?? User::factory()->create())->id,
            'reason' => $reason,
            'details' => $details,
        ]);
    }

    /** What the public API says about a stall's reviews. */
    private function publicReviews(Vendor $stall)
    {
        Sanctum::actingAs(User::factory()->create());

        return $this->getJson("/api/vendors/{$stall->id}/reviews");
    }

    // ---- access ------------------------------------------------------------

    public function test_it_needs_an_admin(): void
    {
        $review = $this->review();

        $this->get('/admin/reviews')->assertRedirect(route('admin.login'));
        $this->get("/admin/reviews/{$review->id}")->assertRedirect(route('admin.login'));
        $this->patch("/admin/reviews/{$review->id}/hide")->assertRedirect(route('admin.login'));

        $this->actingAs(User::factory()->create());
        $this->get('/admin/reviews')->assertForbidden();
        $this->patch("/admin/reviews/{$review->id}/hide")->assertForbidden();
        $this->delete("/admin/reviews/{$review->id}")->assertForbidden();

        $this->assertFalse($review->fresh()->is_hidden);
        $this->assertModelExists($review);
    }

    // ---- listing -----------------------------------------------------------

    public function test_it_opens_on_the_reported_queue_most_reported_first(): void
    {
        $twice = $this->review(null, ['comment' => 'Reported twice']);
        $once = $this->review(null, ['comment' => 'Reported once']);
        $this->review(null, ['comment' => 'Never reported']);

        $this->report($once);
        $this->report($twice);
        $this->report($twice, null, 'offensive_language');

        $this->actingAsAdmin()
            ->get('/admin/reviews')
            ->assertOk()
            ->assertSee('Reported twice')
            ->assertSee('Reported once')
            ->assertDontSee('Never reported')
            ->assertSee('2 reports')
            ->assertViewHas('reviews', fn ($page) => $page->pluck('id')->all() === [$twice->id, $once->id])
            ->assertViewHas('counts', ['flagged' => 2, 'hidden' => 0, 'all' => 3]);
    }

    public function test_an_empty_queue_says_so(): void
    {
        $this->review();

        $this->actingAsAdmin()->get('/admin/reviews')->assertOk()->assertSee('Nothing has been reported.');
    }

    public function test_it_lists_all_or_only_hidden_reviews(): void
    {
        $admin = $this->makeAdmin();
        $visible = $this->review(null, ['comment' => 'A visible one']);
        $hidden = $this->review(null, ['comment' => 'A hidden one']);
        $hidden->hideBy($admin, 'spam');
        $bySuspended = $this->review(null, ['comment' => 'From a suspended author']);
        $bySuspended->user->forceFill(['is_active' => false])->save();

        $this->actingAsAdmin($admin);

        $this->get('/admin/reviews?scope=all')
            ->assertSee('A visible one')->assertSee('A hidden one')->assertSee('From a suspended author')
            ->assertSee('Author suspended');

        $this->get('/admin/reviews?scope=hidden')
            ->assertSee('A hidden one')
            ->assertDontSee('A visible one');
    }

    public function test_it_searches_and_filters_by_rating(): void
    {
        $stall = Vendor::factory()->create(['name' => 'Raju Kottu']);
        $author = User::factory()->create(['name' => 'Kaveen Perera']);
        $this->review($stall, ['comment' => 'Cold kottu', 'rating' => 2], $author);
        $this->review(null, ['comment' => 'Great hoppers', 'rating' => 5]);

        $this->actingAsAdmin();

        foreach (['Cold', 'Kaveen', 'Raju Kottu'] as $term) {
            $this->get('/admin/reviews?'.http_build_query(['scope' => 'all', 'q' => $term]))
                ->assertSee('Cold kottu')
                ->assertDontSee('Great hoppers');
        }

        $this->get('/admin/reviews?scope=all&rating=5')->assertSee('Great hoppers')->assertDontSee('Cold kottu');
        $this->get('/admin/reviews?scope=all&q=zzzz')->assertSee('No reviews match.');
    }

    public function test_it_rejects_bad_filters(): void
    {
        $this->actingAsAdmin()
            ->get('/admin/reviews?scope=nonsense&rating=9')
            ->assertSessionHasErrors(['scope', 'rating']);
    }

    public function test_it_is_paginated_with_the_scope_kept(): void
    {
        foreach (range(1, 30) as $i) {
            $this->review();
        }

        $this->actingAsAdmin()
            ->get('/admin/reviews?scope=all')
            ->assertViewHas('reviews', fn ($page) => $page->count() === 25 && $page->total() === 30)
            ->assertSee('scope=all&amp;page=2', false);
    }

    public function test_an_anonymous_reviews_real_author_is_shown_to_the_moderator(): void
    {
        $author = User::factory()->create(['name' => 'Secret Sally']);
        $this->review(null, ['is_anonymous' => true], $author);

        $this->actingAsAdmin()
            ->get('/admin/reviews?scope=all')
            ->assertSee('Secret Sally')
            ->assertSee('Posted anonymously');
    }

    // ---- detail ------------------------------------------------------------

    public function test_the_detail_page_shows_the_review_its_photos_and_its_reports(): void
    {
        $admin = $this->makeAdmin(['name' => 'Moderator Mo']);
        $author = User::factory()->create(['name' => 'Grumpy Gil']);
        $review = $this->review(null, [
            'comment' => 'Not for me at all',
            'observations' => ['unclean_area', 'no_gloves'],
        ], $author);
        $review->photos()->create(['path' => 'reviews/gil.jpg']);

        $this->report($review, User::factory()->create(['name' => 'Reporting Rita']), 'not_about_this_stall', 'Wrong stall entirely');
        $review->hideBy($admin, 'Under review');

        $this->actingAsAdmin($admin)
            ->get("/admin/reviews/{$review->id}")
            ->assertOk()
            ->assertSee('Not for me at all')
            ->assertSee('Grumpy Gil')
            ->assertSee('Unclean Area')
            ->assertSee('No Gloves')
            ->assertSee('reviews/gil.jpg', false)
            ->assertSee('Reporting Rita')
            ->assertSee('Not About This Stall')
            ->assertSee('Wrong stall entirely')
            ->assertSee('Hidden by a moderator')
            ->assertSee('Under review')
            ->assertSee('Moderator Mo');
    }

    public function test_a_missing_review_is_a_404(): void
    {
        $this->actingAsAdmin()->get('/admin/reviews/999999')->assertNotFound();
    }

    // ---- hide and unhide ---------------------------------------------------

    public function test_hiding_a_review_removes_it_from_the_public_and_from_the_star_rating(): void
    {
        $admin = $this->makeAdmin();
        $stall = Vendor::factory()->create();
        $keep = $this->review($stall, ['rating' => 5, 'comment' => 'Kept']);
        $target = $this->review($stall, ['rating' => 1, 'comment' => 'Hidden soon']);
        $stall->refreshRatingSnapshot();
        $this->assertEquals(3.0, $stall->fresh()->rating_average);

        $this->actingAsAdmin($admin)
            ->patch("/admin/reviews/{$target->id}/hide", ['reason' => 'Harassment'])
            ->assertRedirect()
            ->assertSessionHas('status');

        $target->refresh();
        $this->assertTrue($target->is_hidden);
        $this->assertSame('Harassment', $target->hidden_reason);
        $this->assertSame($admin->id, $target->moderated_by);
        $this->assertNotNull($target->moderated_at);

        // The stored star rating followed straight away.
        $this->assertSame(1, $stall->fresh()->reviews_count);
        $this->assertEquals(5.0, $stall->fresh()->rating_average);

        $this->publicReviews($stall)
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $keep->id)
            ->assertDontSee('Hidden soon');
    }

    public function test_the_reason_is_optional_and_capped(): void
    {
        $review = $this->review();
        $this->actingAsAdmin();

        $this->patch("/admin/reviews/{$review->id}/hide", ['reason' => str_repeat('a', 256)])
            ->assertSessionHasErrors('reason');
        $this->assertFalse($review->fresh()->is_hidden);

        $this->patch("/admin/reviews/{$review->id}/hide")->assertSessionHas('status');
        $this->assertTrue($review->fresh()->is_hidden);
        $this->assertNull($review->fresh()->hidden_reason);
    }

    public function test_unhiding_restores_the_review_and_the_star_rating(): void
    {
        $admin = $this->makeAdmin();
        $stall = Vendor::factory()->create();
        $this->review($stall, ['rating' => 5]);
        $target = $this->review($stall, ['rating' => 1]);
        $target->hideBy($admin, 'Mistake');
        $stall->refreshRatingSnapshot();
        $this->assertSame(1, $stall->fresh()->reviews_count);

        $other = $this->makeAdmin();
        $this->actingAsAdmin($other)->patch("/admin/reviews/{$target->id}/unhide")->assertSessionHas('status');

        $target->refresh();
        $this->assertFalse($target->is_hidden);
        $this->assertNull($target->hidden_reason);
        // Who acted last is kept.
        $this->assertSame($other->id, $target->moderated_by);

        $this->assertSame(2, $stall->fresh()->reviews_count);
        $this->assertEquals(3.0, $stall->fresh()->rating_average);
        $this->publicReviews($stall)->assertJsonCount(2, 'data');
    }

    public function test_unhiding_does_not_override_a_suspension(): void
    {
        $stall = Vendor::factory()->create();
        $review = $this->review($stall);
        $review->hideBy($this->makeAdmin());
        $review->user->forceFill(['is_active' => false])->save();

        $this->actingAsAdmin()->patch("/admin/reviews/{$review->id}/unhide")->assertSessionHas('status');

        $this->assertFalse($review->fresh()->is_hidden);
        // Still out of the public list: its author is suspended.
        $this->publicReviews($stall)->assertJsonCount(0, 'data');
    }

    // ---- dismiss -----------------------------------------------------------

    public function test_dismissing_clears_the_reports_and_leaves_the_review_alone(): void
    {
        $review = $this->review();
        $this->report($review);
        $this->report($review, null, 'other');

        $this->actingAsAdmin()
            ->delete("/admin/reviews/{$review->id}/reports")
            ->assertSessionHas('status', '2 reports dismissed. The review is unchanged.');

        $this->assertDatabaseCount('review_reports', 0);
        $this->assertFalse($review->fresh()->is_hidden);

        $this->get('/admin/reviews')->assertSee('Nothing has been reported.');
    }

    // ---- delete ------------------------------------------------------------

    public function test_deleting_removes_the_review_photos_and_reports_and_recalculates_the_rating(): void
    {
        $stall = Vendor::factory()->create();
        $kept = $this->review($stall, ['rating' => 5]);
        $doomed = $this->review($stall, ['rating' => 1]);
        Storage::disk('public')->put('reviews/doomed.jpg', 'x');
        Storage::disk('public')->put('reviews/kept.jpg', 'x');
        $doomed->photos()->create(['path' => 'reviews/doomed.jpg']);
        $kept->photos()->create(['path' => 'reviews/kept.jpg']);
        $this->report($doomed);
        $stall->refreshRatingSnapshot();

        $this->actingAsAdmin()
            ->delete("/admin/reviews/{$doomed->id}")
            ->assertRedirect(route('admin.reviews.index', ['scope' => 'all']))
            ->assertSessionHas('status', 'Review deleted.');

        $this->assertModelMissing($doomed);
        $this->assertDatabaseMissing('review_photos', ['review_id' => $doomed->id]);
        $this->assertDatabaseMissing('review_reports', ['review_id' => $doomed->id]);
        Storage::disk('public')->assertMissing('reviews/doomed.jpg');

        $this->assertModelExists($kept);
        Storage::disk('public')->assertExists('reviews/kept.jpg');

        $this->assertSame(1, $stall->fresh()->reviews_count);
        $this->assertEquals(5.0, $stall->fresh()->rating_average);
    }

    public function test_deleting_the_only_review_leaves_the_stall_unrated(): void
    {
        $stall = Vendor::factory()->create();
        $review = $this->review($stall);
        $stall->refreshRatingSnapshot();

        $this->actingAsAdmin()->delete("/admin/reviews/{$review->id}");

        $stall->refresh();
        $this->assertSame(0, $stall->reviews_count);
        $this->assertNull($stall->rating_average);
    }

    // ---- dashboard ---------------------------------------------------------

    public function test_the_dashboard_counts_reported_reviews(): void
    {
        $this->report($this->review());
        $this->report($this->review());
        $this->review();

        $this->actingAsAdmin()
            ->get('/admin')
            ->assertOk()
            ->assertSee('Reported reviews')
            ->assertViewHas('stats', fn (array $stats) => $stats['reported_reviews'] === 2);
    }
}
