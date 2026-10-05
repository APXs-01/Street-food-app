<x-admin-layout title="Add feature flag">
    <div class="page-head">
        <div>
            <h1>Add feature flag</h1>
            <p class="lede">The key is what the app looks up and cannot be changed later, so choose it with the app team.</p>
        </div>
    </div>

    <form class="panel form-card" method="POST" action="{{ route('admin.features.store') }}">
        @csrf

        <label for="key">Key</label>
        <input id="key" type="text" name="key" value="{{ old('key') }}" required autofocus autocomplete="off" placeholder="vendor.analytics">
        <p class="hint">Lowercase letters, digits and underscores, starting with a letter. Group with a dot, for example <code>consumer.friends</code>.</p>

        @include('admin.features._fields', ['flag' => null])

        <div class="form-actions">
            <button type="submit">Create flag</button>
            <a class="btn secondary" href="{{ route('admin.features.index') }}">Cancel</a>
        </div>
    </form>
</x-admin-layout>
