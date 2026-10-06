<?php

namespace App\Observers;

use App\Enums\NotificationType;
use App\Models\StatusComment;
use App\Services\NotificationCenter;
use Illuminate\Support\Str;

class StatusCommentObserver
{
    public function __construct(private NotificationCenter $notifications)
    {
    }

    /**
     * Tell the status owner about a comment, unless they wrote it themselves.
     */
    public function created(StatusComment $comment): void
    {
        $status = $comment->status;

        if ($status->user_id === $comment->user_id) {
            return;
        }

        $author = $comment->user;

        $this->notifications->notify(
            $status->user,
            NotificationType::StatusComment,
            "{$author->name} commented on your status",
            Str::limit($comment->body, 120),
            [
                'status_id' => $status->id,
                'comment_id' => $comment->id,
                'actor_id' => $author->id,
                'actor_name' => $author->name,
            ],
        );
    }
}
