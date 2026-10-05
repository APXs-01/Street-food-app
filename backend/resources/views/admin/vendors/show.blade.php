<x-admin-layout :title="$vendor->name">
    <div class="page-head">
        <div>
            <h1>{{ $vendor->name }}</h1>
            <p class="lede">
                <span class="badge">{{ $vendor->stall_code }}</span>
                @if ($vendor->user->is_active)
                    <span class="badge ok">Visible to the public</span>
                @else
                    <span class="badge warn">Hidden: owner is suspended</span>
                @endif
            </p>
        </div>
        <div class="actions">
            <a class="btn secondary" href="{{ route('admin.vendors.index') }}">Back to vendors</a>
        </div>
    </div>

    @unless ($vendor->user->is_active)
        <div class="notice">
            This stall is hidden from the map, search and the public app because
            <a href="{{ route('admin.users.show', $vendor->user) }}">{{ $vendor->user->name }}</a>
            is suspended. Reactivating the owner brings it back.
        </div>
    @endunless

    <div class="two-col">
        <div class="panel">
            <dl class="details">
                <dt>Owner</dt>
                <dd><a href="{{ route('admin.users.show', $vendor->user) }}">{{ $vendor->user->name }}</a></dd>

                <dt>Categories</dt>
                <dd>{{ $vendor->categories->pluck('name')->join(', ') ?: '—' }}</dd>

                <dt>Description</dt>
                <dd>{{ $vendor->description ?? '—' }}</dd>

                <dt>Address</dt>
                <dd>{{ $vendor->address ?? '—' }}@if ($vendor->landmark) <small>· near {{ $vendor->landmark }}</small>@endif</dd>

                <dt>Location</dt>
                <dd>{{ $vendor->latitude }}, {{ $vendor->longitude }}</dd>

                <dt>Hours</dt>
                <dd>{{ substr($vendor->opens_at, 0, 5) }} to {{ substr($vendor->closes_at, 0, 5) }}</dd>

                <dt>Right now</dt>
                <dd>
                    @if ($vendor->isOpenNow())
                        <span class="badge ok">Open</span>
                    @else
                        <span class="badge">Closed</span>
                    @endif
                </dd>

                <dt>Followers</dt>
                <dd>{{ $vendor->followers_count }}</dd>

                <dt>Listed</dt>
                <dd>{{ $vendor->created_at->format('j M Y') }}</dd>
            </dl>
        </div>

        <div>
            @if ($vendor->cover_photo_path)
                <img class="cover" src="{{ \App\Support\Media::url($vendor->cover_photo_path) }}" alt="Cover photo of {{ $vendor->name }}">
            @endif
        </div>
    </div>

    <h2>Hygiene and rating</h2>
    <div class="panel">
        <dl class="details">
            <dt>Status</dt>
            <dd>
                @switch($vendor->hygiene_status)
                    @case(\App\Enums\HygieneStatus::NotInspected)
                        <span class="badge">Not inspected</span>
                        @break
                    @case(\App\Enums\HygieneStatus::ReverificationPending)
                        <span class="badge warn">Re-verification pending</span>
                        @break
                    @default
                        <span class="badge ok">Verified</span>
                @endswitch
            </dd>

            @if ($vendor->hygiene_grade)
                <dt>Grade</dt>
                <dd>{{ $vendor->hygiene_grade->label() }} ({{ number_format($vendor->hygiene_score, 1) }} out of 5)</dd>

                <dt>Safe water source</dt>
                <dd>{{ $vendor->water_source_verified ? 'Verified' : 'Not verified' }}</dd>

                <dt>Last inspected</dt>
                <dd>{{ $vendor->last_inspected_at->format('j M Y') }}</dd>

                <dt>Re-verification due</dt>
                <dd>{{ $vendor->reverification_due_at->format('j M Y') }}</dd>
            @endif

            <dt>Star rating</dt>
            <dd>
                @if ($vendor->rating_average !== null)
                    {{ number_format($vendor->rating_average, 1) }} from {{ $vendor->reviews_count }} {{ Str::plural('review', $vendor->reviews_count) }}
                @else
                    No reviews yet
                @endif
                @if ($hiddenReviews > 0)
                    <small>· {{ $hiddenReviews }} hidden by moderators</small>
                @endif
            </dd>
        </dl>
    </div>

    <h2>Recent inspections <small><a href="{{ route('admin.inspections.index', ['vendor' => $vendor->id]) }}">View all</a></small></h2>
    <div class="panel table-wrap">
        <table>
            <thead><tr><th>Date</th><th>Grade</th><th>Inspector</th><th>Organisation</th></tr></thead>
            <tbody>
                @forelse ($inspections as $inspection)
                    <tr>
                        <td>{{ $inspection->checklist->inspected_at->format('j M Y') }}</td>
                        <td>{{ $inspection->checklist->grade->label() }} <small>({{ number_format($inspection->checklist->score, 1) }})</small></td>
                        <td>{{ $inspection->inspector->name }}</td>
                        <td>{{ $inspection->organization ?? '—' }}</td>
                    </tr>
                @empty
                    <tr><td colspan="4" class="empty">Not inspected yet.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <h2>Menu</h2>
    <div class="panel">
        @if ($menu->isNotEmpty())
            <ul class="plain panel-pad">
                @foreach ($menu as $item)
                    <li>
                        <strong>{{ $item->name }}</strong> · {{ number_format($item->price, 2) }}
                        @unless ($item->is_available) <span class="badge warn">Sold out</span> @endunless
                        @if ($item->is_fresh_today) <span class="badge ok">Fresh today</span> @endif
                    </li>
                @endforeach
            </ul>
        @else
            <div class="empty">No menu items.</div>
        @endif
    </div>

    <h2>Delete this stall</h2>
    <form class="panel panel-pad danger-zone" method="POST" action="{{ route('admin.vendors.destroy', $vendor) }}">
        @csrf
        @method('DELETE')

        <p>
            This is permanent and cannot be undone. To hide a stall while keeping its history,
            <strong>suspend its owner</strong> instead.
        </p>

        <p class="muted">Deleting the stall also deletes:</p>
        <ul>
            <li>{{ $impact['menu_items'] }} menu {{ Str::plural('item', $impact['menu_items']) }}</li>
            <li>{{ $impact['inspections'] }} {{ Str::plural('inspection', $impact['inspections']) }}, including the inspectors' evidence photos (the audit record for this stall)</li>
            <li>{{ $impact['reviews'] }} {{ Str::plural('review', $impact['reviews']) }} and {{ $impact['review_photos'] }} review {{ Str::plural('photo', $impact['review_photos']) }}</li>
            <li>{{ $impact['own_statuses'] }} {{ Str::plural('status', $impact['own_statuses']) }} posted by the stall, with their comments and likes</li>
            <li>{{ $impact['followers'] }} {{ Str::plural('follower', $impact['followers']) }} (the follows, not the people)</li>
        </ul>
        <p class="muted">
            Kept: the owner's account, and {{ $impact['customer_statuses_kept'] }} customer
            {{ Str::plural('status', $impact['customer_statuses_kept']) }} that only tagged this stall (the tag is removed).
        </p>

        <div class="form-grid">
            <div>
                <label for="confirm_name">Type the stall name to confirm</label>
                <input id="confirm_name" type="text" name="confirm_name" autocomplete="off" required placeholder="{{ $vendor->name }}">
            </div>
        </div>

        <div class="form-actions">
            <button class="danger" type="submit">Delete stall permanently</button>
        </div>
    </form>
</x-admin-layout>
