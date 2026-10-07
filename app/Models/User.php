<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use App\Enums\UserRole;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Traits\HasRoles;

// role is deliberately not fillable: it is only ever set through createWithRole().
#[Fillable(['name', 'username', 'email', 'phone', 'password', 'bio'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasRoles, Notifiable;

    /**
     * Mirrors the column default, so a freshly created instance is active
     * without being reloaded. Policies read is_active straight off the model.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'is_active' => true,
    ];

    /**
     * Create an account and keep the role column and the Spatie role in sync.
     *
     * @param  array<string, mixed>  $attributes
     */
    public static function createWithRole(UserRole $role, array $attributes): static
    {
        return DB::transaction(function () use ($role, $attributes) {
            $user = new static($attributes);
            $user->role = $role;
            $user->save();
            $user->assignRole(Role::findOrCreate($role->value, 'web'));

            return $user;
        });
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'role' => UserRole::class,
            'is_active' => 'boolean',
            'last_login_at' => 'datetime',
        ];
    }

    public function vendor(): HasOne
    {
        return $this->hasOne(Vendor::class);
    }

    public function inspectorProfile(): HasOne
    {
        return $this->hasOne(InspectorProfile::class);
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class);
    }

    public function statuses(): HasMany
    {
        return $this->hasMany(DailyStatus::class);
    }

    public function appNotifications(): HasMany
    {
        return $this->hasMany(AppNotification::class);
    }

    /**
     * The one definition of "a stall this user follows": an explicit follow. The
     * status feed reads it from here, so changing the rule is a one-place edit.
     */
    public function followedVendors(): BelongsToMany
    {
        return $this->belongsToMany(Vendor::class, 'vendor_follows')->withTimestamps();
    }

    /**
     * Ids of accepted friends, whichever side sent the request.
     *
     * @return \Illuminate\Support\Collection<int, int>
     */
    public function friendIds(): Collection
    {
        return Friendship::query()
            ->accepted()
            ->involving($this)
            ->get(['requester_id', 'addressee_id'])
            ->map(fn (Friendship $friendship) => $friendship->requester_id === $this->id
                ? $friendship->addressee_id
                : $friendship->requester_id)
            ->values();
    }

    public function isFriendsWith(int $userId): bool
    {
        return Friendship::query()
            ->accepted()
            ->where(fn ($pair) => $pair
                ->where(fn ($forward) => $forward->where('requester_id', $this->id)->where('addressee_id', $userId))
                ->orWhere(fn ($reverse) => $reverse->where('requester_id', $userId)->where('addressee_id', $this->id)))
            ->exists();
    }
}
