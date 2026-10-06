<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ChecksStatusVisibility;
use App\Http\Controllers\Controller;
use App\Models\DailyStatus;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class StatusLikeController extends Controller
{
    use ChecksStatusVisibility;

    /**
     * Like the status, or take the like back if it is already there.
     */
    public function toggle(Request $request, DailyStatus $status): JsonResponse
    {
        $this->ensureVisible($status);
        Gate::authorize('interact', $status);

        $userId = $request->user()->id;
        $existing = $status->likes()->where('user_id', $userId)->first();

        if ($existing) {
            $existing->delete();
            $liked = false;
        } else {
            try {
                $status->likes()->create(['user_id' => $userId]);
            } catch (UniqueConstraintViolationException) {
                // A double tap raced itself; the like exists either way.
            }

            $liked = true;
        }

        return response()->json([
            'liked' => $liked,
            'likes_count' => $status->likes()->count(),
        ]);
    }
}
