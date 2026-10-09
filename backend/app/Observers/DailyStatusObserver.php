<?php

namespace App\Observers;

use App\Enums\NotificationType;
use App\Enums\StatusAudience;
use App\Models\DailyStatus;
use App\Services\NotificationCenter;
use Illuminate\Support\Str;

class DailyStatusObserver
{
    public function __construct(private NotificationCenter $notifications)
    {
    }

    /**
     * When a stall posts, tell the customers who follow it. Only the stall's
     * own public posts count: a customer tagging a stall in their status does
     * not notify that stall's followers. Inactive followers are skipped.
     *
     * The fan-out is synchronous (bulk inserts). If followers grow into the
     * thousands, move this into a queued job.
     */
    public function created(DailyStatus $status): void
    {
        if ($status->vendor_id === null || $status->audience !== StatusAudience::Public) {
            return;
        }

        $vendor = $status->vendor;

        if ($vendor->user_id !== $status->user_id) {
            return;
        }

        $followerIds = $vendor->followers()
            ->where('users.is_active', true)
            ->pluck('users.id')
            ->all();

        if ($followerIds === []) {
            return;
        }

        $this->notifications->notifyMany(
            $followerIds,
            NotificationType::VendorStatus,
            "{$vendor->name} posted a new status",
            $status->body === null ? null : Str::limit($status->body, 120),
            [
                'status_id' => $status->id,
                'vendor_id' => $vendor->id,
                'vendor_name' => $vendor->name,
            ],
        );
    }
}
