<x-admin-layout :title="'Review of '.$review->vendor->name">
    <div class="page-head">
        <div>
            <h1>Review of {{ $review->vendor->name }}</h1>
            <p class="lede">
                <strong>{{ $review->rating }}/5</strong>
                @if ($review->is_hidden) <span class="badge danger">Hidden by a moderator</span> @endif
                @unless ($review->user->is_active) <span class="badge warn">Hidden: author is suspended</span> @endunless
                @if (! $review->is_hidden && $review->user->is_active) <span class="badge ok">Public</span> @endif
                @if ($review->reports->isNotEmpty())
                    <span class="badge warn">{{ $review->reports->count() }} {{ Str::plural('report', $review->reports->count()) }}</span>
                @endif
            </p>
        </div>
        <div class="actions">
            <a class="btn secondary" href="{{ route('admin.reviews.index') }}">Back to reviews</a>
        </div>
    </div>

    <div class="two-col">
        <div class="panel">
            <dl class="details">
                <dt>Stall</dt>
                <dd><a href="{{ route('admin.vendors.show', $review->vendor) }}">{{ $review->vendor->name }}</a></dd>

                <dt>Author</dt>
                <dd>
                    <a href="{{ route('admin.users.show', $review->user) }}">{{ $review->user->name }}</a>
                    @if ($review->is_anonymous) <span class="badge">Posted anonymously: the public cannot see this</span> @endif
                    @unless ($review->user->is_active) <span class="badge warn">Suspended</span> @endunless
                </dd>

                <dt>Posted</dt>
                <dd>{{ $review->created_at->format('j M Y, H:i') }}
                    @if ($review->updated_at->gt($review->created_at)) <small>(edited {{ $review->updated_at->diffForHumans() }})</small> @endif
                </dd>

                <dt>What they noticed</dt>
                <dd>
                    @forelse ($review->observations ?? [] as $observation)
                        <span class="badge">{{ Str::headline($observation) }}</span>
                    @empty
                        —
                    @endforelse
                </dd>

                @if ($review->is_hidden)
                    <dt>Hidden because</dt>
                    <dd>{{ $review->hidden_reason ?? 'No reason recorded' }}</dd>
                @endif

                @if ($review->moderated_at)
                    <dt>Last moderated</dt>
                    <dd>{{ $review->moderated_at->format('j M Y, H:i') }} by {{ $review->moderator?->name ?? 'a removed account' }}</dd>
                @endif
            </dl>
        </div>

        <div class="panel panel-pad">
            <h2 style="margin-top: 0">Comment</h2>
            <p class="excerpt" style="max-width: none">{{ $review->comment ?? 'No comment, rating only.' }}</p>

            @if ($review->photos->isNotEmpty())
                <div class="photo-row">
                    @foreach ($review->photos as $photo)
                        <a href="{{ \App\Support\Media::url($photo->path) }}">
                            <img class="thumb" src="{{ \App\Support\Media::url($photo->path) }}" alt="Review photo {{ $loop->iteration }}">
                        </a>
                    @endforeach
                </div>
            @endif
        </div>
    </div>

    <h2>Reports</h2>
    <div class="panel table-wrap">
        <table>
            <thead><tr><th>Reported</th><th>By</th><th>Reason</th><th>Details</th></tr></thead>
            <tbody>
                @forelse ($review->reports->sortByDesc('created_at') as $report)
                    <tr>
                        <td><small>{{ $report->created_at->format('j M Y, H:i') }}</small></td>
                        <td>
                            <a href="{{ route('admin.users.show', $report->reporter) }}">{{ $report->reporter->name }}</a>
                            <br><small>{{ ucfirst($report->reporter->role->label()) }}</small>
                        </td>
                        <td><span class="badge warn">{{ Str::headline($report->reason) }}</span></td>
                        <td class="excerpt">{{ $report->details ?? '—' }}</td>
                    </tr>
                @empty
                    <tr><td colspan="4" class="empty">No reports.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <h2>Actions</h2>
    <div class="panel panel-pad">
        <div class="inline-form" style="gap: 16px; align-items: flex-start">
            @if ($review->is_hidden)
                <form method="POST" action="{{ route('admin.reviews.unhide', $review) }}">
                    @csrf
                    @method('PATCH')
                    <button type="submit">Restore review</button>
                </form>
            @else
                <form class="inline-form" method="POST" action="{{ route('admin.reviews.hide', $review) }}">
                    @csrf
                    @method('PATCH')
                    <input type="text" name="reason" placeholder="Reason (optional)" maxlength="255" aria-label="Reason for hiding">
                    <button class="danger" type="submit">Hide review</button>
                </form>
            @endif

            @if ($review->reports->isNotEmpty())
                <form method="POST" action="{{ route('admin.reviews.dismiss', $review) }}">
                    @csrf
                    @method('DELETE')
                    <button class="secondary" type="submit">Dismiss reports (keep the review)</button>
                </form>
            @endif

            <form method="POST" action="{{ route('admin.reviews.destroy', $review) }}"
                  data-confirm="Permanently delete this review, its photos and its reports? This cannot be undone."
                  onsubmit="return confirm(this.dataset.confirm)">
                @csrf
                @method('DELETE')
                <button class="danger" type="submit">Delete permanently</button>
            </form>
        </div>
        <p class="muted" style="margin-bottom: 0">
            Hiding is reversible: the review stops showing publicly and stops counting towards the stall's star rating.
            Deleting is permanent.
        </p>
    </div>
</x-admin-layout>
