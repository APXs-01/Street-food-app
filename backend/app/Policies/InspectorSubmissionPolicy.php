<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\User;
use App\Models\Vendor;

class InspectorSubmissionPolicy
{
    /**
     * Only active inspector accounts submit inspections.
     */
    public function create(User $user): bool
    {
        return $user->role === UserRole::Inspector && $user->is_active;
    }

    /**
     * A stall's audit trail is open to inspectors, administrators and the
     * stall's own vendor, who needs it to dispute a score. Consumers and other
     * vendors are blocked.
     */
    public function viewForVendor(User $user, Vendor $vendor): bool
    {
        return in_array($user->role, [UserRole::Inspector, UserRole::SuperAdmin], true)
            || $vendor->user_id === $user->id;
    }
}
