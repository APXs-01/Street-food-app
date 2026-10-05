<?php

namespace Tests\Feature\Admin;

use App\Models\AppNotification;
use App\Models\DailyStatus;
use App\Models\Review;
use App\Models\User;
use App\Models\Vendor;
use App\Services\VendorDeletion;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\SignsInAdmin;
use Tests\TestCase;

class DashboardTest extends TestCase
{
    use RefreshDatabase;
    use SignsInAdmin;

    public function test_it_needs_an_admin(): void
    {
        $this->get('/admin')->assertRedirect(route('admin.login'));
        $this->actingAs(User::factory()->vendor()->create())->get('/admin')->assertForbidden();
    }

    public function test_it_shows_the_headline_counts(): void
    {
        $customerA = User::factory()->create();
        $customerB = User::factory()->create();
        User::factory()->create(['is_active' => false]);
        User::factory()->inspector()->create();

        $fresh = Vendor::factory()->create();
        $overdue = Vendor::factory()->create([
            'hygiene_grade' => 'A',
            'hygiene_score' => 4.0,
            'last_inspected_at' => now()->subDays(40),
            'reverification_due_at' => now()->subDays(10),
        ]);

        Review::create(['vendor_id' => $fresh->id, 'user_id' => $customerA->id, 'rating' => 5, 'comment' => 'Great']);
        $hidden = Review::create(['vendor_id' => $overdue->id, 'user_id' => $customerB->id, 'rating' => 1, 'comment' => 'Bad']);
        $hidden->forceFill(['is_hidden' => true])->save();

        DailyStatus::create(['user_id' => $customerA->id, 'body' => 'Active now', 'audience' => 'public']);
        $this->travelTo(now()->subHours(30));
        DailyStatus::create(['user_id' => $customerA->id, 'body' => 'Expired', 'audience' => 'public']);
        $this->travelBack();

        $this->actingAsAdmin()
            ->get('/admin')
            ->assertOk()
            ->assertViewHas('stats', fn (array $stats) => $stats === [
                'customers' => 3,
                'vendor_accounts' => 2,
                'inspectors' => 1,
                'suspended' => 1,
                'stalls' => 2,
                'not_inspected' => 1,
                'overdue' => 1,
                'inspections' => 0,
                'reviews' => 2,
                'hidden_reviews' => 1,
                'reported_reviews' => 0,
                'active_statuses' => 1,
            ]);
    }

    public function test_it_lists_only_my_unread_reverification_alerts_and_can_clear_them(): void
    {
        $admin = $this->makeAdmin();
        $otherAdmin = $this->makeAdmin();
        $stall = Vendor::factory()->create(['name' => 'Late Stall']);

        $alert = $admin->appNotifications()->create([
            'type' => 'hygiene_overdue',
            'title' => 'Re-verification overdue: Late Stall',
            'body' => 'Re-verification was due 10 days ago.',
            'data' => ['vendor_id' => $stall->id],
        ]);
        // read_at is not mass assignable, so mark it read the way the app does.
        $admin->appNotifications()->create([
            'type' => 'hygiene_overdue',
            'title' => 'Already dealt with',
            'data' => ['vendor_id' => $stall->id],
        ])->markAsRead();
        $admin->appNotifications()->create(['type' => 'new_review', 'title' => 'Some other notification']);
        $theirs = $otherAdmin->appNotifications()->create(['type' => 'hygiene_overdue', 'title' => 'Not mine']);

        $this->actingAsAdmin($admin)
            ->get('/admin')
            ->assertOk()
            ->assertSee('Re-verification overdue: Late Stall')
            ->assertDontSee('Already dealt with')
            ->assertDontSee('Some other notification')
            ->assertDontSee('Not mine')
            ->assertViewHas('alerts', fn ($alerts) => $alerts->count() === 1);

        $this->post('/admin/alerts/read')->assertRedirect(route('admin.dashboard'));

        $this->assertNotNull($alert->fresh()->read_at);
        $this->assertSame(0, $admin->appNotifications()->unread()->count());
        $this->assertNull($theirs->fresh()->read_at);

        $this->get('/admin')->assertSee('No unread alerts.');
    }

    public function test_an_alert_for_a_deleted_stall_has_no_dead_link(): void
    {
        $admin = $this->makeAdmin();
        $live = Vendor::factory()->create();
        $gone = Vendor::factory()->create();

        $admin->appNotifications()->create(['type' => 'hygiene_overdue', 'title' => 'Live alert', 'data' => ['vendor_id' => $live->id]]);
        $admin->appNotifications()->create(['type' => 'hygiene_overdue', 'title' => 'Gone alert', 'data' => ['vendor_id' => $gone->id]]);

        app(VendorDeletion::class)->delete($gone);

        $this->actingAsAdmin($admin)
            ->get('/admin')
            ->assertOk()
            ->assertSee('Live alert')
            ->assertSee('Gone alert')
            ->assertSee(route('admin.vendors.show', $live), false)
            ->assertDontSee("/admin/vendors/{$gone->id}", false);
    }
}
