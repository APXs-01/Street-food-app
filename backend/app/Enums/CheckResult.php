<?php

namespace App\Enums;

/**
 * Outcome of a single hygiene criterion.
 */
enum CheckResult: string
{
    case Pass = 'pass';
    case Partial = 'partial';
    case Fail = 'fail';

    public function points(): float
    {
        return match ($this) {
            self::Pass => 1.0,
            self::Partial => 0.5,
            self::Fail => 0.0,
        };
    }

    public function label(): string
    {
        return ucfirst($this->value);
    }

    /**
     * Badge colour in the admin panel: ok, warn or danger.
     */
    public function tone(): string
    {
        return match ($this) {
            self::Pass => 'ok',
            self::Partial => 'warn',
            self::Fail => 'danger',
        };
    }
}
