<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Notification\NotificationIndexRequest;
use App\Http\Resources\NotificationResource;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * Reading notifications. They are created by the model observers, never here.
 * Every query is scoped to the signed-in user, so another person's notification
 * id simply answers 404.
 */
class NotificationController extends Controller
{
    /**
     * Newest first. Filter with unread=1 or type=. The response also carries
     * the total unread_count, for the badge.
     */
    public function index(NotificationIndexRequest $request): AnonymousResourceCollection
    {
        $user = $request->user();

        $notifications = $user->appNotifications()
            ->when($request->boolean('unread'), fn (Builder $query) => $query->unread())
            ->when($request->validated('type'), fn (Builder $query, string $type) => $query->where('type', $type))
            ->latest()
            ->orderByDesc('id')
            ->paginate($request->integer('per_page', 20));

        return NotificationResource::collection($notifications)->additional([
            'unread_count' => $user->appNotifications()->unread()->count(),
        ]);
    }

    public function markRead(Request $request, string $notification): JsonResponse
    {
        $notification = $request->user()->appNotifications()->findOrFail($notification);

        $notification->markAsRead();

        // Wrapped by hand: the resource has its own `data` key (the payload), so
        // Laravel would otherwise skip its automatic `data` wrapper.
        return response()->json(['data' => (new NotificationResource($notification))->resolve()]);
    }

    public function readAll(Request $request): JsonResponse
    {
        $updated = $request->user()->appNotifications()->unread()->update(['read_at' => now()]);

        return response()->json(['updated' => $updated]);
    }
}
