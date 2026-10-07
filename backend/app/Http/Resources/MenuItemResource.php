<?php

namespace App\Http\Resources;

use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\MenuItem
 */
class MenuItemResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'vendor_id' => $this->vendor_id,
            'name' => $this->name,
            'description' => $this->description,
            'price' => (float) $this->price,
            'photo_url' => Media::url($this->photo_path),
            'is_available' => $this->is_available,
            'is_fresh_today' => $this->is_fresh_today,
            'fresh_marked_at' => $this->fresh_marked_at,
        ];
    }
}
