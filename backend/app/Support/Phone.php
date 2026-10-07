<?php

namespace App\Support;

/**
 * Normalises Sri Lankan style phone input to +94XXXXXXXXX so it can be used as
 * a unique login identifier. Input that cannot be normalised is returned with
 * formatting stripped and fails the +digits validation rule.
 */
final class Phone
{
    public static function normalize(string $input): string
    {
        $number = preg_replace('/[^\d+]/', '', trim($input));
        $number = preg_replace('/(?!^)\+/', '', $number);

        if (str_starts_with($number, '00')) {
            $number = '+'.substr($number, 2);
        }

        if (str_starts_with($number, '+')) {
            return $number;
        }

        if (strlen($number) === 10 && $number[0] === '0') {
            return '+94'.substr($number, 1);
        }

        if (strlen($number) === 9) {
            return '+94'.$number;
        }

        if (strlen($number) === 11 && str_starts_with($number, '94')) {
            return '+'.$number;
        }

        return $number;
    }
}
