<?php

use App\Http\Controllers\Admin\AnalyticsController;
use App\Http\Controllers\Admin\Auth\LoginController;
use App\Http\Controllers\Admin\CommunityModerationController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\FeatureFlagController;
use App\Http\Controllers\Admin\HygieneChecklistController;
use App\Http\Controllers\Admin\InspectorSubmissionController;
use App\Http\Controllers\Admin\ReviewModerationController;
use App\Http\Controllers\Admin\UserManagementController;
use App\Http\Controllers\Admin\VendorManagementController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::prefix('admin')->name('admin.')->group(function () {
    Route::middleware('guest')->group(function () {
        Route::get('login', [LoginController::class, 'create'])->name('login');
        Route::post('login', [LoginController::class, 'store'])->middleware('throttle:auth');
    });

    Route::middleware(['auth', 'admin', 'secure.admin'])->group(function () {
        Route::post('logout', [LoginController::class, 'destroy'])->name('logout');

        Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
        Route::post('alerts/read', [DashboardController::class, 'markAlertsRead'])->name('alerts.read');

        Route::resource('users', UserManagementController::class)->only(['index', 'show', 'create', 'store']);
        Route::patch('users/{user}/deactivate', [UserManagementController::class, 'deactivate'])->name('users.deactivate');
        Route::patch('users/{user}/reactivate', [UserManagementController::class, 'reactivate'])->name('users.reactivate');
        Route::resource('vendors', VendorManagementController::class)->only(['index', 'show', 'destroy']);
        // Read-only audit trail: no create, edit or delete.
        Route::resource('inspections', InspectorSubmissionController::class)->only(['index', 'show']);
        Route::resource('reviews', ReviewModerationController::class)->only(['index', 'show', 'destroy']);
        Route::patch('reviews/{review}/hide', [ReviewModerationController::class, 'hide'])->name('reviews.hide');
        Route::patch('reviews/{review}/unhide', [ReviewModerationController::class, 'unhide'])->name('reviews.unhide');
        Route::delete('reviews/{review}/reports', [ReviewModerationController::class, 'dismiss'])->name('reviews.dismiss');

        Route::get('community', [CommunityModerationController::class, 'index'])->name('community.index');
        Route::patch('community/statuses/{status}/hide', [CommunityModerationController::class, 'hideStatus'])->name('community.statuses.hide');
        Route::patch('community/statuses/{status}/unhide', [CommunityModerationController::class, 'unhideStatus'])->name('community.statuses.unhide');
        Route::patch('community/comments/{comment}/hide', [CommunityModerationController::class, 'hideComment'])->name('community.comments.hide');
        Route::patch('community/comments/{comment}/unhide', [CommunityModerationController::class, 'unhideComment'])->name('community.comments.unhide');
        // Read-only board of current hygiene status; per-inspection detail is under inspections.
        Route::resource('hygiene', HygieneChecklistController::class)->only(['index']);
        Route::resource('features', FeatureFlagController::class)->except('show');
        Route::patch('features/{feature}/toggle', [FeatureFlagController::class, 'toggle'])->name('features.toggle');
        Route::get('analytics', [AnalyticsController::class, 'index'])->name('analytics');
    });
});
