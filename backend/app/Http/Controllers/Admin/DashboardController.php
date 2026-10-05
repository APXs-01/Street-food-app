<?php

namespace App\Http\Controllers\Admin;

use App\Enums\NotificationType;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\DailyStatus;
use App\Models\InspectorSubmission;
use App\Models\Review;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DashboardController extends Controller
{
    /**
     * Headline counts plus the unread re-verification alerts that
     * hygiene:flag-overdue writes for administrators. Deeper figures live on
     * the analytics page.
     */
    public function index(Request $request): View
    {
        $accounts = User::query()
            ->selectRaw('role, COUNT(*) as total')
            ->groupBy('role')
            ->pluck('total', 'role');

        $stats = [
            'customers' => (int) ($accounts[UserRole::Consumer->value] ?? 0),
            'vendor_accounts' => (int) ($accounts[UserRole::Vendor->value] ?? 0),
            'inspectors' => (int) ($accounts[UserRole::Inspector->value] ?? 0),
            'suspended' => User::where('is_active', false)->count(),
            'stalls' => Vendor::count(),
            'not_inspected' => Vendor::neverInspected()->count(),
            'overdue' => Vendor::hygieneOverdue()->count(),
            'inspections' => InspectorSubmission::count(),
            'reviews' => Review::count(),
            'hidden_reviews' => Review::where('is_hidden', true)->count(),
            'reported_reviews' => Review::has('reports')->count(),
            'active_statuses' => DailyStatus::active()->count(),
        ];

        $alerts = $request->user()->appNotifications()
            ->unread()
            ->where('type', NotificationType::HygieneOverdue->value)
            ->latest()
            ->orderByDesc('id')
            ->limit(10)
            ->get();

        // An alert can outlive its stall (a deleted stall keeps no page to link to).
        $existingStalls = Vendor::whereIn('id', $alerts->pluck('data.vendor_id')->filter())->pluck('id');

        return view('admin.dashboard', [
            'stats' => $stats,
            'alerts' => $alerts,
            'existingStalls' => $existingStalls,
            'unreadAlerts' => $request->user()->appNotifications()->unread()->count(),
        ]);
    }

    public function markAlertsRead(Request $request): RedirectResponse
    {
        $request->user()->appNotifications()->unread()->update(['read_at' => now()]);

        return redirect()->route('admin.dashboard')->with('status', 'Alerts marked as read.');
    }
}
