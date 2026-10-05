<x-admin-layout title="Add inspector">
    <div class="page-head">
        <div>
            <h1>Add inspector</h1>
            <p class="lede">Inspector accounts are created here only. You set the first password and pass it on.</p>
        </div>
    </div>

    <form class="panel form-card" method="POST" action="{{ route('admin.users.store') }}">
        @csrf

        <div class="form-grid">
            <div>
                <label for="name">Full name</label>
                <input id="name" type="text" name="name" value="{{ old('name') }}" required autofocus>
            </div>

            <div>
                <label for="email">Email</label>
                <input id="email" type="email" name="email" value="{{ old('email') }}" required autocomplete="off">
            </div>

            <div>
                <label for="phone">Mobile (optional)</label>
                <input id="phone" type="text" name="phone" value="{{ old('phone') }}" placeholder="077 123 4567">
            </div>

            <div>
                <label for="organization">Organisation</label>
                <input id="organization" type="text" name="organization" value="{{ old('organization') }}" required placeholder="Colombo Municipal Health Council">
            </div>

            <div>
                <label for="official_id">Official ID</label>
                <input id="official_id" type="text" name="official_id" value="{{ old('official_id') }}" required>
                <p class="hint">Badge or registration number. Must be unique.</p>
            </div>

            <div>
                <label for="region">Region (optional)</label>
                <input id="region" type="text" name="region" value="{{ old('region') }}">
            </div>

            <div>
                <label for="password">Password</label>
                <input id="password" type="password" name="password" required autocomplete="new-password">
                <p class="hint">At least 8 characters.</p>
            </div>

            <div>
                <label for="password_confirmation">Confirm password</label>
                <input id="password_confirmation" type="password" name="password_confirmation" required autocomplete="new-password">
            </div>
        </div>

        <div class="form-actions">
            <button type="submit">Create inspector</button>
            <a class="btn secondary" href="{{ route('admin.users.index') }}">Cancel</a>
        </div>
    </form>
</x-admin-layout>
