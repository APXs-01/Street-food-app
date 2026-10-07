<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One pin or list row on the map. Expects a distance_km attribute set by
 * MapController.
 *
 * @mixin \App\Models\Vendor
 */
class MapVendorResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'lat' => $this->latitude,
            'lng' => $this->longitude,
            'distance_km' => round($this->distance_km, 2),
            'walking_minutes' => (int) round($this->distance_km / config('streetbite.walking_speed_kmh') * 60),
            // Live status, so a stall left toggled open past its closing time reads closed.
            'is_open' => $this->isOpenNow(),
            'hygiene_grade' => $this->hygiene_grade?->value,
            'hygiene_status' => $this->hygiene_status->value,
            'star_rating' => $this->rating_average,
        ];
    }
}
