# StreetBite mobile

Flutter app for StreetBite customers and stall owners. The API is the Laravel backend in `../backend`
(see `../backend/docs/API.md`).

## Run

```
flutter pub get
php artisan serve          # in ../backend, listens on http://127.0.0.1:8000
flutter run
```

The API address depends on where the app runs:

| Where | Address used |
|---|---|
| Android emulator | `http://10.0.2.2:8000/api` (the emulator's name for your computer) |
| iOS simulator, desktop, web | `http://localhost:8000/api` |
| A real phone | pass your computer's LAN address, with the phone on the same Wi-Fi |

```
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api
```

Start the backend with `php artisan serve --host=0.0.0.0` for a real phone.

## Tests

```
flutter test
```

Covers the request shapes sent to the API, error handling, the 401 interceptor, token storage,
the auth state and the role-based redirect rules.

## Layout

```
lib/
  core/      api client, design tokens (theme/), secure token storage, router
  features/  auth (data, providers, presentation), consumer/home, vendor/home, vendor/onboarding
```

Every colour, text style, radius and shadow comes from `lib/core/theme/`.
