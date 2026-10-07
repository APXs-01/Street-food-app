<?php

namespace App\Models\Concerns;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Shared moderation actions for reviews, statuses and comments, which all carry
 * is_hidden, hidden_reason, moderated_by and moderated_at. The columns are not
 * mass assignable, so this is the only way they change.
 */
trait Moderatable
{
    public function hideBy(User $moderator, ?string $reason = null): void
    {
        $this->forceFill([
            'is_hidden' => true,
            'hidden_reason' => filled($reason) ? $reason : null,
            'moderated_by' => $moderator->id,
            'moderated_at' => now(),
        ])->save();
    }

    /**
     * Unhiding clears the reason but keeps who acted last, and when.
     */
    public function unhideBy(User $moderator): void
    {
        $this->forceFill([
            'is_hidden' => false,
            'hidden_reason' => null,
            'moderated_by' => $moderator->id,
            'moderated_at' => now(),
        ])->save();
    }

    public function moderator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'moderated_by');
    }
}
