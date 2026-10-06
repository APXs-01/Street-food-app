<?php

namespace App\Http\Controllers\Api;

use App\Enums\FriendshipStatus;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Friend\StoreFriendRequest;
use App\Http\Requests\Friend\UpdateFriendRequest;
use App\Http\Resources\FriendshipResource;
use App\Models\Friendship;
use App\Models\User;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\ValidationException;

class FriendController extends Controller
{
    /**
     * Accepted friends only.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate(['per_page' => ['nullable', 'integer', 'between:1,50']]);

        return FriendshipResource::collection(
            Friendship::query()
                ->accepted()
                ->involving($request->user())
                ->with(['requester', 'addressee'])
                ->orderByDesc('responded_at')
                ->orderByDesc('id')
                ->paginate($request->integer('per_page', 20)),
        );
    }

    /**
     * Requests waiting for the signed-in user to accept or decline.
     */
    public function requests(Request $request): AnonymousResourceCollection
    {
        $request->validate(['per_page' => ['nullable', 'integer', 'between:1,50']]);

        return FriendshipResource::collection(
            Friendship::query()
                ->where('addressee_id', $request->user()->id)
                ->where('status', FriendshipStatus::Pending->value)
                ->with(['requester', 'addressee'])
                ->latest()
                ->orderByDesc('id')
                ->paginate($request->integer('per_page', 20)),
        );
    }

    /**
     * Send a request. Because the table is unique per direction, both
     * directions are checked first:
     * - already friends, or they already asked you: 409 with the friendship id;
     * - you already asked, or they declined you earlier: 200 with your existing
     *   row, unchanged. A declined request is never reopened, and the sender is
     *   not told about the decline.
     */
    public function store(StoreFriendRequest $request): JsonResponse
    {
        $me = $request->user();
        $target = $this->findTarget($request);

        if ($target->id === $me->id) {
            throw ValidationException::withMessages(['user_id' => ["You can't add yourself."]]);
        }

        $forward = Friendship::where(['requester_id' => $me->id, 'addressee_id' => $target->id])->first();
        $reverse = Friendship::where(['requester_id' => $target->id, 'addressee_id' => $me->id])->first();

        if ($forward?->status === FriendshipStatus::Accepted || $reverse?->status === FriendshipStatus::Accepted) {
            return $this->conflict('You are already friends.', $forward ?? $reverse);
        }

        if ($reverse?->status === FriendshipStatus::Pending) {
            return $this->conflict("{$target->name} has already sent you a request. Accept it instead.", $reverse);
        }

        $created = false;

        if ($forward === null) {
            try {
                $forward = Friendship::create([
                    'requester_id' => $me->id,
                    'addressee_id' => $target->id,
                    'status' => FriendshipStatus::Pending,
                ]);
                $created = true;
            } catch (UniqueConstraintViolationException) {
                $forward = Friendship::where(['requester_id' => $me->id, 'addressee_id' => $target->id])->firstOrFail();
            }
        }

        return (new FriendshipResource($forward->load(['requester', 'addressee'])))
            ->response()
            ->setStatusCode($created ? 201 : 200);
    }

    public function update(UpdateFriendRequest $request, Friendship $friendship): JsonResponse|FriendshipResource
    {
        if ($friendship->status !== FriendshipStatus::Pending) {
            return $this->conflict('This request has already been answered.', $friendship);
        }

        $friendship->forceFill([
            'status' => FriendshipStatus::from($request->validated('status')),
            'responded_at' => now(),
        ])->save();

        return new FriendshipResource($friendship->load(['requester', 'addressee']));
    }

    public function destroy(Friendship $friendship): Response
    {
        Gate::authorize('delete', $friendship);

        $friendship->delete();

        return response()->noContent();
    }

    /**
     * Only active customers can be added; anyone else looks like no match.
     */
    private function findTarget(StoreFriendRequest $request): User
    {
        $data = $request->validated();

        $query = User::query()->where('role', UserRole::Consumer->value)->where('is_active', true);

        $target = isset($data['user_id'])
            ? $query->find($data['user_id'])
            : $query->where('username', ltrim($data['username'], '@'))->first();

        abort_if($target === null, 404, "We couldn't find that person.");

        return $target;
    }

    private function conflict(string $message, ?Friendship $friendship): JsonResponse
    {
        return response()->json([
            'message' => $message,
            'friendship_id' => $friendship?->id,
        ], 409);
    }
}
