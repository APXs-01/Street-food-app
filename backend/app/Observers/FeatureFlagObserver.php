<?php

namespace App\Observers;

use App\Models\FeatureFlag;
use App\Services\FeatureFlags;

class FeatureFlagObserver
{
    public function __construct(private FeatureFlags $flags)
    {
    }

    /**
     * Any change to any flag drops the cached map, so the next read (the app's
     * next poll) sees it. Lives on the model so every path that changes a flag
     * gets it.
     */
    public function saved(FeatureFlag $flag): void
    {
        $this->flags->flush();
    }

    public function deleted(FeatureFlag $flag): void
    {
        $this->flags->flush();
    }
}
