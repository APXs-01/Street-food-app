<?php

namespace Tests\Feature\Vendor;

use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class VendorManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_any_signed_in_user_can_view_a_stall_with_its_menu(): void
    {
        $vendor = Vendor::factory()->create();
        $vendor->menuItems()->create(['name' => 'Chicken Kottu', 'price' => 450]);
        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/vendors/{$vendor->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $vendor->id)
            ->assertJsonPath('data.hygiene.status', 'not_inspected')
            ->assertJsonPath('data.rating.count', 0)
            ->assertJsonCount(1, 'data.menu');
    }

    public function test_stalls_can_be_searched_by_menu_item(): void
    {
        $kottu = Vendor::factory()->create(['name' => 'Night Bites']);
        $kottu->menuItems()->create(['name' => 'Cheese Kottu', 'price' => 500]);
        Vendor::factory()->create(['name' => 'Juice Corner']);
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/vendors?q=kottu')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Night Bites');
    }

    public function test_the_owner_can_update_stall_details(): void
    {
        $vendor = Vendor::factory()->create(['name' => 'Old Name']);
        Sanctum::actingAs($vendor->user);

        $this->patchJson("/api/vendors/{$vendor->id}", ['name' => 'New Name'])
            ->assertOk()
            ->assertJsonPath('data.name', 'New Name');
    }

    public function test_another_vendor_cannot_update_or_toggle_a_stall(): void
    {
        $vendor = Vendor::factory()->create();
        $other = Vendor::factory()->create();
        Sanctum::actingAs($other->user);

        $this->patchJson("/api/vendors/{$vendor->id}", ['name' => 'Hijacked'])->assertForbidden();
        $this->patchJson("/api/vendors/{$vendor->id}/status", ['is_open' => true])->assertForbidden();
        $this->patchJson("/api/vendors/{$vendor->id}/hours", ['opens_at' => '10:00', 'closes_at' => '20:00'])->assertForbidden();
    }

    public function test_stalls_cannot_be_deleted_through_the_api(): void
    {
        $vendor = Vendor::factory()->create();
        Sanctum::actingAs($vendor->user);

        $this->deleteJson("/api/vendors/{$vendor->id}")->assertStatus(405);
    }

    public function test_opening_the_stall_starts_the_auto_close_clock(): void
    {
        $vendor = Vendor::factory()->create(['opens_at' => '17:00', 'closes_at' => '01:30']);
        Sanctum::actingAs($vendor->user);

        $this->travelTo(Carbon::parse('2026-10-05 18:00', 'Asia/Colombo'));

        $this->patchJson("/api/vendors/{$vendor->id}/status", ['is_open' => true])
            ->assertOk()
            ->assertJsonPath('data.status.is_open', true)
            ->assertJsonPath('data.status.is_open_now', true);

        $this->travelTo(Carbon::parse('2026-10-06 01:29', 'Asia/Colombo'));
        $this->getJson("/api/vendors/{$vendor->id}")->assertJsonPath('data.status.is_open_now', true);

        $this->travelTo(Carbon::parse('2026-10-06 01:31', 'Asia/Colombo'));
        $this->getJson("/api/vendors/{$vendor->id}")
            ->assertJsonPath('data.status.is_open', true)
            ->assertJsonPath('data.status.is_open_now', false);
    }

    public function test_closing_the_stall_takes_effect_immediately(): void
    {
        $vendor = Vendor::factory()->create();
        Sanctum::actingAs($vendor->user);

        $this->patchJson("/api/vendors/{$vendor->id}/status", ['is_open' => true])->assertOk();
        $this->patchJson("/api/vendors/{$vendor->id}/status", ['is_open' => false])
            ->assertOk()
            ->assertJsonPath('data.status.is_open_now', false);
    }

    public function test_hours_and_open_days_can_be_updated(): void
    {
        $vendor = Vendor::factory()->create();
        Sanctum::actingAs($vendor->user);

        $this->patchJson("/api/vendors/{$vendor->id}/hours", [
            'opens_at' => '16:00',
            'closes_at' => '23:00',
            'open_days' => [5, 1, 3],
        ])
            ->assertOk()
            ->assertJsonPath('data.schedule.opens_at', '16:00')
            ->assertJsonPath('data.schedule.closes_at', '23:00')
            ->assertJsonPath('data.schedule.open_days', [1, 3, 5]);
    }

    public function test_equal_opening_and_closing_times_are_rejected(): void
    {
        $vendor = Vendor::factory()->create();
        Sanctum::actingAs($vendor->user);

        $this->patchJson("/api/vendors/{$vendor->id}/hours", ['opens_at' => '10:00', 'closes_at' => '10:00'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('closes_at');
    }
}
