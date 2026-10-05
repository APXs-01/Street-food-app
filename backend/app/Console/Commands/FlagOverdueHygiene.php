<?php

namespace App\Console\Commands;

use App\Enums\NotificationType;
use App\Enums\UserRole;
use App\Models\AppNotification;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Console\Command;

class FlagOverdueHygiene extends Command
{
    public const NOTIFICATION_TYPE = NotificationType::HygieneOverdue->value;

    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'hygiene:flag-overdue';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Notify administrators about stalls whose hygiene re-verification is overdue';

    public function handle(): int
    {
        $adminIds = User::where('role', UserRole::SuperAdmin)
            ->where('is_active', true)
            ->pluck('id');

        if ($adminIds->isEmpty()) {
            $this->warn('No active administrators to notify.');

            return self::SUCCESS;
        }

        // One notification per admin, stall and overdue episode: the due date
        // changes after each inspection, so a new lapse notifies again.
        $alreadySent = AppNotification::where('type', self::NOTIFICATION_TYPE)
            ->whereIn('user_id', $adminIds)
            ->get(['user_id', 'data'])
            ->mapWithKeys(fn (AppNotification $notification) => [
                $this->key($notification->user_id, $notification->data['vendor_id'] ?? 0, $notification->data['due_at'] ?? '') => true,
            ]);

        $overdue = 0;
        $created = 0;

        Vendor::query()
            ->hygieneOverdue()
            ->each(function (Vendor $vendor) use ($adminIds, $alreadySent, &$overdue, &$created) {
                $overdue++;
                $dueAt = $vendor->reverification_due_at;

                foreach ($adminIds as $adminId) {
                    if ($alreadySent->has($this->key($adminId, $vendor->id, $dueAt->toIso8601String()))) {
                        continue;
                    }

                    AppNotification::create([
                        'user_id' => $adminId,
                        'type' => self::NOTIFICATION_TYPE,
                        'title' => "Re-verification overdue: {$vendor->name}",
                        'body' => sprintf(
                            'Last inspected on %s. Re-verification was due on %s (%d days ago).',
                            $vendor->last_inspected_at->toDateString(),
                            $dueAt->toDateString(),
                            (int) $dueAt->diffInDays(now()),
                        ),
                        'data' => [
                            'vendor_id' => $vendor->id,
                            'due_at' => $dueAt->toIso8601String(),
                            'last_inspected_at' => $vendor->last_inspected_at->toIso8601String(),
                        ],
                    ]);

                    $created++;
                }
            });

        $this->info("{$overdue} overdue stall(s); {$created} notification(s) created.");

        return self::SUCCESS;
    }

    private function key(int $userId, int $vendorId, string $dueAt): string
    {
        return "{$userId}|{$vendorId}|{$dueAt}";
    }
}
