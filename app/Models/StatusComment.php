<?php

namespace App\Models;

use App\Models\Concerns\Moderatable;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

// Moderation columns are not fillable.
#[Fillable(['user_id', 'body'])]
class StatusComment extends Model
{
    use Moderatable;

    /** @var array<string, mixed> */
    protected $attributes = [
        'is_hidden' => false,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_hidden' => 'boolean',
            'moderated_at' => 'datetime',
        ];
    }

    /**
     * Not hidden by a moderator and written by an account that is not
     * suspended, checked at query time.
     */
    public function scopeVisible(Builder $query): void
    {
        $query->where('is_hidden', false)
            ->whereHas('user', fn (Builder $author) => $author->where('is_active', true));
    }

    public function status(): BelongsTo
    {
        return $this->belongsTo(DailyStatus::class, 'daily_status_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
