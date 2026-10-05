<x-admin-layout :title="$user->name">
    <div class="page-head">
        <div>
            <h1>{{ $user->name }}</h1>
            <p class="lede">
                <span class="badge">{{ ucfirst($user->role->label()) }}</span>
                @if ($user->is_active)
                    <span class="badge ok">Active</span>
                @else
                    <span class="badge warn">Suspended</span>
                @endif
            </p>
        </div>

        <div class="actions">
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
                        <button type="submit">Reactivate</button>
                    </form>
                @endif
            @endcan
            <a class="btn secondary" href="{{ route('admin.users.index') }}">Back to users</a>
        </div>
    </div>

    <div class="panel">
        <dl class="details">
            <dt>Email</dt>
            <dd>{{ $user->email ?? '—' }}</dd>

            <dt>Phone</dt>
            <dd>{{ $user->phone ?? '—' }}</dd>

            <dt>Username</dt>
            <dd>{{ $user->username ? '@'.$user->username : '—' }}</dd>

            <dt>Bio</dt>
            <dd>{{ $user->bio ?? '—' }}</dd>

            <dt>Joined</dt>
            <dd>{{ $user->created_at->format('j M Y, H:i') }}</dd>

            <dt>Last sign-in</dt>
            <dd>{{ $user->last_login_at?->format('j M Y, H:i') ?? 'Never' }}</dd>

            <dt>Active API sessions</dt>
            <dd>{{ $user->tokens_count }}</dd>

            @if ($user->role === \App\Enums\UserRole::Consumer)
                <dt>Reviews</dt>
                <dd>{{ $user->reviews_count }}</dd>

                <dt>Statuses posted</dt>
                <dd>{{ $user->statuses_count }}</dd>

                <dt>Friends</dt>
                <dd>{{ $friends }}</dd>
            @endif

            @if ($user->role === \App\Enums\UserRole::Vendor)
                <dt>Stall</dt>
                <dd>
                    @if ($user->vendor)
                        <a href="{{ route('admin.vendors.show', $user->vendor) }}">{{ $user->vendor->name }}</a>
                        <small>({{ $user->vendor->stall_code }})</small>
                    @else
                        Not set up yet
                    @endif
                </dd>

                <dt>Statuses posted</dt>
                <dd>{{ $user->statuses_count }}</dd>
            @endif

            @if ($user->role === \App\Enums\UserRole::Inspector)
                <dt>Organisation</dt>
                <dd>{{ $user->inspectorProfile?->organization ?? '—' }}</dd>

                <dt>Official ID</dt>
                <dd>{{ $user->inspectorProfile?->official_id ?? '—' }}</dd>

                <dt>Region</dt>
                <dd>{{ $user->inspectorProfile?->region ?? '—' }}</dd>

                <dt>Inspections submitted</dt>
                <dd>
                    {{ $inspections }}
                    @if ($inspections > 0)
                        <a href="{{ route('admin.inspections.index', ['inspector' => $user->id]) }}">View</a>
                    @endif
                </dd>
            @endif
        </dl>
    </div>
</x-admin-layout>
