<x-admin-layout title="Community">
    <div class="page-head">
        <div>
            <h1>Community</h1>
            <p class="lede">Moderate daily statuses and their comments. Hiding is reversible and only the author still sees hidden content.</p>
        </div>
    </div>

    <nav class="tabs" aria-label="Community content">
        <a href="{{ route('admin.community.index', ['type' => 'statuses']) }}" @class(['active' => $type === 'statuses'])>Statuses <span class="badge count">{{ $hiddenCounts['statuses'] }} hidden</span></a>
        <a href="{{ route('admin.community.index', ['type' => 'comments']) }}" @class(['active' => $type === 'comments'])>Comments <span class="badge count">{{ $hiddenCounts['comments'] }} hidden</span></a>
    </nav>

    <form class="toolbar" method="GET" action="{{ route('admin.community.index') }}">
        <input type="hidden" name="type" value="{{ $type }}">
        <input type="text" name="q" value="{{ $filters['q'] ?? '' }}" placeholder="{{ $type === 'statuses' ? 'Search caption, location or author' : 'Search comment or author' }}" aria-label="Search">

        <select name="state" aria-label="State">
            <option value="">Visible and hidden</option>
            <option value="visible" @selected(($filters['state'] ?? null) === 'visible')>Visible</option>
            <option value="hidden" @selected(($filters['state'] ?? null) === 'hidden')>Hidden</option>
        </select>

        <button type="submit">Filter</button>

        @if (! empty($filters['q']) || ! empty($filters['state']))
            <a class="btn secondary" href="{{ route('admin.community.index', ['type' => $type]) }}">Reset</a>
        @endif
    </form>

    <div class="panel table-wrap">
        @if ($type === 'statuses')
            <table>
                <thead>
                    <tr><th>Posted</th><th>Author</th><th>Status</th><th>Activity</th><th>State</th><th>Moderate</th></tr>
                </thead>
                <tbody>
                    @forelse ($items as $status)
                        <tr>
                            <td><small>{{ $status->created_at->format('j M Y, H:i') }}</small></td>
                            <td>
                                <a href="{{ route('admin.users.show', $status->user) }}">{{ $status->user->name }}</a>
                                @unless ($status->user->is_active) <br><span class="badge warn">Suspended</span> @endunless
                            </td>
                            <td class="excerpt">
                                @if ($status->media_path)
                                    @if ($status->media_type === \App\Enums\MediaType::Image)
                                        <a href="{{ \App\Support\Media::url($status->media_path) }}"><img class="thumb" src="{{ \App\Support\Media::url($status->media_path) }}" alt="Status photo"></a>
                                    @else
                                        <a href="{{ \App\Support\Media::url($status->media_path) }}">Video</a>
                                    @endif
                                @endif
                                {{ $status->body ?? '' }}
                                <br><small>
                                    {{ ucfirst($status->audience->value) }}
                                    @if ($status->location_label) &middot; {{ $status->location_label }} @endif
                                    @if ($status->vendor) &middot; tags <a href="{{ route('admin.vendors.show', $status->vendor) }}">{{ $status->vendor->name }}</a> @endif
                                </small>
                            </td>
                            <td><small>{{ $status->likes_count }} likes<br>{{ $status->comments_count }} comments</small></td>
                            <td>
                                @if ($status->is_hidden) <span class="badge danger">Hidden</span>
                                    @if ($status->hidden_reason) <br><small>{{ $status->hidden_reason }}</small> @endif
                                @elseif (! $status->isActive()) <span class="badge">Expired</span>
                                @else <span class="badge ok">Live</span>
                                @endif
                            </td>
                            <td>
                                @if ($status->is_hidden)
                                    <form class="inline-form" method="POST" action="{{ route('admin.community.statuses.unhide', $status) }}">
                                        @csrf @method('PATCH')
                                        <button class="secondary" type="submit">Restore</button>
                                    </form>
                                @else
                                    <form class="inline-form" method="POST" action="{{ route('admin.community.statuses.hide', $status) }}">
                                        @csrf @method('PATCH')
                                        <input type="text" name="reason" placeholder="Reason (optional)" maxlength="255" aria-label="Reason for hiding">
                                        <button class="danger" type="submit">Hide</button>
                                    </form>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="6" class="empty">No statuses match.</td></tr>
                    @endforelse
                </tbody>
            </table>
        @else
            <table>
                <thead>
                    <tr><th>Posted</th><th>Author</th><th>Comment</th><th>On status by</th><th>State</th><th>Moderate</th></tr>
                </thead>
                <tbody>
                    @forelse ($items as $comment)
                        <tr>
                            <td><small>{{ $comment->created_at->format('j M Y, H:i') }}</small></td>
                            <td>
                                <a href="{{ route('admin.users.show', $comment->user) }}">{{ $comment->user->name }}</a>
                                @unless ($comment->user->is_active) <br><span class="badge warn">Suspended</span> @endunless
                            </td>
                            <td class="excerpt">{{ $comment->body }}</td>
                            <td>
                                <a href="{{ route('admin.users.show', $comment->status->user) }}">{{ $comment->status->user->name }}</a>
                                <br><small>{{ Str::limit($comment->status->body ?? 'Photo or video', 40) }}</small>
                            </td>
                            <td>
                                @if ($comment->is_hidden) <span class="badge danger">Hidden</span>
                                    @if ($comment->hidden_reason) <br><small>{{ $comment->hidden_reason }}</small> @endif
                                @else <span class="badge ok">Visible</span>
                                @endif
                            </td>
                            <td>
                                @if ($comment->is_hidden)
                                    <form class="inline-form" method="POST" action="{{ route('admin.community.comments.unhide', $comment) }}">
                                        @csrf @method('PATCH')
                                        <button class="secondary" type="submit">Restore</button>
                                    </form>
                                @else
                                    <form class="inline-form" method="POST" action="{{ route('admin.community.comments.hide', $comment) }}">
                                        @csrf @method('PATCH')
                                        <input type="text" name="reason" placeholder="Reason (optional)" maxlength="255" aria-label="Reason for hiding">
                                        <button class="danger" type="submit">Hide</button>
                                    </form>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="6" class="empty">No comments match.</td></tr>
                    @endforelse
                </tbody>
            </table>
        @endif
    </div>

    {{ $items->links('admin.pagination') }}
</x-admin-layout>
