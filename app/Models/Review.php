<?php

namespace App\Models;

use App\Models\Concerns\Moderatable;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

// vendor_id and user_id are fillable so updateOrCreate() can key on them; they
// must only ever come from the route and the authenticated user, never input.
// Moderation columns are not fillable.
#[Fillable(['vendor_id', 'user_id', 'rating', 'comment', 'observations', 'is_anonymous'])]
class Review extends Model
{
    use Moderatable;

    /**
     * Mirrors the column defaults, so observers and resources never see null.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'is_anonymous' => false,
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
            'rating' => 'integer',
            'observations' => 'array',
            'is_anonymous' => 'boolean',
            'is_hidden' => 'boolean',
            'moderated_at' => 'datetime',
        ];
    }

    /**
     * What the public sees and what counts towards a stall's star rating: not
     * hidden by a moderator, and written by an account that is not suspended.
     * Both are query-time checks, so lifting either brings the review back.
     */
    public function scopeVisible(Builder $query): void
    {
        $query->where('is_hidden', false)
            ->whereHas('user', fn (Builder $author) => $author->where('is_active', true));
    }

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function photos(): HasMany
    {
        return $this->hasMany(ReviewPhoto::class);
    }

    public function reports(): HasMany
    {
        return $this->hasMany(ReviewReport::class);
    }
}
