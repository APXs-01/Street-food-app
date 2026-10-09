<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['name', 'description', 'price', 'photo_path', 'is_available', 'fresh_marked_at'])]
class MenuItem extends Model
{
    /** @var array<string, mixed> */
    protected $attributes = [
        'is_available' => true,
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'is_available' => 'boolean',
            'fresh_marked_at' => 'datetime',
        ];
    }

    /**
     * Freshness expires on its own: only an item marked today counts.
     */
    protected function isFreshToday(): Attribute
    {
        return Attribute::get(fn (): bool => $this->fresh_marked_at?->isToday() ?? false);
    }

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }
}
