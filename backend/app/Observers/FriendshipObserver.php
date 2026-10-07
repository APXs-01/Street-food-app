<?php

namespace App\Observers;

use App\Enums\FriendshipStatus;
use App\Enums\NotificationType;
use App\Models\Friendship;
use App\Services\NotificationCenter;

class FriendshipObserver
{
    public function __construct(private NotificationCenter $notifications)
    {
    }

    /**
     * A new pending request notifies the person it is addressed to. A re-sent
     * request after a decline never creates a row, so it never notifies.
     */
    public function created(Friendship $friendship): void
    {
        if ($friendship->status !== FriendshipStatus::Pending) {
            return;
        }

        $sender = $friendship->requester;

        $this->notifications->notify(
            $friendship->addressee,
            NotificationType::FriendRequest,
            "{$sender->name} sent you a friend request",
            null,
            [
                'friendship_id' => $friendship->id,
                'actor_id' => $sender->id,
                'actor_name' => $sender->name,
                'actor_username' => $sender->username,
            ],
        );
    }

    /**
     * Accepting notifies the sender. Declining is silent.
     */
    public function updated(Friendship $friendship): void
    {
        if (! $friendship->wasChanged('status') || $friendship->status !== FriendshipStatus::Accepted) {
            return;
        }

        $accepter = $friendship->addressee;

        $this->notifications->notify(
            $friendship->requester,
            NotificationType::FriendAccepted,
            "{$accepter->name} accepted your friend request",
            null,
            [
                'friendship_id' => $friendship->id,
                'actor_id' => $accepter->id,
                'actor_name' => $accepter->name,
                'actor_username' => $accepter->username,
            ],
        );
    }
}
