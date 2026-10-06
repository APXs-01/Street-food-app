<?php

namespace Tests\Feature\Status;

use App\Models\DailyStatus;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StatusPostingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
    }

    private function submit(array $data = [])
    {
        return $this->postJson('/api/statuses', $data);
    }

    public function test_a_customer_can_post_a_caption_that_expires_in_24_hours(): void
    {
        $this->travelTo(Carbon::parse('2026-10-05 20:00', 'Asia/Colombo'));

        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->submit(['caption' => 'Fresh batch at the night market!', 'location_label' => 'Galle Face Green'])
            ->assertCreated()
            ->assertJsonPath('data.caption', 'Fresh batch at the night market!')
            ->assertJsonPath('data.audience', 'public')
            ->assertJsonPath('data.media', null)
            ->assertJsonPath('data.location_label', 'Galle Face Green')
            ->assertJsonPath('data.author.id', $user->id)
            ->assertJsonPath('data.likes_count', 0)
            ->assertJsonPath('data.liked_by_me', false)
            ->assertJsonPath('data.is_active', true)
            ->assertJsonMissingPath('data.latitude');

        $this->assertTrue(DailyStatus::firstOrFail()->expires_at->equalTo(now()->addHours(24)));
    }

    public function test_a_photo_is_resized_and_stored(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->submit(['media' => UploadedFile::fake()->image('dish.png', 800, 600)])
            ->assertCreated()
            ->assertJsonPath('data.media.type', 'image');

        $status = DailyStatus::firstOrFail();

        $this->assertStringEndsWith('.jpg', $status->media_path);
        Storage::disk('public')->assertExists($status->media_path);
    }

    public function test_a_short_video_is_stored_as_uploaded(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->submit([
            'caption' => 'Watch the kottu being chopped',
            'media' => UploadedFile::fake()->create('clip.mp4', 2048, 'video/mp4'),
        ])
            ->assertCreated()
            ->assertJsonPath('data.media.type', 'video');

        Storage::disk('public')->assertExists(DailyStatus::firstOrFail()->media_path);
    }

    public function test_a_video_over_20_mb_is_rejected(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->submit(['media' => UploadedFile::fake()->create('big.mp4', 20481, 'video/mp4')])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('media');

        $this->assertDatabaseCount('daily_statuses', 0);
    }

    public function test_a_photo_over_5_mb_is_rejected_even_though_videos_may_be_larger(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->submit(['media' => UploadedFile::fake()->image('huge.jpg')->size(6000)])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('media');
    }

    public function test_other_file_types_are_rejected(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->submit(['media' => UploadedFile::fake()->create('menu.pdf', 10, 'application/pdf')])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('media');
    }

    public function test_a_status_needs_a_caption_or_media(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->submit([])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['caption', 'media']);
    }

    public function test_the_caption_is_limited_to_200_characters(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->submit(['caption' => str_repeat('a', 201)])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('caption');
    }

    public function test_a_customer_can_limit_a_status_to_friends_and_tag_a_stall(): void
    {
        $stall = Vendor::factory()->create();
        Sanctum::actingAs(User::factory()->create());

        $this->submit(['caption' => 'Best kottu', 'audience' => 'friends', 'vendor_id' => $stall->id])
            ->assertCreated()
            ->assertJsonPath('data.audience', 'friends')
            ->assertJsonPath('data.vendor.id', $stall->id);

        $this->submit(['caption' => 'Best kottu', 'audience' => 'everyone'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('audience');

        $this->submit(['caption' => 'Best kottu', 'vendor_id' => 9999])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('vendor_id');
    }

    public function test_a_vendor_posts_publicly_for_their_own_stall(): void
    {
        $own = Vendor::factory()->create();
        $other = Vendor::factory()->create();
        Sanctum::actingAs($own->user);

        $this->submit(['caption' => 'Hot batch ready', 'audience' => 'friends', 'vendor_id' => $other->id])
            ->assertCreated()
            ->assertJsonPath('data.audience', 'public')
            ->assertJsonPath('data.vendor.id', $own->id)
            ->assertJsonPath('data.author.role', 'vendor');
    }

    public function test_only_active_customers_and_vendors_with_a_stall_can_post(): void
    {
        foreach ([
            User::factory()->vendor()->create(),
            User::factory()->inspector()->create(),
            User::factory()->create(['is_active' => false]),
        ] as $user) {
            Sanctum::actingAs($user);
            $this->submit(['caption' => 'Hello'])->assertForbidden();
        }

        $this->assertDatabaseCount('daily_statuses', 0);
    }
}
