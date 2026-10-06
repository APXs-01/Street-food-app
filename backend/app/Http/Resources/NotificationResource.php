<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * `title` and `body` are English fallbacks; the app builds its own localised
 * text from `type` and `data`.
 *
 * @mixin \App\Models\AppNotification
 */
class NotificationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'title' => $this->title,
            'body' => $this->body,
            'data' => $this->data ?? (object) [],
            'is_read' => $this->read_at !== null,
            'read_at' => $this->read_at,
            'created_at' => $this->created_at,
        ];
    }
}
