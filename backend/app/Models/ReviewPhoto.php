<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

// created_at is the server upload time and the source of truth; capture_time and
// the coordinates are whatever the device reported.
#[Fillable(['path', 'capture_time', 'latitude', 'longitude'])]
class ReviewPhoto extends Model
{
    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'capture_time' => 'datetime',
            'latitude' => 'float',
            'longitude' => 'float',
        ];
    }

    public function review(): BelongsTo
    {
        return $this->belongsTo(Review::class);
    }
}
