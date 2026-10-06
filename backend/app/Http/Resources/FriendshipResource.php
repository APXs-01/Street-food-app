<?php

namespace App\Http\Resources;

use App\Enums\FriendshipStatus;
use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A friendship seen from the signed-in user: `user` is always the other person.
 * Expects requester and addressee to be loaded.
 *
 * @mixin \App\Models\Friendship
 */
class FriendshipResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $outgoing = $this->requester_id === $request->user()->id;
        $other = $outgoing ? $this->addressee : $this->requester;

        // A sender is never told their request was declined; it just stays pending.
        $hideDecline = $outgoing && $this->status === FriendshipStatus::Declined;

        return [
            'id' => $this->id,
            'status' => $hideDecline ? FriendshipStatus::Pending->value : $this->status->value,
            'direction' => $outgoing ? 'outgoing' : 'incoming',
            'user' => [
                'id' => $other->id,
                'name' => $other->name,
                'username' => $other->username,
                'avatar_url' => Media::url($other->avatar_path),
            ],
            'created_at' => $this->created_at,
            'responded_at' => $hideDecline ? null : $this->responded_at,
        ];
    }
}
