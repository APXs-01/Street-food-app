<?php

namespace App\Http\Controllers\Api\Auth;

use App\Enums\UserRole;

/**
 * Login only. Inspector accounts are created by an admin.
 */
class InspectorAuthController extends RoleAuthController
{
    protected function role(): UserRole
    {
        return UserRole::Inspector;
    }
}
