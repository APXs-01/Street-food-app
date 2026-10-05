<?php

namespace App\Providers;

use App\Enums\UserRole;
use App\Models\DailyStatus;
use App\Models\FeatureFlag;
use App\Models\Friendship;
use App\Models\Review;
use App\Models\StatusComment;
use App\Models\StatusLike;
use App\Models\User;
use App\Models\Vendor;
use App\Observers\DailyStatusObserver;
use App\Observers\FeatureFlagObserver;
use App\Observers\FriendshipObserver;
use App\Observers\ReviewObserver;
use App\Observers\StatusCommentObserver;
use App\Observers\StatusLikeObserver;
use App\Observers\UserObserver;
use App\Observers\VendorObserver;
use App\Policies\StatusPolicy;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Foundation\Console\ServeCommand;
use Illuminate\Http\Request;
use Illuminate\Routing\Route as RoutingRoute;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // `php artisan serve` starts the PHP server with only a short list of the
        // environment variables (it strips the rest so .env wins). On Windows that
        // list leaves out TEMP and TMP, so PHP finds no temporary folder and every
        // file upload fails ("unable to create a temporary file"), with a PHP warning
        // printed in front of the JSON reply. Keep the two temp variables.
        if ($this->app->runningInConsole() && class_exists(ServeCommand::class)) {
            ServeCommand::$passthroughVariables = array_values(array_unique([
                ...ServeCommand::$passthroughVariables,
                'TEMP',
                'TMP',
                'TMPDIR',
            ]));
        }

        // Auto-discovery would look for DailyStatusPolicy.
        Gate::policy(DailyStatus::class, StatusPolicy::class);

        // On the public API a stall whose owner is suspended does not exist (404,
        // the same answer as hidden or friends-only content). Resolving it here
        // covers every {vendor} route, current and future. The admin panel
        // (admin/...) still resolves every stall.
        Route::bind('vendor', function (string $value, RoutingRoute $route) {
            $query = Vendor::query();

            if (str_starts_with($route->uri(), 'api/')) {
                $query->visible();
            }

            return $query->findOrFail($value);
        });

        // Notifications are created by observers, not by controllers.
        DailyStatus::observe(DailyStatusObserver::class);
        Friendship::observe(FriendshipObserver::class);
        Review::observe(ReviewObserver::class);
        StatusComment::observe(StatusCommentObserver::class);
        StatusLike::observe(StatusLikeObserver::class);
        Vendor::observe(VendorObserver::class);

        // Any change to a feature flag drops the cached flag map.
        FeatureFlag::observe(FeatureFlagObserver::class);

        // Suspending an account revokes its API tokens.
        User::observe(UserObserver::class);

        // Review reports: stops one account from flooding the moderators.
        RateLimiter::for('report', fn (Request $request) => Limit::perHour(20)->by((string) $request->user()?->id));

        // One gate for every admin-panel moderation action (reviews, statuses, comments).
        Gate::define('moderate-content', fn (User $user) => $user->role === UserRole::SuperAdmin);

        // Feature flags change what the whole app offers.
        Gate::define('manage-features', fn (User $user) => $user->role === UserRole::SuperAdmin);

        // Username lookups: stops a signed-in user from guessing usernames in bulk.
        RateLimiter::for('lookup', fn (Request $request) => Limit::perMinute(30)->by((string) $request->user()?->id));

        // Login and registration attempts, keyed by the submitted identifier and IP.
        RateLimiter::for('auth', function (Request $request) {
            $identifier = Str::lower((string) ($request->input('login') ?? $request->input('email') ?? $request->input('phone')));

            return Limit::perMinute(5)->by($identifier.'|'.$request->ip());
        });
    }
}
