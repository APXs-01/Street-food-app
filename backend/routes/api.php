<?php

use App\Http\Controllers\Api\Auth\ConsumerAuthController;
use App\Http\Controllers\Api\Auth\InspectorAuthController;
use App\Http\Controllers\Api\Auth\SessionController;
use App\Http\Controllers\Api\Auth\VendorAuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\FeatureController;
use App\Http\Controllers\Api\FriendController;
use App\Http\Controllers\Api\InspectorController;
use App\Http\Controllers\Api\MapController;
use App\Http\Controllers\Api\MenuController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\ReviewReportController;
use App\Http\Controllers\Api\StatusCommentController;
use App\Http\Controllers\Api\StatusController;
use App\Http\Controllers\Api\StatusLikeController;
use App\Http\Controllers\Api\UserLookupController;
use App\Http\Controllers\Api\VendorAnalyticsController;
use App\Http\Controllers\Api\VendorController;
use App\Http\Controllers\Api\VendorFollowController;
use App\Http\Controllers\Api\VendorProfileController;
use Illuminate\Support\Facades\Route;

Route::middleware('throttle:auth')->group(function () {
    Route::post('/consumer/register', [ConsumerAuthController::class, 'register']);
    Route::post('/consumer/login', [ConsumerAuthController::class, 'login']);
    Route::post('/vendor/register', [VendorAuthController::class, 'register']);
    Route::post('/vendor/login', [VendorAuthController::class, 'login']);
    // No inspector registration: accounts are created by an admin.
    Route::post('/inspector/login', [InspectorAuthController::class, 'login']);
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [SessionController::class, 'show']);
    Route::get('/features', [FeatureController::class, 'index']);
    Route::post('/logout', [SessionController::class, 'destroy']);

    Route::get('/categories', CategoryController::class);

    // Stalls are never deleted through the API; that is an admin action.
    Route::apiResource('vendors', VendorController::class)->except('destroy');
    Route::patch('/vendors/{vendor}/status', [VendorController::class, 'updateStatus']);
    Route::patch('/vendors/{vendor}/hours', [VendorController::class, 'updateHours']);
    Route::get('/vendors/{vendor}/hygiene', [VendorProfileController::class, 'hygiene']);
    // Owner-only dashboard figures, behind a kill-switch like the other gated endpoints.
    Route::get('/vendors/{vendor}/analytics', VendorAnalyticsController::class)->middleware('feature:vendor.analytics');
    Route::get('/vendors/{vendor}/reviews', [VendorProfileController::class, 'reviews']);
    Route::apiResource('menu-items', MenuController::class);
    Route::get('/map/nearby', [MapController::class, 'nearby']);
    // Consumers read hygiene through GET /vendors/{vendor}/hygiene, so there is
    // no separate hygiene resource. Inspections are submitted here and their
    // audit trail is read per stall; they are never edited or deleted.
    Route::post('/inspections', [InspectorController::class, 'store'])->middleware('feature:inspector.checklist');
    Route::get('/vendors/{vendor}/inspections', [InspectorController::class, 'forVendor']);
    // One review per customer per stall: POST creates it, or updates the existing one.
    Route::post('/vendors/{vendor}/reviews', [ReviewController::class, 'store']);
    Route::get('/vendors/{vendor}/reviews/mine', [ReviewController::class, 'mine']);
    Route::apiResource('reviews', ReviewController::class)->only(['update', 'destroy']);
    Route::post('/reviews/{review}/report', [ReviewReportController::class, 'store'])->middleware('throttle:report');
    Route::apiResource('statuses', StatusController::class)->only(['index', 'show', 'destroy']);
    // Posting is behind a kill-switch; reading, liking, commenting and deleting are not.
    Route::post('/statuses', [StatusController::class, 'store'])->middleware('feature:consumer.daily_status');
    Route::post('/statuses/{status}/comments', [StatusCommentController::class, 'store']);
    Route::post('/statuses/{status}/like', [StatusLikeController::class, 'toggle']);

    Route::post('/vendors/{vendor}/follow', [VendorFollowController::class, 'store']);
    Route::delete('/vendors/{vendor}/follow', [VendorFollowController::class, 'destroy']);

    // Exact-username lookup only, rate limited: no search, so accounts cannot be enumerated.
    Route::get('/users/lookup', UserLookupController::class)->middleware('throttle:lookup');

    Route::get('/friends/requests', [FriendController::class, 'requests']);
    Route::apiResource('friends', FriendController::class)
        ->only(['index', 'destroy'])
        ->parameters(['friends' => 'friendship']);
    // Sending and answering requests are behind a kill-switch; listing and unfriending are not.
    Route::post('/friends', [FriendController::class, 'store'])->middleware('feature:consumer.friends');
    Route::match(['put', 'patch'], '/friends/{friendship}', [FriendController::class, 'update'])->middleware('feature:consumer.friends');
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::patch('/notifications/read-all', [NotificationController::class, 'readAll']);
    Route::patch('/notifications/{notification}/read', [NotificationController::class, 'markRead']);
});
