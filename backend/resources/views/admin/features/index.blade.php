<x-admin-layout title="Feature flags">
    <div class="page-head">
        <div>
            <h1>Feature flags</h1>
            <p class="lede">
                Switches the mobile app reads from <code>GET /api/features</code>. A change reaches the app the next time it asks.
                Nothing on the server is gated by a flag yet: the app decides what a flag turns on.
            </p>
        </div>
        <a class="btn" href="{{ route('admin.features.create') }}">Add flag</a>
    </div>

    <div class="panel table-wrap">
        <table>
            <thead>
                <tr>
                    <th>Key</th>
                    <th>Label</th>
                    <th>State</th>
                    <th>Changed</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                @forelse ($flags as $flag)
                    <tr>
                        <td><code>{{ $flag->key }}</code></td>
                        <td>
                            {{ $flag->label }}
                            @if ($flag->description) <br><small>{{ $flag->description }}</small> @endif
                        </td>
                        <td>
                            @if ($flag->enabled)
                                <span class="badge ok">On</span>
                            @else
                                <span class="badge">Off</span>
                            @endif
                        </td>
                        <td><small>{{ $flag->updated_at->diffForHumans() }}</small></td>
                        <td class="actions">
                            <form method="POST" action="{{ route('admin.features.toggle', $flag) }}">
                                @csrf
                                @method('PATCH')
                                <button class="secondary" type="submit">Turn {{ $flag->enabled ? 'off' : 'on' }}</button>
                            </form>
                            <a class="btn secondary" href="{{ route('admin.features.edit', $flag) }}">Edit</a>
                            <form method="POST" action="{{ route('admin.features.destroy', $flag) }}"
                                  data-confirm="Delete the flag {{ $flag->key }}? The app will find the key missing, which is not the same as switched off."
                                  onsubmit="return confirm(this.dataset.confirm)">
                                @csrf
                                @method('DELETE')
                                <button class="danger" type="submit">Delete</button>
                            </form>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="empty">No flags yet. Add one when the app needs to switch something.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <h2>What the app receives</h2>
    <pre class="code panel">{{ json_encode(['data' => $payload], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) }}</pre>
    <p class="muted">A key that is not listed has not been defined. That is different from a flag that is off, so the app should decide what an unknown key means.</p>
</x-admin-layout>
