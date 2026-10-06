<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DailyStatus;
use App\Models\HygieneChecklist;
use App\Models\Vendor;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

/**
 * The vendor dashboard's figures. Owner only, and switched off as a whole by the
 * vendor.analytics flag. Nothing here is recalculated or defined a second time:
 * the star rating is the stall's stored snapshot, the trend is the stored
 * checklist scores, and the engagement counts are the ones the status feed shows.
 */
class VendorAnalyticsController extends Controller
{
    /** How many inspections the trend covers. */
    private const TREND_POINTS = 10;

    public function __invoke(Vendor $vendor): JsonResponse
    {
        Gate::authorize('viewAnalytics', $vendor);

        // The latest inspections, drawn oldest first so a chart reads left to right.
        $trend = $vendor->checklists()
            ->orderByDesc('inspected_at')
            ->orderByDesc('id')
            ->limit(self::TREND_POINTS)
            ->get(['id', 'vendor_id', 'score', 'grade', 'inspected_at'])
            ->reverse()
            ->values()
            ->map(fn (HygieneChecklist $checklist) => [
                'inspected_at' => $checklist->inspected_at,
                'score' => $checklist->score,
                'grade' => $checklist->grade?->value,
            ]);

        // The owner's own statuses that are still stored (the daily purge removes
        // old ones) and not hidden by a moderator. Counted as in the feed: every
        // like, and only the comments the public can see.
        $statuses = DailyStatus::query()
            ->where('user_id', $vendor->user_id)
            ->where('is_hidden', false)
            ->withCount(['likes', 'comments' => fn ($comments) => $comments->visible()])
            ->get();

        return response()->json(['data' => [
            'vendor_id' => $vendor->id,
            'rating' => [
                'average' => $vendor->rating_average,
                'count' => $vendor->reviews_count,
            ],
            'hygiene_trend' => $trend,
            'engagement' => [
                // Nothing in the app records stall or status views yet, so there
                // is no honest number to give. Reserved so the app can hide the tile.
                'views' => null,
                'likes' => (int) $statuses->sum('likes_count'),
                'comments' => (int) $statuses->sum('comments_count'),
                'statuses' => $statuses->count(),
            ],
        ]]);
    }
}
