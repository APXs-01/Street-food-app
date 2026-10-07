<?php

namespace App\Models;

use App\Enums\FriendshipStatus;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['requester_id', 'addressee_id', 'status', 'responded_at'])]
class Friendship extends Model
{
    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => FriendshipStatus::class,
            'responded_at' => 'datetime',
        ];
    }

    public function scopeAccepted(Builder $query): void
    {
        $query->where('status', FriendshipStatus::Accepted->value);
    }

    /**
     * Rows where the user is either side. The table is unique per direction,
     * so callers must look at both directions before creating a request.
     */
    public function scopeInvolving(Builder $query, User $user): void
    {
        $query->where(fn (Builder $sides) => $sides
            ->where('requester_id', $user->id)
            ->orWhere('addressee_id', $user->id));
    }

    public function requester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requester_id');
    }

    public function addressee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'addressee_id');
    }
}
