<?php

namespace App\Http\Resources;

use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Vendor
 */
class VendorResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'stall_code' => $this->stall_code,
            'name' => $this->name,
            'description' => $this->description,
            'address' => $this->address,
            'landmark' => $this->landmark,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'cover_photo_url' => Media::url($this->cover_photo_path),
            'categories' => $this->whenLoaded('categories', fn () => $this->categories
                ->map(fn ($category) => ['slug' => $category->slug, 'name' => $category->name])
                ->values()),
            'schedule' => [
                'opens_at' => substr($this->opens_at, 0, 5),
                'closes_at' => substr($this->closes_at, 0, 5),
                // null means every day
                'open_days' => $this->open_days,
            ],
            'status' => [
                'is_open' => $this->is_open,
                'is_open_now' => $this->isOpenNow(),
                'auto_closes_at' => $this->autoClosesAt(),
                'updated_at' => $this->status_updated_at,
            ],
            'hygiene' => [
                'status' => $this->hygiene_status->value,
                'score' => $this->hygiene_score,
                'grade' => $this->hygiene_grade?->value,
                'grade_label' => $this->hygiene_grade?->label(),
                'water_source_verified' => $this->water_source_verified,
                'last_inspected_at' => $this->last_inspected_at,
                'reverification_due_at' => $this->reverification_due_at,
            ],
            'rating' => [
                'average' => $this->rating_average,
                'count' => $this->reviews_count,
            ],
            // Only on the single-stall view: whether the signed-in user follows it.
            'followed_by_me' => $this->when(isset($this->followed_by_me), fn () => (bool) $this->followed_by_me),
            'menu' => MenuItemResource::collection($this->whenLoaded('menuItems')),
        ];
    }
}
