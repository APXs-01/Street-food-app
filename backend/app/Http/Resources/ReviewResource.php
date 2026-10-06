<?php

namespace App\Http\Resources;

use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Review
 */
class ReviewResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'vendor_id' => $this->vendor_id,
            'rating' => $this->rating,
            'comment' => $this->comment,
            'observations' => $this->observations ?? [],
            // Anonymous reviews never expose the author.
            'author' => $this->is_anonymous
                ? ['anonymous' => true, 'name' => null, 'avatar_url' => null]
                : $this->whenLoaded('user', fn () => [
                    'anonymous' => false,
                    'name' => $this->user->name,
                    'avatar_url' => Media::url($this->user->avatar_path),
                ]),
            'photos' => ReviewPhotoResource::collection($this->whenLoaded('photos')),
            // Only the author is told when a moderator has hidden their review.
            // Public lists never contain hidden reviews, so this is never true there.
            'is_hidden' => $this->when($request->user()?->id === $this->user_id, $this->is_hidden),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
