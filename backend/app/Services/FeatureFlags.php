<?php

namespace App\Services;

use App\Models\FeatureFlag;
use Illuminate\Support\Facades\Cache;

/**
 * Reads feature flags through the cache. The whole set is one small cached map,
 * rebuilt the first time it is read after any flag is created, changed or
 * deleted (see FeatureFlagObserver), so the app's polling never touches the
 * database.
 */
class FeatureFlags
{
    public const CACHE_KEY = 'feature_flags';

    /**
     * @return array<string, bool> every flag, keyed by its key
     */
    public function all(): array
    {
        return Cache::rememberForever(self::CACHE_KEY, fn () => FeatureFlag::query()
            ->orderBy('key')
            ->pluck('enabled', 'key')
            ->map(fn ($enabled) => (bool) $enabled)
            ->all());
    }

    /**
     * For server-side checks. A key nobody has defined is not a disabled flag:
     * the caller says what an undefined flag means.
     */
    public function isEnabled(string $key, bool $default = false): bool
    {
        return $this->all()[$key] ?? $default;
    }

    public function flush(): void
    {
        Cache::forget(self::CACHE_KEY);
    }
}
