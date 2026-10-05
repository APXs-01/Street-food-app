<x-admin-layout title="Vendors">
    <div class="page-head">
        <div>
            <h1>Vendors</h1>
            <p class="lede">{{ number_format($vendors->total()) }} {{ Str::plural('stall', $vendors->total()) }}, including any hidden because their owner is suspended</p>
        </div>
    </div>

    <form class="toolbar" method="GET" action="{{ route('admin.vendors.index') }}">
        <input type="text" name="q" value="{{ $filters['q'] ?? '' }}" placeholder="Search stall, code, address or owner" aria-label="Search stalls">

        <select name="hygiene" aria-label="Hygiene">
            <option value="">Any hygiene state</option>
            <option value="not_inspected" @selected(($filters['hygiene'] ?? null) === 'not_inspected')>Not inspected</option>
            <option value="verified" @selected(($filters['hygiene'] ?? null) === 'verified')>Verified</option>
            <option value="overdue" @selected(($filters['hygiene'] ?? null) === 'overdue')>Re-verification overdue</option>
        </select>

        <select name="visibility" aria-label="Visibility">
            <option value="">Public and hidden</option>
            <option value="public" @selected(($filters['visibility'] ?? null) === 'public')>Public</option>
            <option value="hidden" @selected(($filters['visibility'] ?? null) === 'hidden')>Hidden (owner suspended)</option>
        </select>

        <button type="submit">Filter</button>

        @if (array_filter($filters))
            <a class="btn secondary" href="{{ route('admin.vendors.index') }}">Reset</a>
        @endif
    </form>

    <div class="panel table-wrap">
        <table>
            <thead>
                <tr>
                    <th>Stall</th>
                    <th>Owner</th>
                    <th>Hygiene</th>
                    <th>Rating</th>
                    <th>Public</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                @forelse ($vendors as $vendor)
                    <tr>
                        <td>
                            <a href="{{ route('admin.vendors.show', $vendor) }}">{{ $vendor->name }}</a>
                            <br><small>{{ $vendor->stall_code }}@if ($vendor->categories->isNotEmpty()) · {{ $vendor->categories->pluck('name')->join(', ') }}@endif</small>
                        </td>
                        <td>
                            <a href="{{ route('admin.users.show', $vendor->user) }}">{{ $vendor->user->name }}</a>
                            @unless ($vendor->user->is_active)
                                <br><span class="badge warn">Suspended</span>
                            @endunless
                        </td>
                        <td>
                            @switch($vendor->hygiene_status)
                                @case(\App\Enums\HygieneStatus::NotInspected)
                                    <span class="badge">Not inspected</span>
                                    @break
                                @case(\App\Enums\HygieneStatus::ReverificationPending)
                                    <span class="badge warn">{{ $vendor->hygiene_grade->label() }} · re-verify</span>
                                    @break
                                @default
                                    <span class="badge ok">{{ $vendor->hygiene_grade->label() }}</span>
                            @endswitch
                        </td>
                        <td>
                            @if ($vendor->rating_average !== null)
                                {{ number_format($vendor->rating_average, 1) }} <small>({{ $vendor->reviews_count }})</small>
                            @else
                                <small>No reviews</small>
                            @endif
                        </td>
                        <td>
                            @if ($vendor->user->is_active)
                                <span class="badge ok">Visible</span>
                            @else
                                <span class="badge warn">Hidden</span>
                            @endif
                        </td>
                        <td class="actions">
                            <a class="btn secondary" href="{{ route('admin.vendors.show', $vendor) }}">View</a>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="empty">No stalls match.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    {{ $vendors->links('admin.pagination') }}
</x-admin-layout>
