<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex, nofollow">
    <title>Sign in · StreetBite Admin</title>
    <link rel="stylesheet" href="{{ asset('css/admin.css') }}">
</head>
<body>
    <div class="login-wrap">
        <form class="login-card" method="POST" action="{{ route('admin.login') }}">
            @csrf

            <h1>StreetBite <span style="color: var(--brand)">Admin</span></h1>

            @if (session('status'))
                <div class="flash ok" role="status">{{ session('status') }}</div>
            @endif

            @if ($errors->any())
                <div class="flash error" role="alert">
                    @foreach ($errors->all() as $error)
                        <div>{{ $error }}</div>
                    @endforeach
                </div>
            @endif

            <label for="email">Email</label>
            <input id="email" type="email" name="email" value="{{ old('email') }}" required autofocus autocomplete="username">

            <label for="password">Password</label>
            <input id="password" type="password" name="password" required autocomplete="current-password">

            <button type="submit">Sign in</button>
        </form>
    </div>
</body>
</html>
