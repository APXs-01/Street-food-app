<?php

namespace App\Http\Resources;

use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\ReviewPhoto
 */
class ReviewPhotoResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'url' => Media::url($this->path),
            // Server upload time is the source of truth; capture time is device-reported.
            'uploaded_at' => $this->created_at,
            'capture_time' => $this->capture_time,
        ];
    }
}
