<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\User;
use App\Models\Vendor;

class VendorPolicy
{
    /**
     * Only vendor accounts onboard a stall. The one-stall-per-account rule is
     * checked in the controller so it can return a friendly 409.
     */
    public function create(User $user): bool
    {
        return $user->role === UserRole::Vendor;
    }

    public function update(User $user, Vendor $vendor): bool
    {
        return $vendor->user_id === $user->id;
    }

    /**
     * The dashboard figures are for the stall's own owner only.
     */
    public function viewAnalytics(User $user, Vendor $vendor): bool
    {
        return $vendor->user_id === $user->id && $user->is_active;
    }

    /**
     * Only an administrator deletes a stall, and only from the admin panel: the
     * API has no delete route. See VendorDeletion for what goes with it.
     */
    public function delete(User $user, Vendor $vendor): bool
    {
        return $user->role === UserRole::SuperAdmin;
    }

    /**
     * Customers follow stalls to see their statuses in the feed.
     */
    public function follow(User $user, Vendor $vendor): bool
    {
        return $user->role === UserRole::Consumer && $user->is_active;
    }
}
