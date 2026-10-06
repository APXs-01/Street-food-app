<?php

namespace App\Http\Controllers\Api\Auth;

use App\Enums\UserRole;
use App\Http\Requests\Auth\RegisterRequest;
use Illuminate\Http\JsonResponse;

class ConsumerAuthController extends RoleAuthController
{
    protected function role(): UserRole
    {
        return UserRole::Consumer;
    }

    public function register(RegisterRequest $request): JsonResponse
    {
        return $this->registerAccount($request);
    }
}
