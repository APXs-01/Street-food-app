<?php

namespace Tests\Feature\Vendor;

use App\Models\User;
use App\Models\Vendor;
use Database\Seeders\CategorySeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class VendorOnboardingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
        $this->seed(CategorySeeder::class);
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function payload(array $overrides = []): array
    {
        return array_merge([
            'name' => "Raju's Master Kottu",
            'description' => 'Fresh kottu every night.',
            'latitude' => 6.9271,
            'longitude' => 79.8612,
            'categories' => ['kottu', 'hoppers'],
            'opens_at' => '17:00',
            'closes_at' => '01:30',
            'cover_photo' => UploadedFile::fake()->image('cover.jpg', 800, 600),
        ], $overrides);
    }

    public function test_a_vendor_can_onboard_a_stall_that_is_live_immediately(): void
    {
        $user = User::factory()->vendor()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/vendors', $this->payload())
            ->assertCreated()
            ->assertJsonPath('data.name', "Raju's Master Kottu")
            ->assertJsonPath('data.hygiene.status', 'not_inspected')
            ->assertJsonPath('data.status.is_open', false)
            ->assertJsonPath('data.schedule.opens_at', '17:00')
            ->assertJsonCount(2, 'data.categories');

        $vendor = $user->vendor()->firstOrFail();

        $this->assertSame(sprintf('VEND-%04d', $vendor->id), $vendor->stall_code);
        $this->assertCount(2, $vendor->categories);
        Storage::disk('public')->assertExists($vendor->cover_photo_path);
    }

    public function test_a_second_stall_gets_a_friendly_conflict_and_stores_nothing(): void
    {
        $user = User::factory()->vendor()->create();
        $existing = Vendor::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        $this->postJson('/api/vendors', $this->payload())
            ->assertStatus(409)
            ->assertJsonPath('vendor_id', $existing->id)
            ->assertJsonPath('message', 'You already have a stall registered. Each vendor account can manage one stall.');

        $this->assertDatabaseCount('vendors', 1);
        $this->assertEmpty(Storage::disk('public')->allFiles());
    }

    public function test_only_vendor_accounts_can_onboard(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/vendors', $this->payload())->assertForbidden();
    }

    public function test_onboarding_requires_the_essentials(): void
    {
        Sanctum::actingAs(User::factory()->vendor()->create());

        $this->postJson('/api/vendors', [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'latitude', 'longitude', 'categories', 'opens_at', 'closes_at', 'cover_photo']);
    }

    public function test_categories_must_exist(): void
    {
        Sanctum::actingAs(User::factory()->vendor()->create());

        $this->postJson('/api/vendors', $this->payload(['categories' => ['pizza']]))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('categories.0');
    }

    public function test_opening_and_closing_time_must_differ(): void
    {
        Sanctum::actingAs(User::factory()->vendor()->create());

        $this->postJson('/api/vendors', $this->payload(['closes_at' => '17:00']))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('closes_at');
    }

    public function test_a_full_week_of_open_days_is_stored_as_every_day(): void
    {
        $user = User::factory()->vendor()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/vendors', $this->payload(['open_days' => [7, 6, 5, 4, 3, 2, 1]]))
            ->assertCreated()
            ->assertJsonPath('data.schedule.open_days', null);
    }
}
