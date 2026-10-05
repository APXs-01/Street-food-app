<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Review;
use App\Support\Media;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

/**
 * Moderation of reviews. Hiding and unhiding are reversible and recalculate the
 * stall's star rating (ReviewObserver). Deleting is permanent. Unlike the public
 * API, this shows every review, including hidden ones and ones written by
 * suspended accounts, and the real author of anonymous reviews.
 */
class ReviewModerationController extends Controller
{
    /**
     * Reported reviews come first (most reports on top) because that is the
     * moderators' queue. Switch to all reviews or only the hidden ones. Search
     * matches the comment, the author and the stall.
     */
    public function index(Request $request): View
    {
        $filters = $request->validate([
            'scope' => ['nullable', Rule::in(['flagged', 'all', 'hidden'])],
            'q' => ['nullable', 'string', 'max:100'],
            'rating' => ['nullable', 'integer', 'between:1,5'],
        ]);

        $scope = $filters['scope'] ?? 'flagged';

        $reviews = Review::query()
            ->with(['user', 'vendor'])
            ->withCount(['reports', 'photos'])
            ->when($scope === 'flagged', fn (Builder $query) => $query->has('reports'))
            ->when($scope === 'hidden', fn (Builder $query) => $query->where('is_hidden', true))
            ->when($filters['q'] ?? null, function (Builder $query, string $term) {
                $like = '%'.addcslashes(trim($term), '%_\\').'%';

                $query->where(fn (Builder $match) => $match
                    ->where('comment', 'like', $like)
                    ->orWhereHas('user', fn (Builder $author) => $author->where('name', 'like', $like)->orWhere('email', 'like', $like))
                    ->orWhereHas('vendor', fn (Builder $stall) => $stall->where('name', 'like', $like)));
            })
            ->when($filters['rating'] ?? null, fn (Builder $query, int|string $rating) => $query->where('rating', $rating))
            ->when($scope === 'flagged', fn (Builder $query) => $query->orderByDesc('reports_count'))
            ->latest()
            ->orderByDesc('id')
            ->paginate(25)
            ->withQueryString();

        return view('admin.reviews.index', [
            'reviews' => $reviews,
            'filters' => $filters,
            'scope' => $scope,
            'counts' => [
                'flagged' => Review::has('reports')->count(),
                'hidden' => Review::where('is_hidden', true)->count(),
                'all' => Review::count(),
            ],
        ]);
    }

    public function show(Review $review): View
    {
        $review->load(['user', 'vendor.user', 'photos', 'reports.reporter', 'moderator']);

        return view('admin.reviews.show', ['review' => $review]);
    }

    public function hide(Request $request, Review $review): RedirectResponse
    {
        Gate::authorize('moderate-content');

        $data = $request->validate(['reason' => ['nullable', 'string', 'max:255']]);

        $review->hideBy($request->user(), $data['reason'] ?? null);

        Log::info('Admin hid a review.', ['admin_id' => $request->user()->id, 'review_id' => $review->id]);

        return $this->backTo($review)->with('status', 'Review hidden. It no longer shows publicly or counts towards the stall\'s rating.');
    }

    public function unhide(Request $request, Review $review): RedirectResponse
    {
        Gate::authorize('moderate-content');

        $review->unhideBy($request->user());

        Log::info('Admin unhid a review.', ['admin_id' => $request->user()->id, 'review_id' => $review->id]);

        return $this->backTo($review)->with('status', 'Review restored. It shows publicly again unless its author is suspended.');
    }

    /**
     * Close the reports without touching the review: the moderators looked and
     * it stays as it is.
     */
    public function dismiss(Request $request, Review $review): RedirectResponse
    {
        Gate::authorize('moderate-content');

        $dismissed = $review->reports()->delete();

        Log::info('Admin dismissed review reports.', ['admin_id' => $request->user()->id, 'review_id' => $review->id, 'reports' => $dismissed]);

        return $this->backTo($review)->with('status', "{$dismissed} ".($dismissed === 1 ? 'report' : 'reports').' dismissed. The review is unchanged.');
    }

    /**
     * Permanent: the review, its photos (rows and files) and its reports go.
     * The stall's star rating is recalculated.
     */
    public function destroy(Request $request, Review $review): RedirectResponse
    {
        Gate::authorize('moderate-content');

        $vendor = $review->vendor;
        $paths = $review->photos()->pluck('path')->all();

        DB::transaction(fn () => $review->delete());

        Media::disk()->delete($paths);
        $vendor->refreshRatingSnapshot();

        Log::warning('Admin deleted a review.', ['admin_id' => $request->user()->id, 'review_id' => $review->id, 'vendor_id' => $vendor->id]);

        return redirect()->route('admin.reviews.index', ['scope' => 'all'])->with('status', 'Review deleted.');
    }

    private function backTo(Review $review): RedirectResponse
    {
        return redirect()->back(fallback: route('admin.reviews.show', $review));
    }
}
