<?php

namespace App\Console\Commands;

use App\Models\DailyStatus;
use App\Support\Media;
use Illuminate\Console\Command;

class PurgeOldStatuses extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'statuses:purge-old';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Permanently delete statuses (and their media) older than the retention window';

    /**
     * Storage hygiene only. A status stops showing to others after 24 hours
     * but stays available to its author until it is older than the retention
     * window (7 days). Comments and likes go with it.
     */
    public function handle(): int
    {
        $cutoff = now()->subDays(config('streetbite.status_retention_days'));
        $purged = 0;

        DailyStatus::where('created_at', '<', $cutoff)->chunkById(200, function ($statuses) use (&$purged) {
            $paths = $statuses->pluck('media_path')->filter()->all();

            if ($paths !== []) {
                Media::disk()->delete($paths);
            }

            $purged += DailyStatus::whereIn('id', $statuses->modelKeys())->delete();
        });

        $this->info("{$purged} status(es) purged.");

        return self::SUCCESS;
    }
}
