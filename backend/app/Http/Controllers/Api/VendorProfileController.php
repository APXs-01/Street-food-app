<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Vendor\ReviewListRequest;
use App\Http\Resources\HygieneBreakdownResource;
use App\Http\Resources\ReviewPhotoResource;
use App\Http\Resources\ReviewResource;
use App\Models\ReviewPhoto;
use App\Models\Vendor;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * Read-only tabs of the vendor profile: Hygiene Breakdown and Reviews. The
 * Overview tab is VendorController@show.
 */
class VendorProfileController extends Controller
{
    public function hygiene(Vendor $vendor): HygieneBreakdownResource
    {
        return new HygieneBreakdownResource(
            $vendor->load('latestChecklist.submission.inspector.inspectorProfile'),
        );
    }

    /**
     * The rating and count come from the vendor's snapshot columns; only the
     * star distribution is computed here.
     */
    public function reviews(ReviewListRequest $request, Vendor $vendor): AnonymousResourceCollection
    {
        $filters = $request->validated();

        $counts = $vendor->reviews()->visible()
            ->selectRaw('rating, COUNT(*) as total')
            ->groupBy('rating')
            ->pluck('total', 'rating');

        $photos = ReviewPhoto::query()->whereHas('review', fn (Builder $review) => $review
            ->visible()
            ->where('vendor_id', $vendor->id));

        $reviews = $vendor->reviews()->visible()
            ->with(['user', 'photos'])
            ->when($request->boolean('with_photos'), fn (Builder $query) => $query->has('photos'))
            ->latest()
            ->paginate($filters['per_page'] ?? 20);

        return ReviewResource::collection($reviews)->additional([
            'summary' => [
                'average' => $vendor->rating_average,
                'count' => $vendor->reviews_count,
                'distribution' => collect([5, 4, 3, 2, 1])
                    ->mapWithKeys(fn (int $star) => [$star => (int) ($counts[$star] ?? 0)]),
            ],
            'photos' => [
                'total' => (clone $photos)->count(),
                'items' => ReviewPhotoResource::collection((clone $photos)->latest()->limit(10)->get()),
            ],
        ]);
    }
}
