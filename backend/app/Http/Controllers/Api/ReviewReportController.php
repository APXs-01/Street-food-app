<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Review\ReportReviewRequest;
use App\Models\Review;
use App\Models\ReviewReport;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class ReviewReportController extends Controller
{
    /**
     * Report a review to the moderators. Only reviews the public can see can be
     * reported (anything else is a 404), and reporting the same review twice is
     * harmless: the first report stands. Reports never change what the public
     * sees; a moderator decides in the admin panel.
     */
    public function store(ReportReviewRequest $request, Review $review): JsonResponse
    {
        abort_unless(Review::visible()->whereKey($review->id)->exists(), 404);

        Gate::authorize('report', $review);

        $report = ReviewReport::firstOrCreate(
            ['review_id' => $review->id, 'reporter_id' => $request->user()->id],
            $request->safe()->only(['reason', 'details']),
        );

        return response()->json(
            ['message' => 'Thank you. A moderator will look at this review.'],
            $report->wasRecentlyCreated ? 201 : 200,
        );
    }
}
