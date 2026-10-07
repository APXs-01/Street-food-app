<?php

namespace App\Observers;

use App\Enums\NotificationType;
use App\Models\StatusLike;
use App\Services\NotificationCenter;

class StatusLikeObserver
{
    public function __construct(private NotificationCenter $notifications)
    {
    }

    /**
     * Tell the status owner about a like, unless it is their own. Liking,
     * unliking and liking again must not notify twice, so one notification is
     * kept per person and status.
     */
    public function created(StatusLike $like): void
    {
        $status = $like->status;

        if ($status->user_id === $like->user_id) {
            return;
        }

        $liker = $like->user;

        $this->notifications->notify(
            $status->user,
            NotificationType::StatusLike,
            "{$liker->name} liked your status",
            null,
            [
                'status_id' => $status->id,
                'actor_id' => $liker->id,
                'actor_name' => $liker->name,
            ],
            uniqueBy: ['status_id', 'actor_id'],
        );
    }
}
