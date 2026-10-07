<?php

namespace App\Observers;

use App\Models\User;
use App\Models\Vendor;

class UserObserver
{
    /**
     * When an account is suspended or reactivated:
     *
     * - Suspending deletes every API token it holds, so a session that is
     *   already open cannot keep acting. Reactivating does not bring them
     *   back: the person signs in again.
     * - The star rating of every stall the person reviewed is recalculated,
     *   because a suspended person's reviews stop counting (and count again
     *   once reactivated). The rating is stored on the stall, so it needs this
     *   nudge; everything else hidden by suspension is filtered at query time.
     *
     * This lives on the model, not in one controller, so every path that flips
     * is_active (the admin panel, tinker, a future importer) gets it.
     */
    public function updated(User $user): void
    {
        if (! $user->wasChanged('is_active')) {
            return;
        }

        if (! $user->is_active) {
            $user->tokens()->delete();
        }

        Vendor::whereIn('id', $user->reviews()->pluck('vendor_id'))
            ->get()
            ->each(fn (Vendor $vendor) => $vendor->refreshRatingSnapshot());
    }
}
