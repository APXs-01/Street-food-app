<?php

namespace App\Services;

use App\Models\DailyStatus;
use App\Models\InspectorSubmission;
use App\Models\MenuItem;
use App\Models\ReviewPhoto;
use App\Models\Vendor;
use App\Support\Media;
use Illuminate\Support\Facades\DB;

/**
 * Permanently deletes a stall. Only an administrator can do this (vendors
 * cannot delete their own stall).
 *
 * The foreign keys already cascade to menu items, hygiene checklists, inspector
 * submissions, reviews, review photos, category links and followers, so none of
 * those are deleted by hand. Two things the schema cannot do, so this does:
 *
 * - daily_statuses.vendor_id is "set null" on purpose, because customers' statuses
 *   that merely tag the stall must survive. The stall's OWN statuses (posted by its
 *   owner) are deleted explicitly, and their comments and likes cascade from that.
 * - Image files are not touched by database cascades. Their paths are collected
 *   first and removed after the transaction commits, so a failure leaves both the
 *   rows and the files intact.
 *
 * The owner's account is kept; they can set up a new stall.
 */
class VendorDeletion
{
    /**
     * What deleting this stall would remove (and what it would keep), for the
     * confirmation screen and the audit log.
     *
     * @return array<string, int>
     */
    public function impact(Vendor $vendor): array
    {
        return [
            'menu_items' => $vendor->menuItems()->count(),
            'inspections' => $vendor->checklists()->count(),
            'reviews' => $vendor->reviews()->count(),
            'review_photos' => ReviewPhoto::whereHas('review', fn ($review) => $review->where('vendor_id', $vendor->id))->count(),
            'own_statuses' => $this->ownStatuses($vendor)->count(),
            'followers' => $vendor->followers()->count(),
            // Kept, with the tag removed.
            'customer_statuses_kept' => DailyStatus::where('vendor_id', $vendor->id)
                ->where('user_id', '!=', $vendor->user_id)
                ->count(),
        ];
    }

    /**
     * @return array<string, int> the impact, as it was just before deleting
     */
    public function delete(Vendor $vendor): array
    {
        $impact = $this->impact($vendor);
        $files = $this->filePaths($vendor);

        DB::transaction(function () use ($vendor) {
            $this->ownStatuses($vendor)->delete();
            $vendor->delete();
        });

        Media::disk()->delete($files);

        return $impact;
    }

    /**
     * @return \Illuminate\Database\Eloquent\Builder<DailyStatus>
     */
    private function ownStatuses(Vendor $vendor)
    {
        return DailyStatus::where('vendor_id', $vendor->id)->where('user_id', $vendor->user_id);
    }

    /**
     * @return array<int, string>
     */
    private function filePaths(Vendor $vendor): array
    {
        return collect([$vendor->cover_photo_path])
            ->merge(MenuItem::where('vendor_id', $vendor->id)->pluck('photo_path'))
            ->merge(ReviewPhoto::whereHas('review', fn ($review) => $review->where('vendor_id', $vendor->id))->pluck('path'))
            ->merge(InspectorSubmission::whereHas('checklist', fn ($checklist) => $checklist->where('vendor_id', $vendor->id))->pluck('evidence_photo_path'))
            ->merge($this->ownStatuses($vendor)->pluck('media_path'))
            ->filter()
            ->unique()
            ->values()
            ->all();
    }
}
