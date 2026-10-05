<x-admin-layout title="Users">
    <div class="page-head">
        <div>
            <h1>Users</h1>
            <p class="lede">{{ number_format($users->total()) }} {{ Str::plural('account', $users->total()) }}</p>
        </div>
        <a class="btn" href="{{ route('admin.users.create') }}">Add inspector</a>
    </div>

    <form class="toolbar" method="GET" action="{{ route('admin.users.index') }}">
        <input type="text" name="q" value="{{ $filters['q'] ?? '' }}" placeholder="Search name, email, username or phone" aria-label="Search users">

        <select name="role" aria-label="Role">
            <option value="">All roles</option>
            @foreach ($roles as $role)
                <option value="{{ $role->value }}" @selected(($filters['role'] ?? null) === $role->value)>{{ ucfirst($role->label()) }}</option>
            @endforeach
        </select>

        <select name="status" aria-label="Status">
            <option value="">Any status</option>
            <option value="active" @selected(($filters['status'] ?? null) === 'active')>Active</option>
            <option value="suspended" @selected(($filters['status'] ?? null) === 'suspended')>Suspended</option>
        </select>

        <button type="submit">Filter</button>

        @if (array_filter($filters))
            <a class="btn secondary" href="{{ route('admin.users.index') }}">Reset</a>
        @endif
    </form>

    <div class="panel table-wrap">
        <table>
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Contact</th>
                    <th>Role</th>
                    <th>Status</th>
                    <th>Last sign-in</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                @forelse ($users as $user)
                    <tr>
                        <td>
                            <a href="{{ route('admin.users.show', $user) }}">{{ $user->name }}</a>
                            @if ($user->username)
                                <br><small>&#64;{{ $user->username }}</small>
                            @endif
                        </td>
                        <td>
                            {{ $user->email }}
                            @if ($user->phone)
                                <br><small>{{ $user->phone }}</small>
                            @endif
                        </td>
                        <td><span class="badge">{{ ucfirst($user->role->label()) }}</span></td>
                        <td>
                            @if ($user->is_active)
                                <span class="badge ok">Active</span>
                            @else
                                <span class="badge warn">Suspended</span>
                            @endif
                        </td>
                        <td><small>{{ $user->last_login_at?->diffForHumans() ?? 'Never' }}</small></td>
                        <td class="actions">
                            @can('toggleActive', $user)
                                @if ($user->is_active)
                                    <form method="POST" action="{{ route('admin.users.deactivate', $user) }}"
                                          data-confirm="Suspend {{ $user->name }}? Their sessions end immediately."
                                          onsubmit="return confirm(this.dataset.confirm)">
                                        @csrf
                                        @method('PATCH')
                                        <button class="danger" type="submit">Suspend</button>
                                    </form>
                                @else
                                    <form method="POST" action="{{ route('admin.users.reactivate', $user) }}">
                                        @csrf
                                        @method('PATCH')
                                        <button class="secondary" type="submit">Reactivate</button>
                                    </form>
                                @endif
                            @endcan
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="empty">No users match.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    {{ $users->links('admin.pagination') }}
</x-admin-layout>
