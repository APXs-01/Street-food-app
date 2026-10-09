<?php

namespace Tests\Feature\Status;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesSocialFixtures;
use Tests\TestCase;

class StatusInteractionTest extends TestCase
{
    use CreatesSocialFixtures;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
    }

    public function test_anyone_can_open_a_public_status_but_friends_only_needs_friendship(): void
    {
        $author = User::factory()->create();
        $friend = User::factory()->create();
        $stranger = User::factory()->create();
        $this->befriend($author, $friend);

        $public = $this->statusBy($author, 'public');
        $private = $this->statusBy($author, 'private', ['audience' => 'friends']);

        Sanctum::actingAs($stranger);
        $this->getJson("/api/statuses/{$public->id}")->assertOk();
        $this->getJson("/api/statuses/{$private->id}")->assertNotFound();

        Sanctum::actingAs($friend);
        $this->getJson("/api/statuses/{$private->id}")->assertOk()->assertJsonPath('data.caption', 'private');

        Sanctum::actingAs($author);
        $this->getJson("/api/statuses/{$private->id}")->assertOk();
    }

    public function test_an_expired_status_is_only_visible_to_its_author(): void
    {
        $author = User::factory()->create();
        $viewer = User::factory()->create();

        $this->travelTo(now()->subHours(30));
        $status = $this->statusBy($author, 'gone');
        $this->travelBack();

        Sanctum::actingAs($viewer);
        $this->getJson("/api/statuses/{$status->id}")->assertNotFound();

        Sanctum::actingAs($author);
        $this->getJson("/api/statuses/{$status->id}")
            ->assertOk()
            ->assertJsonPath('data.is_active', false);
    }

    public function test_show_returns_paginated_comments_oldest_first_and_the_liked_flag(): void
    {
        $author = User::factory()->create();
        $viewer = User::factory()->create();
        $status = $this->statusBy($author, 'talk about it');

        $this->travelTo(now()->subMinutes(30));
        $status->comments()->create(['user_id' => $author->id, 'body' => 'first']);
        $this->travelTo(now()->addMinutes(10));
        $status->comments()->create(['user_id' => $viewer->id, 'body' => 'second']);
        $this->travelBack();

        $status->likes()->create(['user_id' => $viewer->id]);

        Sanctum::actingAs($viewer);

        $this->getJson("/api/statuses/{$status->id}")
            ->assertOk()
            ->assertJsonPath('data.liked_by_me', true)
            ->assertJsonPath('data.likes_count', 1)
            ->assertJsonPath('data.comments_count', 2)
            ->assertJsonPath('comments.meta.total', 2)
            ->assertJsonPath('comments.data.0.body', 'first')
            ->assertJsonPath('comments.data.1.body', 'second')
            ->assertJsonPath('comments.data.1.author.id', $viewer->id);

        Sanctum::actingAs(User::factory()->create());
        $this->getJson("/api/statuses/{$status->id}")->assertJsonPath('data.liked_by_me', false);
    }

    public function test_a_viewer_can_comment_on_a_status_they_can_see(): void
    {
        $author = User::factory()->create();
        $friend = User::factory()->create();
        $stranger = User::factory()->create();
        $this->befriend($author, $friend);

        $public = $this->statusBy($author, 'public');
        $private = $this->statusBy($author, 'private', ['audience' => 'friends']);

        Sanctum::actingAs($stranger);
        $this->postJson("/api/statuses/{$public->id}/comments", ['body' => 'Nice!'])
            ->assertCreated()
            ->assertJsonPath('data.body', 'Nice!')
            ->assertJsonPath('data.author.id', $stranger->id);
        $this->postJson("/api/statuses/{$private->id}/comments", ['body' => 'Let me in'])->assertNotFound();

        Sanctum::actingAs($friend);
        $this->postJson("/api/statuses/{$private->id}/comments", ['body' => 'Looks great'])->assertCreated();

        $this->assertDatabaseCount('status_comments', 2);
    }

    public function test_comments_need_a_body_and_an_active_status(): void
    {
        $author = User::factory()->create();
        $status = $this->statusBy($author);

        Sanctum::actingAs($author);
        $this->postJson("/api/statuses/{$status->id}/comments", [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('body');
        $this->postJson("/api/statuses/{$status->id}/comments", ['body' => str_repeat('a', 301)])
            ->assertUnprocessable();

        $this->travelTo(now()->subHours(30));
        $expired = $this->statusBy($author, 'old');
        $this->travelBack();

        // The author can still see it but it is closed for comments and likes.
        $this->postJson("/api/statuses/{$expired->id}/comments", ['body' => 'Too late'])->assertForbidden();
        $this->postJson("/api/statuses/{$expired->id}/like")->assertForbidden();
    }

    public function test_inspectors_cannot_comment_or_like(): void
    {
        $status = $this->statusBy(User::factory()->create());

        Sanctum::actingAs(User::factory()->inspector()->create());

        $this->postJson("/api/statuses/{$status->id}/comments", ['body' => 'Hi'])->assertForbidden();
        $this->postJson("/api/statuses/{$status->id}/like")->assertForbidden();
    }

    public function test_liking_toggles(): void
    {
        $author = User::factory()->create();
        $fan = User::factory()->create();
        $other = User::factory()->create();
        $status = $this->statusBy($author);

        Sanctum::actingAs($fan);
        $this->postJson("/api/statuses/{$status->id}/like")
            ->assertOk()
            ->assertJsonPath('liked', true)
            ->assertJsonPath('likes_count', 1);

        Sanctum::actingAs($other);
        $this->postJson("/api/statuses/{$status->id}/like")->assertJsonPath('likes_count', 2);

        Sanctum::actingAs($fan);
        $this->postJson("/api/statuses/{$status->id}/like")
            ->assertOk()
            ->assertJsonPath('liked', false)
            ->assertJsonPath('likes_count', 1);

        $this->assertDatabaseCount('status_likes', 1);
    }

    public function test_a_friends_only_status_cannot_be_liked_by_a_stranger(): void
    {
        $status = $this->statusBy(User::factory()->create(), 'private', ['audience' => 'friends']);

        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/statuses/{$status->id}/like")->assertNotFound();
    }

    public function test_only_the_owner_can_delete_a_status_and_its_media_goes_with_it(): void
    {
        $author = User::factory()->create();
        $other = User::factory()->create();

        Storage::disk('public')->put('statuses/1/pic.jpg', 'x');
        $status = $this->statusBy($author, 'with picture', ['media_path' => 'statuses/1/pic.jpg', 'media_type' => 'image']);
        $status->comments()->create(['user_id' => $other->id, 'body' => 'nice']);
        $status->likes()->create(['user_id' => $other->id]);

        Sanctum::actingAs($other);
        $this->deleteJson("/api/statuses/{$status->id}")->assertForbidden();
        $this->assertDatabaseCount('daily_statuses', 1);

        Sanctum::actingAs($author);
        $this->deleteJson("/api/statuses/{$status->id}")->assertNoContent();

        $this->assertDatabaseCount('daily_statuses', 0);
        $this->assertDatabaseCount('status_comments', 0);
        $this->assertDatabaseCount('status_likes', 0);
        Storage::disk('public')->assertMissing('statuses/1/pic.jpg');
    }

    public function test_a_stranger_cannot_delete_or_discover_a_friends_only_status(): void
    {
        $status = $this->statusBy(User::factory()->create(), 'private', ['audience' => 'friends']);

        Sanctum::actingAs(User::factory()->create());

        $this->deleteJson("/api/statuses/{$status->id}")->assertNotFound();
    }
}
