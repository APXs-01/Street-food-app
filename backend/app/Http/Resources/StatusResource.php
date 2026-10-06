<?php

namespace App\Http\Resources;

use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Exact coordinates are never returned, only the free-text location label.
 *
 * @mixin \App\Models\DailyStatus
 */
class StatusResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'caption' => $this->body,
            'media' => $this->media_path === null ? null : [
                'type' => $this->media_type?->value,
                'url' => Media::url($this->media_path),
            ],
            'audience' => $this->audience->value,
            'location_label' => $this->location_label,
            'author' => $this->whenLoaded('user', fn () => [
                'id' => $this->user->id,
                'name' => $this->user->name,
                'username' => $this->user->username,
                'avatar_url' => Media::url($this->user->avatar_path),
                'role' => $this->user->role->value,
            ]),
            // The stall this status is about: a vendor's own stall, or one a customer tagged.
            'vendor' => $this->whenLoaded('vendor', fn () => $this->vendor === null ? null : [
                'id' => $this->vendor->id,
                'name' => $this->vendor->name,
            ]),
            'likes_count' => $this->whenCounted('likes'),
            'comments_count' => $this->whenCounted('comments'),
            'liked_by_me' => $this->when(isset($this->liked_by_me), fn () => (bool) $this->liked_by_me),
            'is_active' => $this->isActive(),
            // Only the author is told a moderator has hidden their status; it never
            // appears in anyone else's feed, so it is never true for other viewers.
            'is_hidden' => $this->when($request->user()?->id === $this->user_id, $this->is_hidden),
            'expires_at' => $this->expires_at,
            'created_at' => $this->created_at,
        ];
    }
}
