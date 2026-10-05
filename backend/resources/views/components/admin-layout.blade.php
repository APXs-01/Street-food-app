@props(['title' => 'Admin'])

@php
    $links = [
        'Dashboard' => ['route' => 'admin.dashboard', 'active' => 'admin.dashboard'],
        'Users' => ['route' => 'admin.users.index', 'active' => 'admin.users.*'],
        'Vendors' => ['route' => 'admin.vendors.index', 'active' => 'admin.vendors.*'],
        'Inspections' => ['route' => 'admin.inspections.index', 'active' => 'admin.inspections.*'],
        'Reviews' => ['route' => 'admin.reviews.index', 'active' => 'admin.reviews.*'],
        'Community' => ['route' => 'admin.community.index', 'active' => 'admin.community.*'],
        'Hygiene' => ['route' => 'admin.hygiene.index', 'active' => 'admin.hygiene.*'],
        'Features' => ['route' => 'admin.features.index', 'active' => 'admin.features.*'],
        'Analytics' => ['route' => 'admin.analytics', 'active' => 'admin.analytics'],
    ];
@endphp
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex, nofollow">
    <title>{{ $title }} · StreetBite Admin</title>
    <link rel="stylesheet" href="{{ asset('css/admin.css') }}">
</head>
<body>
    <header class="topbar">
        <a class="brand" href="{{ route('admin.dashboard') }}">StreetBite <span>Admin</span></a>

        <nav class="nav" aria-label="Admin sections">
            @foreach ($links as $label => $link)
                <a href="{{ route($link['route']) }}" @class(['active' => request()->routeIs($link['active'])])>{{ $label }}</a>
            @endforeach
        </nav>

        <form class="signout" method="POST" action="{{ route('admin.logout') }}">
            @csrf
            <button class="link" type="submit">Sign out ({{ auth()->user()->name }})</button>
        </form>
    </header>

    <main>
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

        {{ $slot }}
    </main>
</body>
</html>
