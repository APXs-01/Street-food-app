<?php

namespace Tests\Feature\Inspection;

use App\Enums\UserRole;
use App\Models\AppNotification;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FlagOverdueHygieneTest extends TestCase
{
    use RefreshDatabase;

    private function inspectedStall(string $name, int $daysSinceInspection, int $daysUntilDue): Vendor
    {
        return Vendor::factory()->create([
            'name' => $name,
            'hygiene_grade' => 'A',
            'hygiene_score' => 4.0,
            'last_inspected_at' => now()->subDays($daysSinceInspection),
            'reverification_due_at' => now()->addDays($daysUntilDue),
        ]);
    }

    public function test_it_notifies_active_admins_about_overdue_stalls_only(): void
    {
        $admin = User::factory()->withRole(UserRole::SuperAdmin)->create();
        User::factory()->withRole(UserRole::SuperAdmin)->create(['is_active' => false]);
        User::factory()->create();

        $overdue = $this->inspectedStall('Overdue Stall', 40, -10);
        $this->inspectedStall('Current Stall', 5, 25);
        Vendor::factory()->create(['name' => 'Never Inspected']);

        $this->artisan('hygiene:flag-overdue')
            ->expectsOutputToContain('1 overdue stall(s); 1 notification(s) created.')
            ->assertSuccessful();

        $this->assertDatabaseCount('app_notifications', 1);

        $notification = AppNotification::firstOrFail();

        $this->assertSame($admin->id, $notification->user_id);
        $this->assertSame('hygiene_overdue', $notification->type);
        $this->assertStringContainsString('Overdue Stall', $notification->title);
        $this->assertSame($overdue->id, $notification->data['vendor_id']);
        $this->assertNull($notification->read_at);
    }

    public function test_running_it_again_does_not_repeat_the_same_lapse(): void
    {
        User::factory()->withRole(UserRole::SuperAdmin)->create();
        $overdue = $this->inspectedStall('Overdue Stall', 40, -10);

        $this->artisan('hygiene:flag-overdue')->assertSuccessful();
        $this->artisan('hygiene:flag-overdue')
            ->expectsOutputToContain('1 overdue stall(s); 0 notification(s) created.')
            ->assertSuccessful();

        $this->assertDatabaseCount('app_notifications', 1);

        // Re-inspected, then lapsed again: a new due date is a new episode.
        $overdue->forceFill(['reverification_due_at' => now()->subDays(2)])->save();

        $this->artisan('hygiene:flag-overdue')
            ->expectsOutputToContain('1 notification(s) created.')
            ->assertSuccessful();

        $this->assertDatabaseCount('app_notifications', 2);
    }

    public function test_it_does_nothing_without_an_active_admin(): void
    {
        $this->inspectedStall('Overdue Stall', 40, -10);

        $this->artisan('hygiene:flag-overdue')
            ->expectsOutputToContain('No active administrators to notify.')
            ->assertSuccessful();

        $this->assertDatabaseCount('app_notifications', 0);
    }

    public function test_it_is_scheduled_daily(): void
    {
        $this->artisan('schedule:list')
            ->expectsOutputToContain('hygiene:flag-overdue')
            ->assertSuccessful();
    }
}
