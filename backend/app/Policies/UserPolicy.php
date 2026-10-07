<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\User;

class UserPolicy
{
    /**
     * Customers, vendors and inspectors can be suspended and reactivated.
     * Administrator accounts cannot, which also rules out an admin locking
     * themselves or the last administrator out.
     */
    public function toggleActive(User $admin, User $target): bool
    {
        return $admin->role === UserRole::SuperAdmin && $target->role !== UserRole::SuperAdmin;
    }

    /**
     * Inspector accounts are created by an administrator only.
     */
    public function createInspector(User $admin): bool
    {
        return $admin->role === UserRole::SuperAdmin;
    }
}
