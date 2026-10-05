<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreInspectorRequest;
use App\Models\InspectorSubmission;
use App\Models\User;
use App\Support\Phone;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class UserManagementController extends Controller
{
    /**
     * Every account, newest first. Search matches name, email, username and
     * phone (a local number like 077... also finds its +94 form); filter by
     * role and by active or suspended.
     */
    public function index(Request $request): View
    {
        $filters = $request->validate([
            'q' => ['nullable', 'string', 'max:100'],
            'role' => ['nullable', Rule::enum(UserRole::class)],
            'status' => ['nullable', Rule::in(['active', 'suspended'])],
        ]);

        $users = User::query()
            ->when($filters['q'] ?? null, function (Builder $query, string $term) {
                $term = trim($term);
                // '!' is the escape character, declared with ESCAPE below. A
                // backslash only works on MySQL: SQLite has no default escape.
                $like = '%'.str_replace(['!', '%', '_'], ['!!', '!%', '!_'], $term).'%';
                $grammar = $query->getQuery()->getGrammar();

                $query->where(function (Builder $match) use ($term, $like, $grammar) {
                    foreach (['name', 'email', 'username', 'phone'] as $column) {
                        $match->orWhereRaw($grammar->wrap($column)." like ? escape '!'", [$like]);
                    }

                    if (preg_match('/^[\d+()\s-]{7,}$/', $term)) {
                        $match->orWhere('phone', Phone::normalize($term));
                    }
                });
            })
            ->when($filters['role'] ?? null, fn (Builder $query, string $role) => $query->where('role', $role))
            ->when($filters['status'] ?? null, fn (Builder $query, string $status) => $query->where('is_active', $status === 'active'))
            ->latest()
            ->orderByDesc('id')
            ->paginate(25)
            ->withQueryString();

        return view('admin.users.index', [
            'users' => $users,
            'filters' => $filters,
            'roles' => UserRole::cases(),
        ]);
    }

    public function show(User $user): View
    {
        $user->load(['vendor', 'inspectorProfile'])->loadCount(['reviews', 'statuses', 'tokens']);

        return view('admin.users.show', [
            'user' => $user,
            'friends' => $user->friendIds()->count(),
            'inspections' => InspectorSubmission::where('inspector_id', $user->id)->count(),
        ]);
    }

    public function create(): View
    {
        Gate::authorize('createInspector', User::class);

        return view('admin.users.create');
    }

    /**
     * Inspector accounts are created here and nowhere else. The administrator
     * sets the first password; there is no self-service password change yet.
     */
    public function store(StoreInspectorRequest $request): RedirectResponse
    {
        $data = $request->validated();

        $inspector = DB::transaction(function () use ($data) {
            $inspector = User::createWithRole(UserRole::Inspector, Arr::only($data, ['name', 'email', 'phone', 'password']));
            $inspector->inspectorProfile()->create(Arr::only($data, ['organization', 'official_id', 'region']));

            return $inspector;
        });

        Log::info('Admin created an inspector account.', ['admin_id' => $request->user()->id, 'user_id' => $inspector->id]);

        return redirect()
            ->route('admin.users.show', $inspector)
            ->with('status', 'Inspector account created. Give them the password you set; they sign in through the inspector login.');
    }

    /**
     * Suspend the account. Its API tokens are deleted by UserObserver in the
     * same instant, so an open session stops working immediately.
     */
    public function deactivate(Request $request, User $user): RedirectResponse
    {
        Gate::authorize('toggleActive', $user);

        if (! $user->is_active) {
            return $this->backTo($user)->with('status', "{$user->name} is already suspended.");
        }

        $user->forceFill(['is_active' => false])->save();

        Log::info('Admin suspended a user.', ['admin_id' => $request->user()->id, 'user_id' => $user->id]);

        return $this->backTo($user)->with('status', "{$user->name} was suspended and their sessions were ended.");
    }

    /**
     * Lift the suspension. Tokens are not restored: the person signs in again.
     */
    public function reactivate(Request $request, User $user): RedirectResponse
    {
        Gate::authorize('toggleActive', $user);

        if ($user->is_active) {
            return $this->backTo($user)->with('status', "{$user->name} is already active.");
        }

        $user->forceFill(['is_active' => true])->save();

        Log::info('Admin reactivated a user.', ['admin_id' => $request->user()->id, 'user_id' => $user->id]);

        return $this->backTo($user)->with('status', "{$user->name} was reactivated. They need to sign in again.");
    }

    private function backTo(User $user): RedirectResponse
    {
        return redirect()->back(fallback: route('admin.users.show', $user));
    }
}
