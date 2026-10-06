<?php

namespace Tests\Feature\Friend;

use App\Enums\FriendshipStatus;
use App\Models\Friendship;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesSocialFixtures;
use Tests\TestCase;

class FriendshipTest extends TestCase
{
    use CreatesSocialFixtures;
    use RefreshDatabase;

    private function pendingRequest(User $from, User $to): Friendship
    {
        return Friendship::create([
            'requester_id' => $from->id,
            'addressee_id' => $to->id,
            'status' => FriendshipStatus::Pending,
        ]);
    }

    public function test_a_customer_can_send_a_request_by_id_or_username(): void
    {
        $me = User::factory()->create();
        $byId = User::factory()->create();
        $byName = User::factory()->create(['username' => 'maya_bites']);
        Sanctum::actingAs($me);

        $this->postJson('/api/friends', ['user_id' => $byId->id])
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.direction', 'outgoing')
            ->assertJsonPath('data.user.id', $byId->id);

        $this->postJson('/api/friends', ['username' => '@maya_bites'])
            ->assertCreated()
            ->assertJsonPath('data.user.id', $byName->id);

        $this->assertDatabaseCount('friendships', 2);
    }

    public function test_the_recipient_sees_the_request_and_can_accept_it(): void
    {
        $sender = User::factory()->create();
        $me = User::factory()->create();
        $friendship = $this->pendingRequest($sender, $me);

        Sanctum::actingAs($me);

        $this->getJson('/api/friends/requests')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.direction', 'incoming')
            ->assertJsonPath('data.0.user.id', $sender->id);

        $this->patchJson("/api/friends/{$friendship->id}", ['status' => 'accepted'])
            ->assertOk()
            ->assertJsonPath('data.status', 'accepted');

        $this->assertTrue($me->isFriendsWith($sender->id));
        $this->assertTrue($sender->isFriendsWith($me->id));
        $this->getJson('/api/friends/requests')->assertJsonCount(0, 'data');
    }

    public function test_only_the_recipient_can_answer_and_only_once(): void
    {
        $sender = User::factory()->create();
        $recipient = User::factory()->create();
        $friendship = $this->pendingRequest($sender, $recipient);

        Sanctum::actingAs($sender);
        $this->patchJson("/api/friends/{$friendship->id}", ['status' => 'accepted'])->assertForbidden();

        Sanctum::actingAs(User::factory()->create());
        $this->patchJson("/api/friends/{$friendship->id}", ['status' => 'accepted'])->assertForbidden();

        Sanctum::actingAs($recipient);
        $this->patchJson("/api/friends/{$friendship->id}", ['status' => 'maybe'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');
        $this->patchJson("/api/friends/{$friendship->id}", ['status' => 'accepted'])->assertOk();
        $this->patchJson("/api/friends/{$friendship->id}", ['status' => 'declined'])
            ->assertStatus(409)
            ->assertJsonPath('friendship_id', $friendship->id);
    }

    public function test_only_customers_can_use_the_friend_network(): void
    {
        $customer = User::factory()->create();

        foreach ([User::factory()->vendor()->create(), User::factory()->inspector()->create()] as $user) {
            Sanctum::actingAs($user);
            $this->postJson('/api/friends', ['user_id' => $customer->id])->assertForbidden();
        }

        // Nor can a customer add one.
        $vendor = Vendor::factory()->create();
        Sanctum::actingAs($customer);
        $this->postJson('/api/friends', ['user_id' => $vendor->user_id])->assertNotFound();
        $this->postJson('/api/friends', ['user_id' => User::factory()->create(['is_active' => false])->id])->assertNotFound();
        $this->postJson('/api/friends', ['user_id' => 99999])->assertNotFound();
    }

    public function test_you_cannot_add_yourself_and_need_someone_to_add(): void
    {
        $me = User::factory()->create(['username' => 'me_myself']);
        Sanctum::actingAs($me);

        $this->postJson('/api/friends', ['user_id' => $me->id])->assertUnprocessable();
        $this->postJson('/api/friends', ['username' => 'me_myself'])->assertUnprocessable();
        $this->postJson('/api/friends', [])->assertUnprocessable()->assertJsonValidationErrors(['user_id', 'username']);
    }

    public function test_resending_a_pending_request_is_harmless(): void
    {
        $me = User::factory()->create();
        $target = User::factory()->create();
        Sanctum::actingAs($me);

        $first = $this->postJson('/api/friends', ['user_id' => $target->id])->assertCreated();

        $this->postJson('/api/friends', ['user_id' => $target->id])
            ->assertOk()
            ->assertJsonPath('data.id', $first->json('data.id'));

        $this->assertDatabaseCount('friendships', 1);
    }

    public function test_asking_someone_who_already_asked_you_points_to_their_request(): void
    {
        $me = User::factory()->create();
        $them = User::factory()->create(['name' => 'Sam']);
        $theirs = $this->pendingRequest($them, $me);
        Sanctum::actingAs($me);

        $this->postJson('/api/friends', ['user_id' => $them->id])
            ->assertStatus(409)
            ->assertJsonPath('friendship_id', $theirs->id);

        $this->assertDatabaseCount('friendships', 1);
    }

    public function test_existing_friends_get_a_friendly_conflict_in_either_direction(): void
    {
        $me = User::factory()->create();
        $them = User::factory()->create();
        $friendship = $this->befriend($them, $me);
        Sanctum::actingAs($me);

        $this->postJson('/api/friends', ['user_id' => $them->id])
            ->assertStatus(409)
            ->assertJsonPath('message', 'You are already friends.')
            ->assertJsonPath('friendship_id', $friendship->id);
    }

    public function test_a_declined_request_stays_declined_and_the_sender_still_sees_pending(): void
    {
        $sender = User::factory()->create();
        $recipient = User::factory()->create();

        Sanctum::actingAs($sender);
        $id = $this->postJson('/api/friends', ['user_id' => $recipient->id])->json('data.id');

        Sanctum::actingAs($recipient);
        $this->patchJson("/api/friends/{$id}", ['status' => 'declined'])
            ->assertOk()
            ->assertJsonPath('data.status', 'declined');

        // The sender asks again: same row, still shown as pending, nothing reopened.
        Sanctum::actingAs($sender);
        $this->postJson('/api/friends', ['user_id' => $recipient->id])
            ->assertOk()
            ->assertJsonPath('data.id', $id)
            ->assertJsonPath('data.status', 'pending');

        $this->assertSame(FriendshipStatus::Declined, Friendship::findOrFail($id)->status);
        $this->assertDatabaseCount('friendships', 1);

        Sanctum::actingAs($recipient);
        $this->getJson('/api/friends/requests')->assertJsonCount(0, 'data');
    }

    public function test_someone_you_declined_can_still_be_asked_by_you(): void
    {
        $me = User::factory()->create();
        $them = User::factory()->create();
        $theirs = $this->pendingRequest($them, $me);
        $theirs->forceFill(['status' => FriendshipStatus::Declined, 'responded_at' => now()])->save();

        Sanctum::actingAs($me);

        $this->postJson('/api/friends', ['user_id' => $them->id])
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending');

        $this->assertDatabaseCount('friendships', 2);
    }

    public function test_the_friend_list_holds_accepted_friends_only(): void
    {
        $me = User::factory()->create();
        $sentAndAccepted = User::factory()->create(['name' => 'Accepted A']);
        $receivedAndAccepted = User::factory()->create(['name' => 'Accepted B']);
        $pendingOut = User::factory()->create();
        $pendingIn = User::factory()->create();
        $declined = User::factory()->create();

        $this->befriend($me, $sentAndAccepted);
        $this->befriend($receivedAndAccepted, $me);
        $this->pendingRequest($me, $pendingOut);
        $this->pendingRequest($pendingIn, $me);
        $this->pendingRequest($declined, $me)->forceFill(['status' => FriendshipStatus::Declined])->save();

        Sanctum::actingAs($me);

        $response = $this->getJson('/api/friends')->assertOk()->assertJsonCount(2, 'data');

        $this->assertEqualsCanonicalizing(
            ['Accepted A', 'Accepted B'],
            collect($response->json('data'))->pluck('user.name')->all(),
        );
    }

    public function test_either_side_can_unfriend_and_visibility_ends_with_it(): void
    {
        $author = User::factory()->create();
        $friend = User::factory()->create();
        $friendship = $this->befriend($author, $friend);
        $private = $this->statusBy($author, 'private', ['audience' => 'friends']);

        Sanctum::actingAs($friend);
        $this->getJson("/api/statuses/{$private->id}")->assertOk();

        $this->deleteJson("/api/friends/{$friendship->id}")->assertNoContent();

        $this->getJson("/api/statuses/{$private->id}")->assertNotFound();
        $this->assertDatabaseCount('friendships', 0);
    }

    public function test_a_sender_can_withdraw_a_pending_request_but_the_recipient_cannot_delete_it(): void
    {
        $sender = User::factory()->create();
        $recipient = User::factory()->create();
        $friendship = $this->pendingRequest($sender, $recipient);

        Sanctum::actingAs($recipient);
        $this->deleteJson("/api/friends/{$friendship->id}")->assertForbidden();

        Sanctum::actingAs($sender);
        $this->deleteJson("/api/friends/{$friendship->id}")->assertNoContent();
    }

    public function test_declined_rows_and_other_peoples_friendships_cannot_be_deleted(): void
    {
        $sender = User::factory()->create();
        $recipient = User::factory()->create();
        $declined = $this->pendingRequest($sender, $recipient);
        $declined->forceFill(['status' => FriendshipStatus::Declined])->save();
        $accepted = $this->befriend(User::factory()->create(), User::factory()->create());

        foreach ([$sender, $recipient] as $party) {
            Sanctum::actingAs($party);
            $this->deleteJson("/api/friends/{$declined->id}")->assertForbidden();
        }

        Sanctum::actingAs(User::factory()->create());
        $this->deleteJson("/api/friends/{$accepted->id}")->assertForbidden();

        $this->assertDatabaseCount('friendships', 2);
    }
}
