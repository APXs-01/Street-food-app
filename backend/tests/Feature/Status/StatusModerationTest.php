<?php

namespace Tests\Feature\Status;

use App\Enums\UserRole;
use App\Models\DailyStatus;
use App\Models\StatusComment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesSocialFixtures;
use Tests\TestCase;

class StatusModerationTest extends TestCase
{
    use CreatesSocialFixtures;
    use RefreshDatabase;

    private function hide(DailyStatus|StatusComment $item, string $reason = 'spam'): void
    {
        $moderator = User::factory()->withRole(UserRole::SuperAdmin)->create();

        $item->forceFill([
            'is_hidden' => true,
            'hidden_reason' => $reason,
            'moderated_by' => $moderator->id,
            'moderated_at' => now(),
        ])->save();
    }

    public function test_a_hidden_status_leaves_the_feed_but_not_the_authors_own_list(): void
    {
        $author = User::factory()->create();
        $friend = User::factory()->create();
        $this->befriend($author, $friend);

        $shown = $this->statusBy($author, 'still shown');
        $hidden = $this->statusBy($author, 'moderated away');
        $this->hide($hidden);

        Sanctum::actingAs($friend);
        $captions = collect($this->getJson('/api/statuses')->assertOk()->json('data'))->pluck('caption')->all();
        $this->assertSame(['still shown'], $captions);

        // Not even the author's own feed shows it...
        Sanctum::actingAs($author);
        $captions = collect($this->getJson('/api/statuses')->json('data'))->pluck('caption')->all();
        $this->assertSame(['still shown'], $captions);

        // ...but their own list does, flagged, so they are not left wondering.
        $mine = $this->getJson('/api/statuses?mine=1')->assertOk()->json('data');
        $this->assertCount(2, $mine);
        $this->assertSame(
            [true, false],
            collect($mine)->sortByDesc('id')->pluck('is_hidden')->values()->all(),
        );
    }

    public function test_only_the_author_ever_sees_the_hidden_flag(): void
    {
        $author = User::factory()->create();
        $friend = User::factory()->create();
        $this->befriend($author, $friend);
        $this->statusBy($author, 'visible to all');

        Sanctum::actingAs($friend);

        $this->getJson('/api/statuses')->assertJsonMissingPath('data.0.is_hidden');

        Sanctum::actingAs($author);

        $this->getJson('/api/statuses')->assertJsonPath('data.0.is_hidden', false);
    }

    public function test_a_hidden_status_is_a_404_for_everyone_but_its_author(): void
    {
        $author = User::factory()->create();
        $friend = User::factory()->create();
        $stranger = User::factory()->create();
        $this->befriend($author, $friend);
        $status = $this->statusBy($author, 'moderated away');
        $this->hide($status);

        foreach ([$friend, $stranger] as $viewer) {
            Sanctum::actingAs($viewer);

            $this->getJson("/api/statuses/{$status->id}")->assertNotFound();
            $this->postJson("/api/statuses/{$status->id}/like")->assertNotFound();
            $this->postJson("/api/statuses/{$status->id}/comments", ['body' => 'hello'])->assertNotFound();
        }

        Sanctum::actingAs($author);
        $this->getJson("/api/statuses/{$status->id}")
            ->assertOk()
            ->assertJsonPath('data.is_hidden', true);
    }

    public function test_the_author_cannot_interact_with_their_own_hidden_status_but_can_delete_it(): void
    {
        $author = User::factory()->create();
        $status = $this->statusBy($author);
        $this->hide($status);

        Sanctum::actingAs($author);

        $this->postJson("/api/statuses/{$status->id}/like")->assertForbidden();
        $this->postJson("/api/statuses/{$status->id}/comments", ['body' => 'bumping'])->assertForbidden();
        $this->deleteJson("/api/statuses/{$status->id}")->assertNoContent();
    }

    public function test_a_hidden_comment_disappears_from_the_status_and_its_count(): void
    {
        $author = User::factory()->create();
        $status = $this->statusBy($author);

        $kept = $status->comments()->create(['user_id' => User::factory()->create()->id, 'body' => 'kept']);
        $removed = $status->comments()->create(['user_id' => User::factory()->create()->id, 'body' => 'removed by a moderator']);
        $this->hide($removed);

        $viewer = User::factory()->create();
        $this->befriend($author, $viewer);

        Sanctum::actingAs($viewer);

        $this->getJson("/api/statuses/{$status->id}")
            ->assertOk()
            ->assertJsonPath('data.comments_count', 1)
            ->assertJsonPath('comments.meta.total', 1)
            ->assertJsonPath('comments.data.0.id', $kept->id)
            ->assertDontSee('removed by a moderator');

        // The feed count agrees.
        $this->getJson('/api/statuses')->assertJsonPath('data.0.comments_count', 1);
    }

    public function test_the_moderation_fields_cannot_be_set_through_the_api(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/statuses', [
            'caption' => 'trying my luck',
            'is_hidden' => true,
            'hidden_reason' => 'nope',
            'moderated_by' => 1,
        ])->assertCreated();

        $status = DailyStatus::firstOrFail();

        $this->assertFalse($status->is_hidden);
        $this->assertNull($status->hidden_reason);
        $this->assertNull($status->moderated_by);
    }
}
