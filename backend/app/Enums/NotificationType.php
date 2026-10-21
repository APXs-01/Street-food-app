<?php

namespace App\Enums;

/**
 * The `type` stored on an app notification. The app builds the localised text
 * from the type and the `data` payload; the stored title and body are English
 * fallbacks.
 */
enum NotificationType: string
{
    case StatusComment = 'status_comment';
    case StatusLike = 'status_like';
    case FriendRequest = 'friend_request';
    case FriendAccepted = 'friend_accepted';
    case VendorStatus = 'vendor_status';
    case NewReview = 'new_review';
    case HygieneUpdated = 'hygiene_updated';
    case HygieneOverdue = 'hygiene_overdue';
}
