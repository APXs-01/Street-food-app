<?php

namespace App\Enums;

/**
 * Account type. Values double as the Spatie role names.
 */
enum UserRole: string
{
    case Consumer = 'consumer';
    case Vendor = 'vendor';
    case Inspector = 'inspector';
    case SuperAdmin = 'super-admin';

    public function label(): string
    {
        return match ($this) {
            self::Consumer => 'customer',
            self::Vendor => 'vendor',
            self::Inspector => 'inspector',
            self::SuperAdmin => 'administrator',
        };
    }
}
