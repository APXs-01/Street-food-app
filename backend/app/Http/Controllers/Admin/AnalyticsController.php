<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Review;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\View\View;

/**
 * Platform figures for the administrator. Nothing is defined here that is not
 * defined once elsewhere: "overdue" and the other re-verification states are the
 * Vendor scopes the Hygiene board and the daily alert also use, and "visible
 * review" is the Review scope the public API uses.
 */
class AnalyticsController extends Controller
{
    private const MOST_OVERDUE = 10;

    private const MOST_REPORTED = 10;

    public function index(): View
    {
        $soonDays = (int) config('streetbite.due_soon_days');

        $reviewStats = Review::visible()->selectRaw('COUNT(*) as total, AVG(rating) as average')->first();
        $visibleReviews = (int) $reviewStats->total;

        return view('admin.analytics', [
            'people' => $this->people(),
            'stalls' => [
                'listed' => Vendor::count(),
                'public' => Vendor::visible()->count(),
                'hidden' => Vendor::count() - Vendor::visible()->count(),
            ],
            'hygiene' => [
                'soon_days' => $soonDays,
                'overdue' => Vendor::hygieneOverdue()->count(),
                'due_soon' => Vendor::hygieneDueSoon($soonDays)->count(),
                'current' => Vendor::hygieneCurrent($soonDays)->count(),
                'not_inspected' => Vendor::neverInspected()->count(),
                // Longest overdue first.
                'most_overdue' => Vendor::hygieneOverdue()
                    ->with('user')
                    ->orderBy('reverification_due_at')
                    ->orderBy('id')
                    ->limit(self::MOST_OVERDUE)
                    ->get(),
            ],
            'reported' => [
                'total' => Review::has('reports')->count(),
                'top' => Review::query()
                    ->has('reports')
                    ->withCount('reports')
                    ->with(['user', 'vendor'])
                    ->orderByDesc('reports_count')
                    ->latest()
                    ->orderByDesc('id')
                    ->limit(self::MOST_REPORTED)
                    ->get(),
            ],
            // The mean of every review the public can see (not hidden, author not
            // suspended), with the count so a thin sample is visible at a glance.
            'rating' => [
                'average' => $visibleReviews > 0 ? round((float) $reviewStats->average, 1) : null,
                'count' => $visibleReviews,
                'excluded' => Review::count() - $visibleReviews,
            ],
        ]);
    }

    /**
     * Accounts by role, each split into active and suspended.
     *
     * @return array<string, array{total: int, active: int, suspended: int}>
     */
    private function people(): array
    {
        $rows = User::query()
            ->selectRaw('role, is_active, COUNT(*) as total')
            ->groupBy('role', 'is_active')
            ->get();

        return collect([
            'customers' => UserRole::Consumer,
            'vendors' => UserRole::Vendor,
            'inspectors' => UserRole::Inspector,
        ])->map(function (UserRole $role) use ($rows) {
            $ofRole = $rows->filter(fn (User $row) => $row->role === $role);

            $active = (int) $ofRole->firstWhere('is_active', true)?->total;
            $suspended = (int) $ofRole->firstWhere('is_active', false)?->total;

            return ['total' => $active + $suspended, 'active' => $active, 'suspended' => $suspended];
        })->all();
    }
}
