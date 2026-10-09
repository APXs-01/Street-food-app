<?php

namespace App\Policies;

use App\Enums\FriendshipStatus;
use App\Enums\UserRole;
use App\Models\Friendship;
use App\Models\User;

class FriendshipPolicy
{
    /**
     * The friend network is for customers.
     */
    public function create(User $user): bool
    {
        return $user->role === UserRole::Consumer && $user->is_active;
    }

    /**
     * Only the person who received the request can accept or decline it.
     */
    public function respond(User $user, Friendship $friendship): bool
    {
        return $friendship->addressee_id === $user->id && $user->is_active;
    }

    /**
     * Either side can end an accepted friendship, and a sender can withdraw a
     * pending request. A declined row is kept so the sender cannot clear it
     * and ask again.
     */
    public function delete(User $user, Friendship $friendship): bool
    {
        if (! in_array($user->id, [$friendship->requester_id, $friendship->addressee_id], true)) {
            return false;
        }

        return match ($friendship->status) {
            FriendshipStatus::Accepted => true,
            FriendshipStatus::Pending => $friendship->requester_id === $user->id,
            FriendshipStatus::Declined => false,
        };
    }
}
