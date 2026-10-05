<x-admin-layout title="Reviews">
    <div class="page-head">
        <div>
            <h1>Reviews</h1>
            <p class="lede">Moderate reviews. The reported queue comes first, most reported on top. You see every review, including hidden ones and the real author of anonymous ones.</p>
        </div>
    </div>

    <nav class="tabs" aria-label="Review lists">
        <a href="{{ route('admin.reviews.index', ['scope' => 'flagged']) }}" @class(['active' => $scope === 'flagged'])>Reported <span class="badge {{ $counts['flagged'] > 0 ? 'warn' : '' }} count">{{ $counts['flagged'] }}</span></a>
        <a href="{{ route('admin.reviews.index', ['scope' => 'hidden']) }}" @class(['active' => $scope === 'hidden'])>Hidden <span class="badge count">{{ $counts['hidden'] }}</span></a>
        <a href="{{ route('admin.reviews.index', ['scope' => 'all']) }}" @class(['active' => $scope === 'all'])>All <span class="badge count">{{ $counts['all'] }}</span></a>
    </nav>

    <form class="toolbar" method="GET" action="{{ route('admin.reviews.index') }}">
        <input type="hidden" name="scope" value="{{ $scope }}">
        <input type="text" name="q" value="{{ $filters['q'] ?? '' }}" placeholder="Search comment, author or stall" aria-label="Search reviews">

        <select name="rating" aria-label="Rating">
            <option value="">Any rating</option>
            @foreach ([5, 4, 3, 2, 1] as $stars)
                <option value="{{ $stars }}" @selected((int) ($filters['rating'] ?? 0) === $stars)>{{ $stars }} {{ Str::plural('star', $stars) }}</option>
            @endforeach
        </select>

        <button type="submit">Filter</button>

        @if (! empty($filters['q']) || ! empty($filters['rating']))
            <a class="btn secondary" href="{{ route('admin.reviews.index', ['scope' => $scope]) }}">Reset</a>
        @endif
    </form>

    <div class="panel table-wrap">
        <table>
            <thead>
                <tr>
                    <th>Posted</th>
                    <th>Stall</th>
                    <th>Author</th>
                    <th>Review</th>
                    <th>Reports</th>
                    <th>State</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                @forelse ($reviews as $review)
                    <tr>
                        <td><small>{{ $review->created_at->format('j M Y') }}</small></td>
                        <td><a href="{{ route('admin.vendors.show', $review->vendor) }}">{{ $review->vendor->name }}</a></td>
                        <td>
                            <a href="{{ route('admin.users.show', $review->user) }}">{{ $review->user->name }}</a>
                            @if ($review->is_anonymous) <br><span class="badge">Posted anonymously</span> @endif
                        </td>
                        <td class="excerpt">
                            <strong>{{ $review->rating }}/5</strong>
                            @if ($review->comment) &middot; {{ Str::limit($review->comment, 120) }} @endif
                            @if ($review->photos_count > 0) <br><small>{{ $review->photos_count }} {{ Str::plural('photo', $review->photos_count) }}</small> @endif
                        </td>
                        <td>
                            @if ($review->reports_count > 0)
                                <span class="badge warn">{{ $review->reports_count }} {{ Str::plural('report', $review->reports_count) }}</span>
                            @else
                                <small>None</small>
                            @endif
                        </td>
                        <td>
                            @if ($review->is_hidden) <span class="badge danger">Hidden</span> @endif
                            @unless ($review->user->is_active) <span class="badge warn">Author suspended</span> @endunless
                            @if (! $review->is_hidden && $review->user->is_active) <span class="badge ok">Public</span> @endif
                        </td>
                        <td class="actions"><a class="btn secondary" href="{{ route('admin.reviews.show', $review) }}">Review</a></td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="7" class="empty">
                            @if ($scope === 'flagged' && empty($filters['q']) && empty($filters['rating']))
                                Nothing has been reported. Nice.
                            @else
                                No reviews match.
                            @endif
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    {{ $reviews->links('admin.pagination') }}
</x-admin-layout>
