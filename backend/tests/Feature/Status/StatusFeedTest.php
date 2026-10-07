<?php

namespace Tests\Feature\Status;

use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesSocialFixtures;
use Tests\TestCase;

class StatusFeedTest extends TestCase
{
    use CreatesSocialFixtures;
    use RefreshDatabase;

    /**
     * @return array<int, string>
     */
    private function feedCaptions(string $query = ''): array
    {
        return collect($this->getJson('/api/statuses'.$query)->assertOk()->json('data'))
            ->pluck('caption')
            ->all();
    }

    public function test_the_feed_holds_own_and_friends_posts_and_followed_stalls_but_not_strangers(): void
    {
        $me = User::factory()->create();
        $friend = User::factory()->create();
        $stranger = User::factory()->create();
        $followed = Vendor::factory()->create();
        $unfollowed = Vendor::factory()->create();

        $this->befriend($friend, $me);
        $me->followedVendors()->attach($followed);

        $this->statusBy($me, 'mine');
        $this->statusBy($friend, 'friend public');
        $this->statusBy($friend, 'friend only', ['audience' => 'friends']);
        $this->statusBy($stranger, 'stranger public');
        $this->statusBy($followed->user, 'followed stall', ['vendor_id' => $followed->id]);
        $this->statusBy($unfollowed->user, 'unfollowed stall', ['vendor_id' => $unfollowed->id]);

        Sanctum::actingAs($me);

        $captions = $this->feedCaptions();

        $this->assertEqualsCanonicalizing(
            ['mine', 'friend public', 'friend only', 'followed stall'],
            $captions,
        );
    }

    public function test_friends_only_posts_are_hidden_from_non_friends_even_if_they_follow_the_stall(): void
    {
        $author = User::factory()->create();
        $outsider = User::factory()->create();
        $this->statusBy($author, 'private', ['audience' => 'friends']);

        Sanctum::actingAs($outsider);

        $this->assertSame([], $this->feedCaptions());
    }

    public function test_the_feed_is_newest_first_and_hides_expired_statuses(): void
    {
        $me = User::factory()->create();
        $friend = User::factory()->create();
        $this->befriend($me, $friend);

        $this->travelTo(now()->subHours(30));
        $this->statusBy($friend, 'expired');
        $this->travelBack();

        $this->travelTo(now()->subHours(3));
        $this->statusBy($friend, 'older');
        $this->travelTo(now()->addHour());
        $this->statusBy($friend, 'newer');
        $this->travelBack();

        Sanctum::actingAs($me);

        $this->assertSame(['newer', 'older'], $this->feedCaptions());
    }

    public function test_mine_lists_own_statuses_including_expired_ones_and_nothing_else(): void
    {
        $me = User::factory()->create();
        $friend = User::factory()->create();
        $this->befriend($me, $friend);

        $this->travelTo(now()->subHours(30));
        $this->statusBy($me, 'expired but mine');
        $this->travelBack();
        $this->statusBy($me, 'current');
        $this->statusBy($friend, 'friend');

        Sanctum::actingAs($me);

        $this->assertEqualsCanonicalizing(['expired but mine', 'current'], $this->feedCaptions('?mine=1'));
        $this->assertEqualsCanonicalizing(['expired but mine', 'current'], $this->feedCaptions('?mine=true'));

        $this->getJson('/api/statuses?mine=maybe')->assertUnprocessable()->assertJsonValidationErrors('mine');
    }

    public function test_feed_items_carry_counts_and_the_liked_flag(): void
    {
        $me = User::factory()->create();
        $friend = User::factory()->create();
        $this->befriend($me, $friend);

        $status = $this->statusBy($friend, 'popular');
        $status->likes()->create(['user_id' => $me->id]);
        $status->likes()->create(['user_id' => User::factory()->create()->id]);
        $status->comments()->create(['user_id' => $friend->id, 'body' => 'Thanks!']);

        Sanctum::actingAs($me);

        $this->getJson('/api/statuses')
            ->assertOk()
            ->assertJsonPath('data.0.likes_count', 2)
            ->assertJsonPath('data.0.comments_count', 1)
            ->assertJsonPath('data.0.liked_by_me', true)
            ->assertJsonPath('data.0.author.id', $friend->id);
    }

    public function test_the_feed_is_paginated(): void
    {
        $me = User::factory()->create();

        foreach (range(1, 3) as $i) {
            $this->statusBy($me, "post {$i}");
        }

        Sanctum::actingAs($me);

        $this->getJson('/api/statuses?per_page=2')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('meta.total', 3);
    }

    public function test_the_feed_needs_a_token(): void
    {
        $this->getJson('/api/statuses')->assertUnauthorized();
    }
}
