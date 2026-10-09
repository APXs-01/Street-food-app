<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

// submitted_at is the server timestamp and is not fillable.
#[Fillable([
    'inspector_id',
    'notes',
    'organization',
    'evidence_photo_path',
    'evidence_capture_time',
    'evidence_latitude',
    'evidence_longitude',
])]
class InspectorSubmission extends Model
{
    protected static function booted(): void
    {
        static::creating(function (self $submission): void {
            $submission->submitted_at ??= now();
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
            'evidence_capture_time' => 'datetime',
            'evidence_latitude' => 'float',
            'evidence_longitude' => 'float',
            'submitted_at' => 'datetime',
        ];
    }

    public function checklist(): BelongsTo
    {
        return $this->belongsTo(HygieneChecklist::class, 'hygiene_checklist_id');
    }

    public function inspector(): BelongsTo
    {
        return $this->belongsTo(User::class, 'inspector_id');
    }
}
