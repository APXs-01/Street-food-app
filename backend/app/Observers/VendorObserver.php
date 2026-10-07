<?php

namespace App\Observers;

use App\Enums\NotificationType;
use App\Models\Vendor;
use App\Services\NotificationCenter;

class VendorObserver
{
    public function __construct(private NotificationCenter $notifications)
    {
    }

    /**
     * Tell the stall owner when their hygiene rating changes: the first
     * inspection, a different score or a different grade. An inspection that
     * lands on the same score changes nothing and does not notify.
     */
    public function updated(Vendor $vendor): void
    {
        if (! $vendor->wasChanged(['hygiene_score', 'hygiene_grade']) || $vendor->hygiene_grade === null) {
            return;
        }

        // Inside the updated event getOriginal() still holds the previous values.
        $previousGrade = $vendor->getOriginal('hygiene_grade');
        $previousScore = $vendor->getOriginal('hygiene_score');

        $this->notifications->notify(
            $vendor->user,
            NotificationType::HygieneUpdated,
            'Your hygiene rating was updated',
            sprintf('Your stall is now rated %s (%s out of 5).', $vendor->hygiene_grade->label(), number_format($vendor->hygiene_score, 1)),
            [
                'vendor_id' => $vendor->id,
                'grade' => $vendor->hygiene_grade->value,
                'score' => $vendor->hygiene_score,
                'previous_grade' => $previousGrade?->value,
                'previous_score' => $previousScore,
                'first_inspection' => $previousGrade === null,
            ],
        );
    }
}
