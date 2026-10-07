<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ChecksStatusVisibility;
use App\Http\Controllers\Controller;
use App\Http\Requests\Status\StoreCommentRequest;
use App\Http\Resources\StatusCommentResource;
use App\Models\DailyStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class StatusCommentController extends Controller
{
    use ChecksStatusVisibility;

    public function store(StoreCommentRequest $request, DailyStatus $status): JsonResponse
    {
        $this->ensureVisible($status);
        Gate::authorize('interact', $status);

        $comment = $status->comments()->create([
            'user_id' => $request->user()->id,
            'body' => $request->validated('body'),
        ]);

        return (new StatusCommentResource($comment->load('user')))->response()->setStatusCode(201);
    }
}
