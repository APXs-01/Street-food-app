<?php

namespace App\Models;

use App\Enums\CheckResult;
use App\Enums\HygieneGrade;
use InvalidArgumentException;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

// score, grade and inspected_at are not fillable: they are derived on save so a
// stored rating can never disagree with its criteria (NFR-05).
#[Fillable([
    'vendor_id',
    'water_source',
    'utensil_glove_hygiene',
    'waste_disposal',
    'food_covering',
    'overall_cleanliness',
])]
class HygieneChecklist extends Model
{
    public const CRITERIA = [
        'water_source',
        'utensil_glove_hygiene',
        'waste_disposal',
        'food_covering',
        'overall_cleanliness',
    ];

    protected static function booted(): void
    {
        static::saving(function (self $checklist): void {
            $checklist->score = $checklist->calculateScore();
            $checklist->grade = HygieneGrade::fromScore($checklist->score);
            $checklist->inspected_at ??= now();
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
            'water_source' => CheckResult::class,
            'utensil_glove_hygiene' => CheckResult::class,
            'waste_disposal' => CheckResult::class,
            'food_covering' => CheckResult::class,
            'overall_cleanliness' => CheckResult::class,
            'score' => 'float',
            'grade' => HygieneGrade::class,
            'inspected_at' => 'datetime',
        ];
    }

    /**
     * Pass = 1, Partial = 0.5, Fail = 0 per criterion, scaled to 5.0.
     *
     * @param  array<string, CheckResult>  $results  keyed by criterion
     */
    public static function scoreFor(array $results): float
    {
        $points = 0.0;

        foreach (self::CRITERIA as $criterion) {
            $result = $results[$criterion] ?? null;

            if (! $result instanceof CheckResult) {
                throw new InvalidArgumentException("Missing result for {$criterion}.");
            }

            $points += $result->points();
        }

        return round($points / count(self::CRITERIA) * 5, 2);
    }

    public function calculateScore(): float
    {
        return self::scoreFor(array_combine(
            self::CRITERIA,
            array_map(fn (string $criterion) => $this->getAttribute($criterion), self::CRITERIA),
        ));
    }

    /**
     * The criteria this inspection failed.
     *
     * @return array<int, string>
     */
    public function failedCriteria(): array
    {
        return array_values(array_filter(
            self::CRITERIA,
            fn (string $criterion) => $this->getAttribute($criterion) === CheckResult::Fail,
        ));
    }

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    public function submission(): HasOne
    {
        return $this->hasOne(InspectorSubmission::class);
    }
}
