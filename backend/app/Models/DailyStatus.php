<?php

namespace App\Models;

use App\Enums\MediaType;
use App\Enums\StatusAudience;
use App\Models\Concerns\Moderatable;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

// user_id is fillable so statuses can be created without a relation; set it from
// the authenticated user only. expires_at is not fillable. latitude and
// longitude are reserved for a future nearby-stories feature and are never
// accepted or exposed yet.
#[Fillable([
    'user_id',
    'vendor_id',
    'body',
    'media_path',
    'media_type',
    'audience',
    'location_label',
])]
class DailyStatus extends Model
{
    use Moderatable;

    /** @var array<string, mixed> */
    protected $attributes = [
        'is_hidden' => false,
    ];

    protected static function booted(): void
    {
        static::creating(function (self $status): void {
            $status->expires_at ??= now()->addHours(config('streetbite.status_ttl_hours'));
        });
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'media_type' => MediaType::class,
            'audience' => StatusAudience::class,
            'latitude' => 'float',
            'longitude' => 'float',
            'expires_at' => 'datetime',
            'is_hidden' => 'boolean',
            'moderated_at' => 'datetime',
        ];
    }

    /**
     * What other people may see: not hidden by a moderator, and written by an
     * account that is not suspended. Both are query-time checks, so nothing is
     * deleted and lifting a moderation or a suspension brings the status back.
     * Combine with active() for the 24 hour window.
     */
    public function scopeVisible(Builder $query): void
    {
        $query->where('is_hidden', false)
            ->whereHas('user', fn (Builder $author) => $author->where('is_active', true));
    }

    /**
     * Statuses are hidden at read time as soon as they expire; a scheduled
     * command hard-deletes old rows separately. The author can still list their
     * own expired statuses until then.
     */
    public function scopeActive(Builder $query): void
    {
        $query->where('expires_at', '>', now());
    }

    public function isActive(): bool
    {
        return $this->expires_at->isFuture();
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    public function comments(): HasMany
    {
        return $this->hasMany(StatusComment::class);
    }

    public function likes(): HasMany
    {
        return $this->hasMany(StatusLike::class);
    }
}
