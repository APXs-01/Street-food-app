<?php

namespace App\Http\Controllers\Api\Auth;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * Shared token login for the role specific endpoints. Each subclass only
 * accepts accounts of its own role.
 */
abstract class RoleAuthController extends Controller
{
    abstract protected function role(): UserRole;

    public function login(LoginRequest $request): JsonResponse
    {
        [$column, $value] = $request->identifier();

        $user = User::where($column, $value)->first();

        if ($user === null || ! Hash::check($request->input('password'), $user->password)) {
            throw ValidationException::withMessages(['login' => [trans('auth.failed')]]);
        }

        if (! $user->is_active) {
            return response()->json(['message' => 'This account has been suspended.'], 403);
        }

        // Only reached with a correct password, so this does not reveal which
        // accounts exist; it lets the app send the user to the right login.
        if ($user->role !== $this->role()) {
            return response()->json([
                'message' => "This account is a {$user->role->label()} account. Please use the {$user->role->label()} login.",
                'role' => $user->role->value,
            ], 403);
        }

        $user->forceFill(['last_login_at' => now()])->save();

        return $this->tokenResponse($user, $request->input('device_name'));
    }

    protected function registerAccount(RegisterRequest $request): JsonResponse
    {
        $user = User::createWithRole(
            $this->role(),
            $request->safe()->only(['name', 'email', 'phone', 'username', 'password']),
        );

        return $this->tokenResponse($user, $request->input('device_name'), 201);
    }

    private function tokenResponse(User $user, ?string $deviceName, int $status = 200): JsonResponse
    {
        return response()->json([
            'token' => $user->createToken($deviceName ?? 'mobile')->plainTextToken,
            'user' => new UserResource($user->load('vendor')),
        ], $status);
    }
}
