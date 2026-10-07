<?php

namespace App\Observers;

use App\Enums\NotificationType;
use App\Models\Review;
use App\Services\NotificationCenter;
use Illuminate\Support\Str;

class ReviewObserver
{
    public function __construct(private NotificationCenter $notifications)
    {
    }

    /**
     * Hiding or unhiding a review changes which reviews count towards the
     * stall's stored star rating, so recalculate it.
     */
    public function updated(Review $review): void
    {
        if ($review->wasChanged('is_hidden')) {
            $review->vendor->refreshRatingSnapshot();
        }
    }

    /**
     * Tell the stall owner about a new review. A hidden review never
     * notifies, an anonymous one never reveals its author, and edits to an
     * existing review are not "new" so they do not notify.
     */
    public function created(Review $review): void
    {
        if ($review->is_hidden) {
            return;
        }

        $vendor = $review->vendor;
        $reviewer = $review->user;
        $anonymous = (bool) $review->is_anonymous;

        $this->notifications->notify(
            $vendor->user,
            NotificationType::NewReview,
            $anonymous
                ? "New review on {$vendor->name}"
                : "{$reviewer->name} reviewed {$vendor->name}",
            $review->comment === null ? null : Str::limit($review->comment, 120),
            [
                'review_id' => $review->id,
                'vendor_id' => $vendor->id,
                'rating' => $review->rating,
                'anonymous' => $anonymous,
                'actor_id' => $anonymous ? null : $reviewer->id,
                'actor_name' => $anonymous ? null : $reviewer->name,
            ],
        );
    }
}
