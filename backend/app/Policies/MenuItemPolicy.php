<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\MenuItem;
use App\Models\User;

class MenuItemPolicy
{
    /**
     * A vendor account with a stall can add menu items to it.
     */
    public function create(User $user): bool
    {
        return $user->role === UserRole::Vendor && $user->vendor()->exists();
    }

    public function update(User $user, MenuItem $menuItem): bool
    {
        return $menuItem->vendor->user_id === $user->id;
    }

    public function delete(User $user, MenuItem $menuItem): bool
    {
        return $this->update($user, $menuItem);
    }
}
