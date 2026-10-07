<?php

namespace App\Enums;

enum HygieneGrade: string
{
    case APlus = 'A+';
    case A = 'A';
    case B = 'B';
    case NeedsImprovement = 'needs_improvement';

    /**
     * A+ 4.5-5.0, A 3.5-4.49, B 2.5-3.49, below 2.5 needs improvement.
     */
    public static function fromScore(float $score): self
    {
        return match (true) {
            $score >= 4.5 => self::APlus,
            $score >= 3.5 => self::A,
            $score >= 2.5 => self::B,
            default => self::NeedsImprovement,
        };
    }

    public function label(): string
    {
        return match ($this) {
            self::NeedsImprovement => 'Needs Improvement',
            default => $this->value,
        };
    }

    /**
     * Badge colour in the admin panel: ok, warn or danger.
     */
    public function tone(): string
    {
        return match ($this) {
            self::APlus, self::A => 'ok',
            self::B => 'warn',
            self::NeedsImprovement => 'danger',
        };
    }
}
