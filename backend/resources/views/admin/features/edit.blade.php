<x-admin-layout :title="'Edit '.$flag->key">
    <div class="page-head">
        <div>
            <h1>Edit flag</h1>
            <p class="lede"><code>{{ $flag->key }}</code></p>
        </div>
    </div>

    <form class="panel form-card" method="POST" action="{{ route('admin.features.update', $flag) }}">
        @csrf
        @method('PUT')

        <label>Key</label>
        <div><code>{{ $flag->key }}</code></div>
        <p class="hint">The key cannot be changed: the app looks the flag up by it. To use a different key, add a new flag and delete this one.</p>

        @include('admin.features._fields', ['flag' => $flag])

        <div class="form-actions">
            <button type="submit">Save</button>
            <a class="btn secondary" href="{{ route('admin.features.index') }}">Cancel</a>
        </div>
    </form>
</x-admin-layout>
