<?php

namespace App\Policies;

use App\Enums\StatusAudience;
use App\Enums\UserRole;
use App\Models\DailyStatus;
use App\Models\User;

class StatusPolicy
{
    /**
     * Customers post freely. A vendor needs a stall to post on its behalf.
     */
    public function create(User $user): bool
    {
        if (! $user->is_active) {
            return false;
        }

        return match ($user->role) {
            UserRole::Consumer => true,
            UserRole::Vendor => $user->vendor()->exists(),
            default => false,
        };
    }

    /**
     * The author always sees their own status, expired or hidden included.
     * Everyone else sees it only while it is active, not hidden by a
     * moderator and written by an account that is not suspended, and
     * friends-only statuses only if they are friends with the author. The
     * same rules as DailyStatus::scopeVisible(), for a single status.
     */
    public function view(User $user, DailyStatus $status): bool
    {
        if ($status->user_id === $user->id) {
            return true;
        }

        if ($status->is_hidden || ! $status->isActive() || ! $status->user->is_active) {
            return false;
        }

        return $status->audience === StatusAudience::Public
            || $user->isFriendsWith($status->user_id);
    }

    /**
     * Commenting and liking: customers and vendors, on an active status that
     * is not hidden and that they can see.
     */
    public function interact(User $user, DailyStatus $status): bool
    {
        return $user->is_active
            && in_array($user->role, [UserRole::Consumer, UserRole::Vendor], true)
            && ! $status->is_hidden
            && $status->isActive()
            && $this->view($user, $status);
    }

    public function delete(User $user, DailyStatus $status): bool
    {
        return $status->user_id === $user->id;
    }
}
