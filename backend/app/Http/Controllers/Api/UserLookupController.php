<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Friend\LookupUserRequest;
use App\Models\User;
use App\Support\Media;
use Illuminate\Http\JsonResponse;

class UserLookupController extends Controller
{
    /**
     * Find one person by their exact username so they can be added as a friend.
     * There is deliberately no partial match, no search by name, phone or email,
     * and no suggestions, so accounts cannot be enumerated. Only active
     * customers are found (the same people who can be added), the answer is a
     * bare 404 otherwise, and the route is rate limited.
     */
    public function __invoke(LookupUserRequest $request): JsonResponse
    {
        $user = User::query()
            ->where('role', UserRole::Consumer->value)
            ->where('is_active', true)
            ->where('username', ltrim($request->validated('username'), '@'))
            ->first();

        abort_if($user === null, 404, "We couldn't find that person.");

        return response()->json(['data' => [
            'id' => $user->id,
            'name' => $user->name,
            'username' => $user->username,
            'avatar_url' => Media::url($user->avatar_path),
        ]]);
    }
}
