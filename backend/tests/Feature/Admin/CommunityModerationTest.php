<?php

namespace Tests\Feature\Admin;

use App\Models\DailyStatus;
use App\Models\StatusComment;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesSocialFixtures;
use Tests\Concerns\SignsInAdmin;
use Tests\TestCase;

class CommunityModerationTest extends TestCase
{
    use CreatesSocialFixtures;
    use RefreshDatabase;
    use SignsInAdmin;

    private function comment(DailyStatus $status, string $body = 'A comment', ?User $author = null): StatusComment
    {
        return $status->comments()->create(['user_id' => ($author ?? User::factory()->create())->id, 'body' => $body]);
    }

    // ---- access ------------------------------------------------------------

    public function test_it_needs_an_admin(): void
    {
        $status = $this->statusBy(User::factory()->create());

        $this->get('/admin/community')->assertRedirect(route('admin.login'));
        $this->patch("/admin/community/statuses/{$status->id}/hide")->assertRedirect(route('admin.login'));

        $this->actingAs(User::factory()->create());
        $this->get('/admin/community')->assertForbidden();
        $this->patch("/admin/community/statuses/{$status->id}/hide")->assertForbidden();

        $this->assertFalse($status->fresh()->is_hidden);
    }

    // ---- statuses ----------------------------------------------------------

    public function test_it_lists_statuses_with_their_state_and_context(): void
    {
        $admin = $this->makeAdmin();
        $stall = Vendor::factory()->create(['name' => 'Raju Kottu']);

        $live = $this->statusBy(User::factory()->create(['name' => 'Kaveen']), 'Fresh batch', [
            'vendor_id' => $stall->id,
            'location_label' => 'Galle Face Green',
        ]);
        $hidden = $this->statusBy(User::factory()->create(), 'Something rude');
        $hidden->hideBy($admin, 'Abusive');
        $suspended = $this->statusBy(User::factory()->create(['name' => 'Suspended Sam']), 'By a suspended user');
        $suspended->user->forceFill(['is_active' => false])->save();
        $this->statusBy(User::factory()->create(), 'With a photo', ['media_path' => 'statuses/1/pic.jpg', 'media_type' => 'image']);

        $this->travelTo(now()->subHours(30));
        $this->statusBy(User::factory()->create(), 'An old one');
        $this->travelBack();

        $this->actingAsAdmin($admin)
            ->get('/admin/community')
            ->assertOk()
            ->assertSee('Fresh batch')
            ->assertSee('Galle Face Green')
            ->assertSee('Raju Kottu')
            ->assertSee('Something rude')
            ->assertSee('Abusive')
            ->assertSee('By a suspended user')
            ->assertSee('Suspended')
            ->assertSee('statuses/1/pic.jpg', false)
            ->assertSee('Expired')
            ->assertSee('Live')
            ->assertViewHas('hiddenCounts', ['statuses' => 1, 'comments' => 0]);
    }

    public function test_it_filters_and_searches_statuses(): void
    {
        $admin = $this->makeAdmin();
        $this->statusBy(User::factory()->create(['name' => 'Kaveen Perera']), 'Kottu night');
        $hidden = $this->statusBy(User::factory()->create(), 'Rude hopper post', ['location_label' => 'Fort']);
        $hidden->hideBy($admin);

        $this->actingAsAdmin($admin);

        $this->get('/admin/community?state=hidden')->assertSee('Rude hopper post')->assertDontSee('Kottu night');
        $this->get('/admin/community?state=visible')->assertSee('Kottu night')->assertDontSee('Rude hopper post');

        foreach (['Kottu', 'Kaveen'] as $term) {
            $this->get('/admin/community?q='.$term)->assertSee('Kottu night')->assertDontSee('Rude hopper post');
        }
        $this->get('/admin/community?q=Fort')->assertSee('Rude hopper post');
        $this->get('/admin/community?q=zzzz')->assertSee('No statuses match.');
    }

    public function test_it_rejects_bad_filters(): void
    {
        $this->actingAsAdmin()
            ->get('/admin/community?type=posts&state=maybe')
            ->assertSessionHasErrors(['type', 'state']);
    }

    public function test_it_is_paginated_with_the_tab_and_filters_kept(): void
    {
        $author = User::factory()->create();

        foreach (range(1, 30) as $i) {
            $this->statusBy($author, "Post {$i}");
        }

        $this->actingAsAdmin()
            ->get('/admin/community?state=visible')
            ->assertViewHas('items', fn ($page) => $page->count() === 25 && $page->total() === 30)
            ->assertSee('state=visible&amp;page=2', false);
    }

    public function test_hiding_a_status_removes_it_from_the_public_api(): void
    {
        $admin = $this->makeAdmin();
        $author = User::factory()->create();
        $friend = User::factory()->create();
        $this->befriend($author, $friend);
        $status = $this->statusBy($author, 'Judge me');

        $this->actingAsAdmin($admin)
            ->patch("/admin/community/statuses/{$status->id}/hide", ['reason' => 'Harassment'])
            ->assertSessionHas('status');

        $status->refresh();
        $this->assertTrue($status->is_hidden);
        $this->assertSame('Harassment', $status->hidden_reason);
        $this->assertSame($admin->id, $status->moderated_by);
        $this->assertNotNull($status->moderated_at);

        Sanctum::actingAs($friend);
        $this->getJson('/api/statuses')->assertJsonCount(0, 'data');
        $this->getJson("/api/statuses/{$status->id}")->assertNotFound();
    }

    public function test_unhiding_a_status_brings_it_back(): void
    {
        $admin = $this->makeAdmin();
        $author = User::factory()->create();
        $friend = User::factory()->create();
        $this->befriend($author, $friend);
        $status = $this->statusBy($author, 'Judge me');
        $status->hideBy($admin, 'Mistake');

        $this->actingAsAdmin($admin)
            ->patch("/admin/community/statuses/{$status->id}/unhide")
            ->assertSessionHas('status', 'Status restored.');

        $status->refresh();
        $this->assertFalse($status->is_hidden);
        $this->assertNull($status->hidden_reason);
        $this->assertSame($admin->id, $status->moderated_by);

        Sanctum::actingAs($friend);
        $this->getJson('/api/statuses')->assertJsonCount(1, 'data');
    }

    public function test_the_reason_is_optional_and_capped(): void
    {
        $status = $this->statusBy(User::factory()->create());
        $this->actingAsAdmin();

        $this->patch("/admin/community/statuses/{$status->id}/hide", ['reason' => str_repeat('a', 256)])
            ->assertSessionHasErrors('reason');
        $this->assertFalse($status->fresh()->is_hidden);

        $this->patch("/admin/community/statuses/{$status->id}/hide")->assertSessionHas('status');
        $this->assertTrue($status->fresh()->is_hidden);
        $this->assertNull($status->fresh()->hidden_reason);
    }

    public function test_a_missing_status_or_comment_is_a_404(): void
    {
        $this->actingAsAdmin();

        $this->patch('/admin/community/statuses/999999/hide')->assertNotFound();
        $this->patch('/admin/community/comments/999999/hide')->assertNotFound();
    }

    // ---- comments ----------------------------------------------------------

    public function test_it_lists_comments_with_the_status_they_are_on(): void
    {
        $admin = $this->makeAdmin();
        $status = $this->statusBy(User::factory()->create(['name' => 'Status Author']), 'The original post');
        $this->comment($status, 'A friendly comment', User::factory()->create(['name' => 'Kind Kim']));
        $rude = $this->comment($status, 'Something rude');
        $rude->hideBy($admin, 'Abusive');

        $this->actingAsAdmin($admin)
            ->get('/admin/community?type=comments')
            ->assertOk()
            ->assertSee('A friendly comment')
            ->assertSee('Kind Kim')
            ->assertSee('Something rude')
            ->assertSee('Abusive')
            ->assertSee('Status Author')
            ->assertSee('The original post')
            ->assertViewHas('hiddenCounts', ['statuses' => 0, 'comments' => 1]);
    }

    public function test_it_filters_and_searches_comments(): void
    {
        $admin = $this->makeAdmin();
        $status = $this->statusBy(User::factory()->create());
        $this->comment($status, 'Lovely kottu', User::factory()->create(['name' => 'Kaveen Perera']));
        $this->comment($status, 'Rude words')->hideBy($admin);

        $this->actingAsAdmin($admin);

        $this->get('/admin/community?type=comments&state=hidden')->assertSee('Rude words')->assertDontSee('Lovely kottu');
        $this->get('/admin/community?type=comments&state=visible')->assertSee('Lovely kottu')->assertDontSee('Rude words');
        $this->get('/admin/community?type=comments&q=Kaveen')->assertSee('Lovely kottu')->assertDontSee('Rude words');
        $this->get('/admin/community?type=comments&q=zzzz')->assertSee('No comments match.');
    }

    public function test_hiding_a_comment_removes_it_from_the_status_and_its_count(): void
    {
        $admin = $this->makeAdmin();
        $viewer = User::factory()->create();
        $status = $this->statusBy(User::factory()->create());
        $this->comment($status, 'Fine');
        $rude = $this->comment($status, 'Not fine');

        $this->actingAsAdmin($admin)
            ->patch("/admin/community/comments/{$rude->id}/hide", ['reason' => 'Abusive'])
            ->assertSessionHas('status');

        $rude->refresh();
        $this->assertTrue($rude->is_hidden);
        $this->assertSame('Abusive', $rude->hidden_reason);
        $this->assertSame($admin->id, $rude->moderated_by);

        Sanctum::actingAs($viewer);
        $this->getJson("/api/statuses/{$status->id}")
            ->assertJsonPath('data.comments_count', 1)
            ->assertJsonPath('comments.meta.total', 1)
            ->assertDontSee('Not fine');
    }

    public function test_unhiding_a_comment_restores_it_and_its_count(): void
    {
        $admin = $this->makeAdmin();
        $viewer = User::factory()->create();
        $status = $this->statusBy(User::factory()->create());
        $this->comment($status, 'Fine');
        $rude = $this->comment($status, 'Not fine');
        $rude->hideBy($admin, 'Mistake');

        $this->actingAsAdmin($admin)
            ->patch("/admin/community/comments/{$rude->id}/unhide")
            ->assertSessionHas('status', 'Comment restored.');

        $this->assertFalse($rude->fresh()->is_hidden);
        $this->assertNull($rude->fresh()->hidden_reason);

        Sanctum::actingAs($viewer);
        $this->getJson("/api/statuses/{$status->id}")->assertJsonPath('data.comments_count', 2);
    }

    public function test_hiding_a_comment_does_not_touch_the_status_or_other_comments(): void
    {
        $status = $this->statusBy(User::factory()->create());
        $kept = $this->comment($status, 'Kept');
        $hidden = $this->comment($status, 'Hidden');

        $this->actingAsAdmin()->patch("/admin/community/comments/{$hidden->id}/hide");

        $this->assertFalse($status->fresh()->is_hidden);
        $this->assertFalse($kept->fresh()->is_hidden);
        $this->assertTrue($hidden->fresh()->is_hidden);
    }
}
