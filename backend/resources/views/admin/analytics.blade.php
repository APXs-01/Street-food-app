<x-admin-layout title="Analytics">
    <div class="page-head">
        <div>
            <h1>Analytics</h1>
            <p class="lede">Platform figures. Each one uses the same definition as the screen it links to.</p>
        </div>
    </div>

    <h2 style="margin-top: 0">People</h2>
    <div class="panel table-wrap">
        <table>
            <thead><tr><th>Accounts</th><th>Total</th><th>Active</th><th>Suspended</th></tr></thead>
            <tbody>
                @foreach ([
                    'customers' => ['Customers', 'consumer'],
                    'vendors' => ['Vendors', 'vendor'],
                    'inspectors' => ['Inspectors', 'inspector'],
                ] as $key => [$label, $role])
                    <tr>
                        <td><a href="{{ route('admin.users.index', ['role' => $role]) }}">{{ $label }}</a></td>
                        <td><strong>{{ number_format($people[$key]['total']) }}</strong></td>
                        <td>{{ number_format($people[$key]['active']) }}</td>
                        <td>
                            @if ($people[$key]['suspended'] > 0)
                                <a href="{{ route('admin.users.index', ['role' => $role, 'status' => 'suspended']) }}">{{ number_format($people[$key]['suspended']) }}</a>
                            @else
                                0
                            @endif
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    <p class="muted">
        Stalls listed: <strong>{{ number_format($stalls['listed']) }}</strong>,
        {{ number_format($stalls['public']) }} visible to the public
        and {{ number_format($stalls['hidden']) }} hidden because their owner is suspended.
        <a href="{{ route('admin.vendors.index') }}">All stalls</a>
    </p>

    <h2>Platform rating</h2>
    <div class="grid">
        <div class="card">
            <div class="label">Average review rating</div>
            @if ($rating['average'] !== null)
                <div class="value">{{ number_format($rating['average'], 1) }}</div>
                <div class="sub">out of 5, from {{ number_format($rating['count']) }} {{ Str::plural('review', $rating['count']) }}</div>
            @else
                <div class="value">&mdash;</div>
                <div class="sub">No reviews yet</div>
            @endif
        </div>
    </div>
    <p class="muted">
        The mean of every review the public can see, so reviews hidden by a moderator or written by a suspended account are left out
        @if ($rating['excluded'] > 0)
            ({{ number_format($rating['excluded']) }} left out).
        @else
            (none are left out at the moment).
        @endif
        With only a few reviews this figure is a small sample, which is why the count sits beside it.
    </p>

    <h2>Re-verification</h2>
    <div class="grid" style="margin-bottom: 16px">
        <a @class(['card', 'attention' => $hygiene['overdue'] > 0]) href="{{ route('admin.hygiene.index', ['state' => 'overdue']) }}">
            <div class="label">Overdue</div>
            <div class="value">{{ number_format($hygiene['overdue']) }}</div>
            <div class="sub">re-verification date has passed</div>
        </a>
        <a class="card" href="{{ route('admin.hygiene.index', ['state' => 'due_soon']) }}">
            <div class="label">Due in the next {{ $hygiene['soon_days'] }} {{ Str::plural('day', $hygiene['soon_days']) }}</div>
            <div class="value">{{ number_format($hygiene['due_soon']) }}</div>
        </a>
        <a class="card" href="{{ route('admin.hygiene.index', ['state' => 'current']) }}">
            <div class="label">Current</div>
            <div class="value">{{ number_format($hygiene['current']) }}</div>
        </a>
        <a class="card" href="{{ route('admin.hygiene.index', ['state' => 'not_inspected']) }}">
            <div class="label">Never inspected</div>
            <div class="value">{{ number_format($hygiene['not_inspected']) }}</div>
        </a>
    </div>

    <div class="panel table-wrap">
        <table>
            <thead><tr><th>Longest overdue</th><th>Owner</th><th>Was due</th><th>Overdue by</th></tr></thead>
            <tbody>
                @forelse ($hygiene['most_overdue'] as $stall)
                    @php $overdueDays = (int) $stall->reverification_due_at->copy()->startOfDay()->diffInDays(now()->startOfDay()); @endphp
                    <tr>
                        <td><a href="{{ route('admin.vendors.show', $stall) }}">{{ $stall->name }}</a></td>
                        <td>{{ $stall->user->name }}</td>
                        <td>{{ $stall->reverification_due_at->format('j M Y') }}</td>
                        <td><span class="badge danger">{{ $overdueDays === 0 ? 'Since today' : $overdueDays.' '.Str::plural('day', $overdueDays) }}</span></td>
                    </tr>
                @empty
                    <tr><td colspan="4" class="empty">Nothing is overdue.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
    @if ($hygiene['overdue'] > count($hygiene['most_overdue']))
        <p class="muted">Showing {{ count($hygiene['most_overdue']) }} of {{ number_format($hygiene['overdue']) }}. <a href="{{ route('admin.hygiene.index', ['state' => 'overdue']) }}">See all overdue stalls</a></p>
    @endif

    <h2>Most reported reviews</h2>
    <div class="panel table-wrap">
        <table>
            <thead><tr><th>Stall</th><th>Author</th><th>Review</th><th>Reports</th><th></th></tr></thead>
            <tbody>
                @forelse ($reported['top'] as $review)
                    <tr>
                        <td><a href="{{ route('admin.vendors.show', $review->vendor) }}">{{ $review->vendor->name }}</a></td>
                        <td>
                            {{ $review->user->name }}
                            @if ($review->is_hidden) <span class="badge danger">Hidden</span> @endif
                            @unless ($review->user->is_active) <span class="badge warn">Suspended</span> @endunless
                        </td>
                        <td class="excerpt"><strong>{{ $review->rating }}/5</strong> @if ($review->comment) &middot; {{ Str::limit($review->comment, 100) }} @endif</td>
                        <td><span class="badge warn">{{ $review->reports_count }}</span></td>
                        <td class="actions"><a class="btn secondary" href="{{ route('admin.reviews.show', $review) }}">Review</a></td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="empty">No review has been reported.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
    @if ($reported['total'] > count($reported['top']))
        <p class="muted">Showing {{ count($reported['top']) }} of {{ number_format($reported['total']) }} reported reviews. <a href="{{ route('admin.reviews.index', ['scope' => 'flagged']) }}">Open the full queue</a></p>
    @endif
</x-admin-layout>
