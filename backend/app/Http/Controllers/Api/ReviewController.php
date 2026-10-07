<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Review\StoreReviewRequest;
use App\Http\Requests\Review\UpdateReviewRequest;
use App\Http\Resources\ReviewResource;
use App\Models\Review;
use App\Models\Vendor;
use App\Services\ImageStorage;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\ValidationException;
use Throwable;

/**
 * Writing reviews. Reading them is VendorProfileController@reviews.
 *
 * Moderation columns (is_hidden and friends) are not fillable and never appear
 * in the validated data, so nothing here can hide, unhide or clear them: a
 * hidden review stays hidden when its author edits it.
 */
class ReviewController extends Controller
{
    public function __construct(private ImageStorage $images)
    {
    }

    /**
     * Submit a review. A customer has one review per stall, so submitting again
     * updates it and answers 200 instead of a conflict.
     */
    public function store(StoreReviewRequest $request, Vendor $vendor): JsonResponse
    {
        $keys = ['vendor_id' => $vendor->id, 'user_id' => $request->user()->id];

        $review = Review::firstOrNew($keys);
        $created = ! $review->exists;

        try {
            $this->save($review, $request);
        } catch (UniqueConstraintViolationException) {
            // Two first submissions raced and the other one won: this becomes an update.
            $review = Review::where($keys)->firstOrFail();
            $created = false;

            $this->save($review, $request);
        }

        $resource = new ReviewResource($review->load(['user', 'photos']));

        if (! $created) {
            $resource->additional(['message' => 'Your existing review for this stall was updated.']);
        }

        return $resource->response()->setStatusCode($created ? 201 : 200);
    }

    /**
     * The signed-in customer's own review of a stall, to pre-fill the edit form.
     */
    public function mine(Request $request, Vendor $vendor): ReviewResource
    {
        return new ReviewResource(
            Review::where(['vendor_id' => $vendor->id, 'user_id' => $request->user()->id])
                ->with(['user', 'photos'])
                ->firstOrFail(),
        );
    }

    public function update(UpdateReviewRequest $request, Review $review): ReviewResource
    {
        $this->save($review, $request);

        return new ReviewResource($review->load(['user', 'photos']));
    }

    public function destroy(Review $review): Response
    {
        Gate::authorize('delete', $review);

        $vendor = $review->vendor;
        $paths = $review->photos()->pluck('path');

        $review->photos()->delete();
        $review->delete();

        $paths->each(fn (string $path) => $this->images->delete($path));
        $vendor->refreshRatingSnapshot();

        return response()->noContent();
    }

    /**
     * Save the review and adjust its photos, then refresh the stall's star
     * rating. New photos are added; remove_photo_ids removes chosen ones and
     * remove_photos removes all of them. The total may not exceed the maximum.
     */
    private function save(Review $review, StoreReviewRequest $request): void
    {
        $data = $request->validated();
        $newPhotos = $data['photos'] ?? [];
        $max = (int) config('streetbite.review_max_photos');

        $existing = $review->exists ? $review->photos()->get(['id', 'path']) : collect();

        $removeIds = array_values(array_unique($data['remove_photo_ids'] ?? []));

        if (array_diff($removeIds, $existing->pluck('id')->all()) !== []) {
            throw ValidationException::withMessages([
                'remove_photo_ids' => ['One or more of those photos are not on this review.'],
            ]);
        }

        $removing = $request->boolean('remove_photos') ? $existing : $existing->whereIn('id', $removeIds);

        if ($existing->count() - $removing->count() + count($newPhotos) > $max) {
            throw ValidationException::withMessages([
                'photos' => ["A review can have at most {$max} photos. Remove one first."],
            ]);
        }

        $storedPaths = array_map(
            fn (array $photo) => $this->images->store($photo['file'], "reviews/{$review->vendor_id}"),
            $newPhotos,
        );

        try {
            DB::transaction(function () use ($review, $data, $newPhotos, $storedPaths, $removing) {
                $review->fill(Arr::only($data, ['rating', 'comment', 'observations', 'is_anonymous']))->save();

                if ($removing->isNotEmpty()) {
                    $review->photos()->whereIn('id', $removing->pluck('id')->all())->delete();
                }

                foreach ($newPhotos as $position => $photo) {
                    $review->photos()->create([
                        'path' => $storedPaths[$position],
                        'capture_time' => $photo['capture_time'] ?? null,
                        'latitude' => $photo['latitude'] ?? null,
                        'longitude' => $photo['longitude'] ?? null,
                    ]);
                }
            });
        } catch (Throwable $e) {
            array_map($this->images->delete(...), $storedPaths);

            throw $e;
        }

        $removing->each(fn ($photo) => $this->images->delete($photo->path));

        $review->vendor->refreshRatingSnapshot();
    }
}
