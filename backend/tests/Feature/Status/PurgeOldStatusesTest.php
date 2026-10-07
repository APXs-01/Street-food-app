<?php

namespace Tests\Feature\Status;

use App\Models\DailyStatus;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesSocialFixtures;
use Tests\TestCase;

class PurgeOldStatusesTest extends TestCase
{
    use CreatesSocialFixtures;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
    }

    public function test_it_deletes_statuses_older_than_seven_days_with_their_media_and_interactions(): void
    {
        $author = User::factory()->create();
        $fan = User::factory()->create();

        Storage::disk('public')->put('statuses/1/old.jpg', 'x');
        Storage::disk('public')->put('statuses/1/recent.jpg', 'x');

        $this->travelTo(now()->subDays(8));
        $old = $this->statusBy($author, 'old', ['media_path' => 'statuses/1/old.jpg', 'media_type' => 'image']);
        $old->comments()->create(['user_id' => $fan->id, 'body' => 'nice']);
        $old->likes()->create(['user_id' => $fan->id]);
        $this->travelBack();

        $this->travelTo(now()->subDays(6));
        $recent = $this->statusBy($author, 'recent', ['media_path' => 'statuses/1/recent.jpg', 'media_type' => 'image']);
        $this->travelBack();

        $fresh = $this->statusBy($author, 'fresh');

        $this->artisan('statuses:purge-old')
            ->expectsOutputToContain('1 status(es) purged.')
            ->assertSuccessful();

        $this->assertModelMissing($old);
        $this->assertModelExists($recent);
        $this->assertModelExists($fresh);
        $this->assertDatabaseCount('status_comments', 0);
        $this->assertDatabaseCount('status_likes', 0);
        Storage::disk('public')->assertMissing('statuses/1/old.jpg');
        Storage::disk('public')->assertExists('statuses/1/recent.jpg');
    }

    public function test_an_expired_but_recent_status_stays_available_to_its_author_after_the_purge(): void
    {
        $author = User::factory()->create();

        $this->travelTo(now()->subDays(3));
        $status = $this->statusBy($author, 'three days old');
        $this->travelBack();

        $this->assertFalse($status->fresh()->isActive());

        $this->artisan('statuses:purge-old')->assertSuccessful();

        Sanctum::actingAs($author);

        $this->getJson('/api/statuses?mine=1')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.caption', 'three days old')
            ->assertJsonPath('data.0.is_active', false);

        // Everyone else no longer sees it.
        Sanctum::actingAs(User::factory()->create());
        $this->getJson("/api/statuses/{$status->id}")->assertNotFound();
    }

    public function test_it_does_nothing_when_there_is_nothing_old(): void
    {
        $this->statusBy(User::factory()->create());

        $this->artisan('statuses:purge-old')
            ->expectsOutputToContain('0 status(es) purged.')
            ->assertSuccessful();

        $this->assertSame(1, DailyStatus::count());
    }

    public function test_it_is_scheduled_daily(): void
    {
        $this->artisan('schedule:list')
            ->expectsOutputToContain('statuses:purge-old')
            ->assertSuccessful();
    }
}
