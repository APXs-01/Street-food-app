<x-admin-layout title="Dashboard">
    <h1>Dashboard</h1>
    <p class="lede">A snapshot of the platform. Deeper figures are on the Analytics page.</p>

    <div class="grid">
        <a class="card" href="{{ route('admin.users.index', ['role' => 'consumer']) }}">
            <div class="label">Customers</div>
            <div class="value">{{ number_format($stats['customers']) }}</div>
        </a>
        <a class="card" href="{{ route('admin.users.index', ['role' => 'vendor']) }}">
            <div class="label">Vendor accounts</div>
            <div class="value">{{ number_format($stats['vendor_accounts']) }}</div>
        </a>
        <a class="card" href="{{ route('admin.users.index', ['role' => 'inspector']) }}">
            <div class="label">Inspectors</div>
            <div class="value">{{ number_format($stats['inspectors']) }}</div>
        </a>
        <a @class(['card', 'attention' => $stats['suspended'] > 0]) href="{{ route('admin.users.index', ['status' => 'suspended']) }}">
            <div class="label">Suspended accounts</div>
            <div class="value">{{ number_format($stats['suspended']) }}</div>
        </a>

        <a class="card" href="{{ route('admin.vendors.index') }}">
            <div class="label">Stalls listed</div>
            <div class="value">{{ number_format($stats['stalls']) }}</div>
            <div class="sub">{{ number_format($stats['not_inspected']) }} not yet inspected</div>
        </a>
        <a @class(['card', 'attention' => $stats['overdue'] > 0]) href="{{ route('admin.hygiene.index', ['state' => 'overdue']) }}">
            <div class="label">Re-verification overdue</div>
            <div class="value">{{ number_format($stats['overdue']) }}</div>
            <div class="sub">stalls past their due date</div>
        </a>
        <a class="card" href="{{ route('admin.inspections.index') }}">
            <div class="label">Inspections</div>
            <div class="value">{{ number_format($stats['inspections']) }}</div>
        </a>

        <a class="card" href="{{ route('admin.reviews.index') }}">
            <div class="label">Reviews</div>
            <div class="value">{{ number_format($stats['reviews']) }}</div>
            <div class="sub">{{ number_format($stats['hidden_reviews']) }} hidden</div>
        </a>
        <a @class(['card', 'attention' => $stats['reported_reviews'] > 0]) href="{{ route('admin.reviews.index', ['scope' => 'flagged']) }}">
            <div class="label">Reported reviews</div>
            <div class="value">{{ number_format($stats['reported_reviews']) }}</div>
            <div class="sub">waiting for a moderator</div>
        </a>
        <a class="card" href="{{ route('admin.community.index') }}">
            <div class="label">Active statuses</div>
            <div class="value">{{ number_format($stats['active_statuses']) }}</div>
            <div class="sub">posted in the last 24 hours</div>
        </a>
    </div>

    <h2>Re-verification alerts</h2>
    <div class="panel">
        @forelse ($alerts as $alert)
            <div class="alert-item">
                <strong>{{ $alert->title }}</strong>
                {{ $alert->body }}
                <small>· {{ $alert->created_at->diffForHumans() }}</small>
                @if (isset($alert->data['vendor_id']) && $existingStalls->contains($alert->data['vendor_id']))
                    <a href="{{ route('admin.vendors.show', $alert->data['vendor_id']) }}">View stall</a>
                @endif
            </div>
        @empty
            <div class="empty">No unread alerts.</div>
        @endforelse
    </div>

    @if ($unreadAlerts > 0)
        <form method="POST" action="{{ route('admin.alerts.read') }}" style="margin-top: 12px">
            @csrf
            <button class="secondary" type="submit">Mark all {{ $unreadAlerts }} as read</button>
        </form>
    @endif
</x-admin-layout>
