<?php

namespace App\Models;

use App\Enums\CheckResult;
use App\Enums\HygieneGrade;
use App\Enums\HygieneStatus;
use Database\Factories\VendorFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Carbon;

// Live status, hygiene and rating snapshot columns are not fillable; they are
// written only by setOpen(), applyChecklist() and refreshRatingSnapshot().
#[Fillable([
    'name',
    'description',
    'address',
    'landmark',
    'latitude',
    'longitude',
    'cover_photo_path',
    'opens_at',
    'closes_at',
    'open_days',
])]
class Vendor extends Model
{
    /** @use HasFactory<VendorFactory> */
    use HasFactory;

    /**
     * Mirrors the column defaults: a new stall starts closed, uninspected and
     * unreviewed, and says so on the instance without needing a reload.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'is_open' => false,
        'water_source_verified' => false,
        'reviews_count' => 0,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'latitude' => 'float',
            'longitude' => 'float',
            'open_days' => 'array',
            'is_open' => 'boolean',
            'status_updated_at' => 'datetime',
            'hygiene_score' => 'float',
            'hygiene_grade' => HygieneGrade::class,
            'water_source_verified' => 'boolean',
            'last_inspected_at' => 'datetime',
            'reverification_due_at' => 'datetime',
            'rating_average' => 'float',
            'reviews_count' => 'integer',
        ];
    }

    /**
     * Not inspected until the first checklist exists; once inspected the badge
     * is never hidden, it flips to reverification_pending when overdue.
     */
    protected function hygieneStatus(): Attribute
    {
        return Attribute::get(function (): HygieneStatus {
            if ($this->last_inspected_at === null) {
                return HygieneStatus::NotInspected;
            }

            return $this->reverification_due_at?->isPast()
                ? HygieneStatus::ReverificationPending
                : HygieneStatus::Verified;
        });
    }

    /**
     * The vendor opens the stall with the toggle; it closes itself at the first
     * closes_at (Asia/Colombo) after that moment. A stall opened outside its
     * hours therefore stays open until the next closing time.
     */
    public function autoClosesAt(): ?Carbon
    {
        if (! $this->is_open || $this->status_updated_at === null) {
            return null;
        }

        [$hour, $minute] = array_map('intval', explode(':', $this->closes_at));

        $closesAt = $this->status_updated_at->copy()->setTime($hour, $minute);

        return $closesAt->lte($this->status_updated_at) ? $closesAt->addDay() : $closesAt;
    }

    public function isOpenNow(): bool
    {
        return $this->autoClosesAt()?->isFuture() ?? false;
    }

    /**
     * Flip the live status. Opening restarts the auto-close clock.
     */
    public function setOpen(bool $open): void
    {
        $this->forceFill(['is_open' => $open, 'status_updated_at' => now()])->save();
    }

    /**
     * Copy the latest inspection onto the vendor so map queries can filter and
     * sort on it without joins.
     */
    public function applyChecklist(HygieneChecklist $checklist): void
    {
        $this->forceFill([
            'hygiene_score' => $checklist->score,
            'hygiene_grade' => $checklist->grade,
            'water_source_verified' => $checklist->water_source === CheckResult::Pass,
            'last_inspected_at' => $checklist->inspected_at,
            'reverification_due_at' => $checklist->inspected_at
                ->copy()
                ->addDays(config('streetbite.reverification_days')),
        ])->save();
    }

    /**
     * Recompute the star rating from visible reviews. Independent of hygiene.
     */
    public function refreshRatingSnapshot(): void
    {
        $stats = $this->reviews()->visible()
            ->selectRaw('COUNT(*) as total, AVG(rating) as average')
            ->first();

        $this->forceFill([
            'reviews_count' => (int) $stats->total,
            'rating_average' => $stats->total > 0 ? round((float) $stats->average, 2) : null,
        ])->save();
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function categories(): BelongsToMany
    {
        return $this->belongsToMany(Category::class);
    }

    /**
     * A stall is public only while its owner's account is active. Suspension
     * hides it at query time, nothing is deleted, and reactivating the owner
     * brings it straight back. The admin panel queries without this scope.
     */
    public function scopeVisible(Builder $query): void
    {
        $query->whereHas('user', fn (Builder $owner) => $owner->where('is_active', true));
    }

    /*
     * Re-verification states. Every stall is in exactly one of these four, so
     * the counts always add up to the total:
     *
     *   overdue          due date has passed
     *   due soon         due within the next $days days
     *   current          due later than that
     *   never inspected  no inspection yet, so no due date
     */

    public function scopeHygieneOverdue(Builder $query): void
    {
        $query->whereNotNull('reverification_due_at')->where('reverification_due_at', '<', now());
    }

    public function scopeHygieneDueSoon(Builder $query, int $days): void
    {
        $query->where('reverification_due_at', '>=', now())
            ->where('reverification_due_at', '<', now()->addDays($days));
    }

    public function scopeHygieneCurrent(Builder $query, int $days): void
    {
        $query->where('reverification_due_at', '>=', now()->addDays($days));
    }

    public function scopeNeverInspected(Builder $query): void
    {
        $query->whereNull('last_inspected_at');
    }

    public function isVisible(): bool
    {
        return (bool) $this->user?->is_active;
    }

    public function followers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'vendor_follows')->withTimestamps();
    }

    public function menuItems(): HasMany
    {
        return $this->hasMany(MenuItem::class);
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class);
    }

    public function statuses(): HasMany
    {
        return $this->hasMany(DailyStatus::class);
    }

    public function checklists(): HasMany
    {
        return $this->hasMany(HygieneChecklist::class);
    }

    public function latestChecklist(): HasOne
    {
        return $this->hasOne(HygieneChecklist::class)->latestOfMany('inspected_at');
    }
}
