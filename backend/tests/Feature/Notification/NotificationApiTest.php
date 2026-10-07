<?php

namespace Tests\Feature\Notification;

use App\Models\AppNotification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationApiTest extends TestCase
{
    use RefreshDatabase;

    /**
     * @param  array<string, mixed>  $overrides
     */
    private function notification(User $user, array $overrides = []): AppNotification
    {
        return $user->appNotifications()->create($overrides + [
            'type' => 'status_like',
            'title' => 'Someone liked your status',
            'body' => null,
            'data' => ['status_id' => 1],
        ]);
    }

    public function test_it_requires_a_token(): void
    {
        $this->getJson('/api/notifications')->assertUnauthorized();
        $this->patchJson('/api/notifications/read-all')->assertUnauthorized();
    }

    public function test_it_lists_only_my_notifications_newest_first_with_the_unread_count(): void
    {
        $me = User::factory()->create();
        $other = User::factory()->create();

        $this->travelTo(now()->subHours(2));
        $this->notification($me, ['title' => 'older']);
        $this->travelTo(now()->addHour());
        $this->notification($me, ['title' => 'newer']);
        $this->travelBack();
        $this->notification($other, ['title' => 'not mine']);

        Sanctum::actingAs($me);

        $this->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.title', 'newer')
            ->assertJsonPath('data.1.title', 'older')
            ->assertJsonPath('meta.total', 2)
            ->assertJsonPath('unread_count', 2);
    }

    public function test_each_notification_has_the_documented_shape(): void
    {
        $me = User::factory()->create();
        $this->notification($me, [
            'type' => 'friend_request',
            'title' => 'Sam sent you a friend request',
            'data' => ['friendship_id' => 4, 'actor_id' => 9, 'actor_name' => 'Sam'],
        ]);

        Sanctum::actingAs($me);

        $this->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonStructure(['data' => [['id', 'type', 'title', 'body', 'data', 'is_read', 'read_at', 'created_at']]])
            ->assertJsonPath('data.0.type', 'friend_request')
            ->assertJsonPath('data.0.is_read', false)
            ->assertJsonPath('data.0.data.actor_name', 'Sam');
    }

    public function test_it_can_filter_by_unread_and_by_type(): void
    {
        $me = User::factory()->create();
        $read = $this->notification($me, ['title' => 'read one']);
        $read->markAsRead();
        $this->notification($me, ['title' => 'unread like']);
        $this->notification($me, ['type' => 'friend_request', 'title' => 'unread request']);

        Sanctum::actingAs($me);

        $this->getJson('/api/notifications?unread=1')->assertJsonCount(2, 'data')->assertJsonPath('unread_count', 2);
        $this->getJson('/api/notifications?unread=true')->assertJsonCount(2, 'data');
        $this->getJson('/api/notifications?type=friend_request')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'unread request');

        $this->getJson('/api/notifications?type=nonsense')->assertUnprocessable()->assertJsonValidationErrors('type');
        $this->getJson('/api/notifications?unread=maybe')->assertUnprocessable()->assertJsonValidationErrors('unread');
    }

    public function test_it_is_paginated(): void
    {
        $me = User::factory()->create();

        foreach (range(1, 3) as $i) {
            $this->notification($me, ['title' => "n{$i}"]);
        }

        Sanctum::actingAs($me);

        $this->getJson('/api/notifications?per_page=2&page=2')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('meta.total', 3);
    }

    public function test_one_notification_can_be_marked_read_and_it_is_idempotent(): void
    {
        $me = User::factory()->create();
        $notification = $this->notification($me);

        Sanctum::actingAs($me);

        $this->travelTo(now()->subMinutes(10));
        $this->patchJson("/api/notifications/{$notification->id}/read")
            ->assertOk()
            ->assertJsonPath('data.is_read', true);

        $firstReadAt = $notification->fresh()->read_at;
        $this->assertNotNull($firstReadAt);

        $this->travelBack();
        $this->patchJson("/api/notifications/{$notification->id}/read")->assertOk();

        $this->assertTrue($notification->fresh()->read_at->equalTo($firstReadAt));
        $this->getJson('/api/notifications')->assertJsonPath('unread_count', 0);
    }

    public function test_someone_elses_notification_is_not_found(): void
    {
        $owner = User::factory()->create();
        $notification = $this->notification($owner);

        Sanctum::actingAs(User::factory()->create());

        $this->patchJson("/api/notifications/{$notification->id}/read")->assertNotFound();
        $this->patchJson('/api/notifications/999999/read')->assertNotFound();

        $this->assertNull($notification->fresh()->read_at);
    }

    public function test_read_all_marks_only_my_unread_notifications(): void
    {
        $me = User::factory()->create();
        $other = User::factory()->create();

        $alreadyRead = $this->notification($me);
        $alreadyRead->markAsRead();
        $this->notification($me);
        $this->notification($me);
        $theirs = $this->notification($other);

        Sanctum::actingAs($me);

        $this->patchJson('/api/notifications/read-all')->assertOk()->assertJsonPath('updated', 2);
        $this->patchJson('/api/notifications/read-all')->assertOk()->assertJsonPath('updated', 0);

        $this->assertSame(0, $me->appNotifications()->unread()->count());
        $this->assertNull($theirs->fresh()->read_at);
    }
}
