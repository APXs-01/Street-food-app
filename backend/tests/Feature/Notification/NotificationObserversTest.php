<?php

namespace Tests\Feature\Notification;

use App\Enums\CheckResult;
use App\Enums\FriendshipStatus;
use App\Models\AppNotification;
use App\Models\DailyStatus;
use App\Models\Friendship;
use App\Models\HygieneChecklist;
use App\Models\Review;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesSocialFixtures;
use Tests\TestCase;

class NotificationObserversTest extends TestCase
{
    use CreatesSocialFixtures;
    use RefreshDatabase;

    /**
     * @return Collection<int, AppNotification>
     */
    private function received(User $user, ?string $type = null): Collection
    {
        return AppNotification::where('user_id', $user->id)
            ->when($type, fn ($query, $type) => $query->where('type', $type))
            ->orderBy('id')
            ->get();
    }

    // ---- comments -------------------------------------------------------

    public function test_a_comment_notifies_the_status_owner_but_not_the_commenter(): void
    {
        $owner = User::factory()->create();
        $commenter = User::factory()->create(['name' => 'Kaveen']);
        $status = $this->statusBy($owner);

        $comment = $status->comments()->create(['user_id' => $commenter->id, 'body' => 'Looks great']);

        $notification = $this->received($owner, 'status_comment')->sole();

        $this->assertSame('Kaveen commented on your status', $notification->title);
        $this->assertSame('Looks great', $notification->body);
        $this->assertSame($status->id, $notification->data['status_id']);
        $this->assertSame($comment->id, $notification->data['comment_id']);
        $this->assertSame($commenter->id, $notification->data['actor_id']);
        $this->assertCount(0, $this->received($commenter));
    }

    public function test_commenting_on_your_own_status_does_not_notify(): void
    {
        $owner = User::factory()->create();

        $this->statusBy($owner)->comments()->create(['user_id' => $owner->id, 'body' => 'note to self']);

        $this->assertCount(0, $this->received($owner));
    }

    public function test_an_inactive_owner_receives_nothing(): void
    {
        $owner = User::factory()->create(['is_active' => false]);
        $status = $this->statusBy($owner);

        $status->comments()->create(['user_id' => User::factory()->create()->id, 'body' => 'hello']);
        $status->likes()->create(['user_id' => User::factory()->create()->id]);

        $this->assertCount(0, $this->received($owner));
    }

    public function test_commenting_through_the_api_notifies_the_owner(): void
    {
        $owner = User::factory()->create();
        $status = $this->statusBy($owner);

        Sanctum::actingAs(User::factory()->create());
        $this->postJson("/api/statuses/{$status->id}/comments", ['body' => 'Nice one'])->assertCreated();

        $this->assertCount(1, $this->received($owner, 'status_comment'));
    }

    // ---- likes ----------------------------------------------------------

    public function test_a_like_notifies_the_owner_once_however_often_it_is_toggled(): void
    {
        $owner = User::factory()->create();
        $fan = User::factory()->create(['name' => 'Priya']);
        $status = $this->statusBy($owner);

        Sanctum::actingAs($fan);

        $this->postJson("/api/statuses/{$status->id}/like")->assertJsonPath('liked', true);
        $this->postJson("/api/statuses/{$status->id}/like")->assertJsonPath('liked', false);
        $this->postJson("/api/statuses/{$status->id}/like")->assertJsonPath('liked', true);

        $notification = $this->received($owner, 'status_like')->sole();

        $this->assertSame('Priya liked your status', $notification->title);
        $this->assertSame($fan->id, $notification->data['actor_id']);
    }

    public function test_each_person_who_likes_gets_their_own_notification_and_self_likes_are_ignored(): void
    {
        $owner = User::factory()->create();
        $status = $this->statusBy($owner);

        $status->likes()->create(['user_id' => User::factory()->create()->id]);
        $status->likes()->create(['user_id' => User::factory()->create()->id]);
        $status->likes()->create(['user_id' => $owner->id]);

        $this->assertCount(2, $this->received($owner, 'status_like'));
    }

    // ---- friends --------------------------------------------------------

    public function test_a_friend_request_notifies_the_recipient_and_acceptance_notifies_the_sender(): void
    {
        $sender = User::factory()->create(['name' => 'Sam', 'username' => 'sam_eats']);
        $recipient = User::factory()->create(['name' => 'Rae']);

        Sanctum::actingAs($sender);
        $friendshipId = $this->postJson('/api/friends', ['user_id' => $recipient->id])->assertCreated()->json('data.id');

        $request = $this->received($recipient, 'friend_request')->sole();
        $this->assertSame('Sam sent you a friend request', $request->title);
        $this->assertSame($friendshipId, $request->data['friendship_id']);
        $this->assertSame('sam_eats', $request->data['actor_username']);
        $this->assertCount(0, $this->received($sender));

        Sanctum::actingAs($recipient);
        $this->patchJson("/api/friends/{$friendshipId}", ['status' => 'accepted'])->assertOk();

        $accepted = $this->received($sender, 'friend_accepted')->sole();
        $this->assertSame('Rae accepted your friend request', $accepted->title);
        $this->assertSame($recipient->id, $accepted->data['actor_id']);
    }

    public function test_resending_or_declining_never_sends_extra_notifications(): void
    {
        $sender = User::factory()->create();
        $recipient = User::factory()->create();

        Sanctum::actingAs($sender);
        $id = $this->postJson('/api/friends', ['user_id' => $recipient->id])->json('data.id');
        $this->postJson('/api/friends', ['user_id' => $recipient->id])->assertOk();

        $this->assertCount(1, $this->received($recipient, 'friend_request'));

        Sanctum::actingAs($recipient);
        $this->patchJson("/api/friends/{$id}", ['status' => 'declined'])->assertOk();

        // The sender is not told, and asking again does not notify again.
        Sanctum::actingAs($sender);
        $this->postJson('/api/friends', ['user_id' => $recipient->id])->assertOk();

        $this->assertCount(0, $this->received($sender));
        $this->assertCount(1, $this->received($recipient, 'friend_request'));
    }

    public function test_an_inactive_recipient_gets_no_friend_request_notification(): void
    {
        $recipient = User::factory()->create(['is_active' => false]);

        Friendship::create([
            'requester_id' => User::factory()->create()->id,
            'addressee_id' => $recipient->id,
            'status' => FriendshipStatus::Pending,
        ]);

        $this->assertCount(0, $this->received($recipient));
    }

    public function test_creating_an_accepted_friendship_directly_does_not_send_a_request_notification(): void
    {
        $a = User::factory()->create();
        $b = User::factory()->create();

        $this->befriend($a, $b);

        $this->assertCount(0, $this->received($a));
        $this->assertCount(0, $this->received($b));
    }

    // ---- followed stalls ------------------------------------------------

    public function test_a_stall_status_notifies_its_active_followers_only(): void
    {
        Storage::fake('public');

        $vendor = Vendor::factory()->create(['name' => 'Raju Kottu']);
        $follower = User::factory()->create();
        $anotherFollower = User::factory()->create();
        $inactiveFollower = User::factory()->create(['is_active' => false]);
        $stranger = User::factory()->create();

        $vendor->followers()->attach([$follower->id, $anotherFollower->id, $inactiveFollower->id]);

        Sanctum::actingAs($vendor->user);
        $statusId = $this->postJson('/api/statuses', ['caption' => 'Fresh batch is ready'])->assertCreated()->json('data.id');

        $notification = $this->received($follower, 'vendor_status')->sole();

        $this->assertSame('Raju Kottu posted a new status', $notification->title);
        $this->assertSame('Fresh batch is ready', $notification->body);
        $this->assertSame($statusId, $notification->data['status_id']);
        $this->assertSame($vendor->id, $notification->data['vendor_id']);

        $this->assertCount(1, $this->received($anotherFollower, 'vendor_status'));
        $this->assertCount(0, $this->received($inactiveFollower));
        $this->assertCount(0, $this->received($stranger));
        $this->assertCount(0, $this->received($vendor->user));
    }

    public function test_a_customer_tagging_a_stall_does_not_notify_that_stalls_followers(): void
    {
        $vendor = Vendor::factory()->create();
        $follower = User::factory()->create();
        $vendor->followers()->attach($follower);

        DailyStatus::create([
            'user_id' => User::factory()->create()->id,
            'vendor_id' => $vendor->id,
            'body' => 'Loved it here',
            'audience' => 'public',
        ]);

        $this->assertCount(0, $this->received($follower));
    }

    // ---- reviews --------------------------------------------------------

    public function test_a_new_review_notifies_the_stall_owner(): void
    {
        $vendor = Vendor::factory()->create(['name' => 'Raju Kottu']);
        $reviewer = User::factory()->create(['name' => 'Dilani']);

        $review = Review::create([
            'vendor_id' => $vendor->id,
            'user_id' => $reviewer->id,
            'rating' => 5,
            'comment' => 'Spotless counter and great kottu.',
        ]);

        $notification = $this->received($vendor->user, 'new_review')->sole();

        $this->assertSame('Dilani reviewed Raju Kottu', $notification->title);
        $this->assertSame('Spotless counter and great kottu.', $notification->body);
        $this->assertSame($review->id, $notification->data['review_id']);
        $this->assertSame(5, $notification->data['rating']);
        $this->assertSame($reviewer->id, $notification->data['actor_id']);
        $this->assertFalse($notification->data['anonymous']);
    }

    public function test_an_anonymous_review_never_reveals_its_author(): void
    {
        $vendor = Vendor::factory()->create(['name' => 'Raju Kottu']);
        $reviewer = User::factory()->create(['name' => 'Secret Sally']);

        Review::create([
            'vendor_id' => $vendor->id,
            'user_id' => $reviewer->id,
            'rating' => 4,
            'comment' => 'Fine.',
            'is_anonymous' => true,
        ]);

        $notification = $this->received($vendor->user, 'new_review')->sole();

        $this->assertSame('New review on Raju Kottu', $notification->title);
        $this->assertNull($notification->data['actor_id']);
        $this->assertNull($notification->data['actor_name']);
        $this->assertTrue($notification->data['anonymous']);
        $this->assertStringNotContainsString('Secret Sally', json_encode($notification->toArray()));
    }

    public function test_a_hidden_review_does_not_notify(): void
    {
        $vendor = Vendor::factory()->create();

        $review = new Review([
            'vendor_id' => $vendor->id,
            'user_id' => User::factory()->create()->id,
            'rating' => 1,
            'comment' => 'Removed.',
        ]);
        $review->is_hidden = true;
        $review->save();

        $this->assertCount(0, $this->received($vendor->user));
    }

    public function test_editing_a_review_does_not_notify_again(): void
    {
        $vendor = Vendor::factory()->create();
        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/vendors/{$vendor->id}/reviews", ['rating' => 5])->assertCreated();
        $this->postJson("/api/vendors/{$vendor->id}/reviews", ['rating' => 2])->assertOk();

        $this->assertCount(1, $this->received($vendor->user, 'new_review'));
    }

    public function test_a_deactivated_stall_owner_receives_no_review_notification(): void
    {
        $vendor = Vendor::factory()->create();
        $vendor->user->forceFill(['is_active' => false])->save();

        Review::create([
            'vendor_id' => $vendor->id,
            'user_id' => User::factory()->create()->id,
            'rating' => 5,
            'comment' => 'Great.',
        ]);

        $this->assertCount(0, $this->received($vendor->user));
    }

    // ---- hygiene rating -------------------------------------------------

    private function inspect(Vendor $vendor, CheckResult $result): void
    {
        $checklist = $vendor->checklists()->create(array_fill_keys(HygieneChecklist::CRITERIA, $result));

        $vendor->applyChecklist($checklist);
    }

    public function test_the_first_inspection_notifies_the_owner(): void
    {
        $vendor = Vendor::factory()->create();

        $this->inspect($vendor, CheckResult::Pass);

        $notification = $this->received($vendor->user, 'hygiene_updated')->sole();

        $this->assertSame('Your hygiene rating was updated', $notification->title);
        $this->assertSame('Your stall is now rated A+ (5.0 out of 5).', $notification->body);
        $this->assertSame('A+', $notification->data['grade']);
        $this->assertNull($notification->data['previous_grade']);
        $this->assertTrue($notification->data['first_inspection']);
    }

    public function test_a_changed_rating_notifies_but_an_unchanged_one_does_not(): void
    {
        $vendor = Vendor::factory()->create();

        $this->inspect($vendor, CheckResult::Pass);

        $this->travelTo(now()->addDays(10));
        $this->inspect($vendor, CheckResult::Pass);
        $this->assertCount(1, $this->received($vendor->user, 'hygiene_updated'));

        $this->travelTo(now()->addDays(10));
        $this->inspect($vendor, CheckResult::Fail);

        $notifications = $this->received($vendor->user, 'hygiene_updated');
        $this->assertCount(2, $notifications);

        $latest = $notifications->last();
        $this->assertSame('needs_improvement', $latest->data['grade']);
        $this->assertSame('A+', $latest->data['previous_grade']);
        $this->assertEquals(5.0, $latest->data['previous_score']);
        $this->assertEquals(0.0, $latest->data['score']);
        $this->assertFalse($latest->data['first_inspection']);
    }

    public function test_other_stall_changes_do_not_notify(): void
    {
        $vendor = Vendor::factory()->create();

        $vendor->setOpen(true);
        $vendor->update(['name' => 'Renamed Stall']);
        $vendor->refreshRatingSnapshot();

        $this->assertCount(0, $this->received($vendor->user));
    }

    public function test_a_deactivated_owner_receives_no_hygiene_notification(): void
    {
        $vendor = Vendor::factory()->create();
        $vendor->user->forceFill(['is_active' => false])->save();

        $this->inspect($vendor, CheckResult::Pass);

        $this->assertCount(0, $this->received($vendor->user));
    }

    public function test_submitting_an_inspection_through_the_api_notifies_the_owner(): void
    {
        Storage::fake('public');

        $vendor = Vendor::factory()->create();
        Sanctum::actingAs(User::factory()->inspector()->create());

        $payload = array_fill_keys(HygieneChecklist::CRITERIA, 'pass') + [
            'vendor_id' => $vendor->id,
            'evidence_photo' => \Illuminate\Http\UploadedFile::fake()->image('evidence.jpg'),
        ];

        $this->postJson('/api/inspections', $payload)->assertCreated();

        $this->assertCount(1, $this->received($vendor->user, 'hygiene_updated'));
    }
}
