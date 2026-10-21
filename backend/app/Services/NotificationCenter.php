<?php

namespace App\Services;

use App\Enums\NotificationType;
use App\Models\AppNotification;
use App\Models\User;

/**
 * The single place notifications are written, called from the model
 * observers. It owns the rules every notification shares: nobody inactive
 * receives one, and repeat events can be de-duplicated.
 */
class NotificationCenter
{
    /**
     * Notify one person. Returns null when nothing was created: no recipient,
     * an inactive recipient, or (with $uniqueBy) an identical notification
     * already sent.
     *
     * @param  array<string, mixed>  $data
     * @param  array<int, string>  $uniqueBy  keys of $data that, together with the
     *                                        recipient and type, identify a duplicate
     */
    public function notify(
        ?User $recipient,
        NotificationType $type,
        string $title,
        ?string $body = null,
        array $data = [],
        array $uniqueBy = [],
    ): ?AppNotification {
        if ($recipient === null || ! $recipient->is_active) {
            return null;
        }

        if ($uniqueBy !== [] && $this->alreadySent($recipient, $type, $data, $uniqueBy)) {
            return null;
        }

        return AppNotification::create([
            'user_id' => $recipient->id,
            'type' => $type->value,
            'title' => $title,
            'body' => $body,
            'data' => $data,
        ]);
    }

    /**
     * Fan one notification out to many people with bulk inserts. The caller
     * passes only the ids of active recipients.
     *
     * @param  array<int, int>  $userIds
     * @param  array<string, mixed>  $data
     */
    public function notifyMany(array $userIds, NotificationType $type, string $title, ?string $body, array $data): int
    {
        $now = now();
        $payload = json_encode($data);

        foreach (array_chunk($userIds, 500) as $chunk) {
            AppNotification::insert(array_map(fn (int $userId) => [
                'user_id' => $userId,
                'type' => $type->value,
                'title' => $title,
                'body' => $body,
                'data' => $payload,
                'created_at' => $now,
                'updated_at' => $now,
            ], $chunk));
        }

        return count($userIds);
    }

    /**
     * @param  array<string, mixed>  $data
     * @param  array<int, string>  $uniqueBy
     */
    private function alreadySent(User $recipient, NotificationType $type, array $data, array $uniqueBy): bool
    {
        $query = AppNotification::where('user_id', $recipient->id)->where('type', $type->value);

        foreach ($uniqueBy as $key) {
            $query->where("data->{$key}", $data[$key]);
        }

        return $query->exists();
    }
}
