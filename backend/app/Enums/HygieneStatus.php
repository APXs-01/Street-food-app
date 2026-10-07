<?php

namespace App\Enums;

/**
 * What the vendor's hygiene badge should show. Never hides the badge.
 */
enum HygieneStatus: string
{
    case NotInspected = 'not_inspected';
    case Verified = 'verified';
    case ReverificationPending = 'reverification_pending';
}
