<?php

namespace App\Http\Controllers\Api;

use App\Enums\MediaType;
use App\Enums\StatusAudience;
use App\Enums\UserRole;
use App\Http\Controllers\Api\Concerns\ChecksStatusVisibility;
use App\Http\Controllers\Controller;
use App\Http\Requests\Status\StatusIndexRequest;
use App\Http\Requests\Status\StoreStatusRequest;
use App\Http\Resources\StatusCommentResource;
use App\Http\Resources\StatusResource;
use App\Models\DailyStatus;
use App\Services\ImageStorage;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;
use Throwable;

class StatusController extends Controller
{
    use ChecksStatusVisibility;

    public function __construct(private ImageStorage $images)
    {
    }

    /**
     * The feed: active statuses from the user's own posts, accepted friends
     * (public and friends-only), and followed stalls (public). With mine=1 it
     * is the user's own statuses instead, expired ones included until the
     * daily purge removes them.
     */
    public function index(StatusIndexRequest $request): AnonymousResourceCollection
    {
        $me = $request->user();

        // A tagged stall whose owner is suspended shows as no stall at all, and
        // hidden or suspended people's comments are not counted.
        $query = DailyStatus::query()
            ->with(['user', 'vendor' => fn ($vendor) => $vendor->visible()])
            ->withCount(['likes', 'comments' => fn ($comments) => $comments->visible()])
            ->withExists(['likes as liked_by_me' => fn (Builder $likes) => $likes->where('user_id', $me->id)]);

        if ($request->boolean('mine')) {
            // Your own statuses, expired and hidden ones included (is_hidden tells you).
            $query->where('user_id', $me->id);
        } else {
            $friendIds = $me->friendIds();
            $stallOwnerIds = $me->followedVendors()->pluck('vendors.user_id');

            $query->active()->visible()->where(fn (Builder $visible) => $visible
                ->where('user_id', $me->id)
                ->orWhereIn('user_id', $friendIds)
                ->orWhere(fn (Builder $stalls) => $stalls
                    ->whereIn('user_id', $stallOwnerIds)
                    ->where('audience', StatusAudience::Public->value)));
        }

        return StatusResource::collection(
            $query->latest()->orderByDesc('id')->paginate($request->integer('per_page', 20)),
        );
    }

    public function store(StoreStatusRequest $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validated();
        $isVendor = $user->role === UserRole::Vendor;

        $mediaPath = null;
        $mediaType = null;

        if ($file = $request->file('media')) {
            $mediaType = str_starts_with((string) $file->getMimeType(), 'video/') ? MediaType::Video : MediaType::Image;
            $mediaPath = $mediaType === MediaType::Video
                ? $this->images->storeVideo($file, "statuses/{$user->id}")
                : $this->images->store($file, "statuses/{$user->id}");
        }

        try {
            $status = DailyStatus::create([
                'user_id' => $user->id,
                'vendor_id' => $isVendor ? $user->vendor->id : ($data['vendor_id'] ?? null),
                'body' => $data['caption'] ?? null,
                'media_path' => $mediaPath,
                'media_type' => $mediaType,
                'audience' => $isVendor ? StatusAudience::Public : ($data['audience'] ?? StatusAudience::Public->value),
                'location_label' => $data['location_label'] ?? null,
            ]);
        } catch (Throwable $e) {
            $this->images->delete($mediaPath);

            throw $e;
        }

        $status->load(['user', 'vendor'])
            ->setAttribute('likes_count', 0)
            ->setAttribute('comments_count', 0)
            ->setAttribute('liked_by_me', false);

        return (new StatusResource($status))->response()->setStatusCode(201);
    }

    /**
     * The status with its first page of comments, oldest first; page through
     * the rest with ?page=.
     */
    public function show(Request $request, DailyStatus $status): StatusResource
    {
        $this->ensureVisible($status);

        $status->load(['user', 'vendor' => fn ($vendor) => $vendor->visible()])
            ->loadCount(['likes', 'comments' => fn ($comments) => $comments->visible()])
            ->setAttribute('liked_by_me', $status->likes()->where('user_id', $request->user()->id)->exists());

        $comments = $status->comments()->visible()->with('user')->oldest()->orderBy('id')->paginate(20);

        return (new StatusResource($status))->additional([
            'comments' => StatusCommentResource::collection($comments)->response()->getData(true),
        ]);
    }

    public function destroy(DailyStatus $status): Response
    {
        $this->ensureVisible($status);
        Gate::authorize('delete', $status);

        $status->delete();
        $this->images->delete($status->media_path);

        return response()->noContent();
    }
}
