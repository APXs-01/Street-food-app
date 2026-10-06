<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\Review;
use App\Models\User;
use Illuminate\Auth\Access\Response;

class ReviewPolicy
{
    /**
     * Only active customer accounts review stalls.
     */
    public function create(User $user): bool
    {
        return $user->role === UserRole::Consumer && $user->is_active;
    }

    /**
     * A review is public content, so someone else's visible review answers 403.
     * One the public cannot see (hidden by a moderator, or by a suspended
     * author) answers 404, so its existence is not revealed.
     */
    public function update(User $user, Review $review): Response|bool
    {
        if ($review->user_id !== $user->id) {
            $visible = Review::visible()->whereKey($review->getKey())->exists();

            return $visible ? Response::deny() : Response::denyAsNotFound();
        }

        return $user->is_active;
    }

    public function delete(User $user, Review $review): Response|bool
    {
        return $this->update($user, $review);
    }

    /**
     * Customers and vendors (a stall owner disputing a review of their stall)
     * can report a review. Nobody reports their own.
     */
    public function report(User $user, Review $review): bool
    {
        return $user->is_active
            && in_array($user->role, [UserRole::Consumer, UserRole::Vendor], true)
            && $review->user_id !== $user->id;
    }
}
