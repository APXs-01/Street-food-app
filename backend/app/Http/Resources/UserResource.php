<?php

namespace App\Http\Resources;

use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\User
 */
class UserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'username' => $this->username,
            'email' => $this->email,
            'phone' => $this->phone,
            'bio' => $this->bio,
            'avatar_url' => Media::url($this->avatar_path),
            'role' => $this->role->value,
            // Set once a vendor finishes stall onboarding; null before that.
            'vendor_id' => $this->whenLoaded('vendor', fn () => $this->vendor?->id),
            'created_at' => $this->created_at,
        ];
    }
}
