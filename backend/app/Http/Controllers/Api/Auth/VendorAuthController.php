<?php

namespace App\Http\Controllers\Api\Auth;

use App\Enums\UserRole;
use App\Http\Requests\Auth\RegisterRequest;
use Illuminate\Http\JsonResponse;

/**
 * Registration only creates the account. The stall is created afterwards by the
 * onboarding step and goes live immediately.
 */
class VendorAuthController extends RoleAuthController
{
    protected function role(): UserRole
    {
        return UserRole::Vendor;
    }

    public function register(RegisterRequest $request): JsonResponse
    {
        return $this->registerAccount($request);
    }
}
