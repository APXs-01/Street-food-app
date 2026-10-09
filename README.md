# StreetBite — Street-Food Vendor Locator with Hygiene Ratings

[![Flutter](https://img.shields.io/badge/Flutter-Mobile_App-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Laravel](https://img.shields.io/badge/Laravel-Backend_API-FF2D20?logo=laravel&logoColor=white)](https://laravel.com/)
[![MySQL](https://img.shields.io/badge/MySQL-Database-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Docker](https://img.shields.io/badge/Docker-Backend_Image-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Figma](https://img.shields.io/badge/Figma-UI%2FUX_Design-F24E1E?logo=figma&logoColor=white)](https://www.figma.com/)

A mobile app that helps customers discover nearby street-food vendors with inspection-backed hygiene ratings, and gives vendors a simple way to build trust and grow their customer base, without needing complex technology.

Built as part of **IT3060 — Human Computer Interaction**, SLIIT (3rd Year, 2nd Semester), Group **WD_07**.

---

## 📱 Overview

Street food is a daily reality for many people, but there is no reliable way to check a stall's hygiene before buying, and clean, hardworking vendors have no way to prove it. **StreetBite** combines:

- **Hygiene ratings backed by a 5-point inspection checklist** (water source, utensil and glove hygiene, waste disposal, food covering, overall cleanliness), with each criterion scored Pass, Partial or Fail.
- **Dated photo evidence in customer reviews.** The server checks that a photo is recent, stores its capture time, resizes it and removes its EXIF data.
- **Nearby-stall discovery**, filterable by distance, hygiene, category and open-now status.
- **A simple vendor dashboard** in English or Sinhala, for busy vendors with limited smartphone experience.
- **An inspector submission flow**, so ratings are grounded in structured evaluation rather than self-reported claims.
- **An administrator web panel** for moderation, inspector accounts and platform oversight.

---

## ✨ Core Features

| Feature | Requirement | Description |
|---|---|---|
| Nearby discovery | FR-05 | Search and filter stalls by distance, hygiene grade, category and open-now. The server calculates distance with a bounding box and the Haversine formula. |
| Open/closed status and hours | FR-09 | Vendors set status and operating hours; customers see them on the map and in lists. |
| Hygiene rating and breakdown | FR-01, FR-10, FR-11 | Overall grade plus a five-criterion breakdown, including the water-source result. |
| Inspection-verified status | FR-03 | Status comes from submitted inspections and is distinct from customer ratings. |
| Daily menu | FR-08 | Vendors add, edit and delete menu items. |
| Photo and review submission | FR-02, FR-07 | Customers submit star ratings, hygiene observations, written reviews and photos. Reviews can be edited, deleted and reported. |
| Photo evidence checks | NFR-04, NFR-05 | Server-side freshness check, stored capture time, resizing and EXIF stripping. |
| Sinhala support | FR-04, NFR-02 | English and Sinhala localization, switchable in settings. |
| Inspector checklist | FR-06 | Pass / Partial / Fail per criterion with evidence photo and GPS. Score and grade are calculated on the server. |
| Periodic re-verification | NFR-06 | A daily scheduled command flags stalls whose last inspection is overdue. |
| Daily statuses and friends | Extra | Stories with likes and comments, plus friend requests by exact username. |
| In-app notifications | Extra | Alerts for customers and vendors with unread counts. |
| Low data use | NFR-03, NFR-07 | Paged lists, resized images and small payloads. |

---

## 🛠️ Tech Stack

| Layer | Technology | Why |
|---|---|---|
| Mobile app | **Flutter (Dart)** with **Riverpod** and **go_router** | One codebase for Android and iOS, good performance on low-end devices, built-in localization. |
| Networking and device | **Dio**, **flutter_secure_storage**, **geolocator**, **image_picker** | API calls with bearer-token handling, secure token storage, GPS position, camera and gallery photos. |
| Localization | **Flutter gen-l10n** (English and Sinhala ARB files) | Language switch applies immediately and is remembered. |
| Backend / API | **Laravel 13 (PHP 8.3+)** with **Sanctum** | Fast REST API development and token authentication. |
| Roles and permissions | **Spatie Laravel-Permission** | Four roles: customer, vendor, inspector, super-admin. |
| Database | **MySQL** (SQLite in memory for automated tests) | Relational data for users, vendors, reviews, inspections and statuses. |
| Image handling | **Intervention Image** | Resizes and re-encodes uploads and strips EXIF data. |
| Scheduled jobs | **Laravel scheduler** | Daily re-verification alerts and cleanup of expired statuses. |
| Admin panel | **Laravel Blade, Tailwind CSS and Vite** | Server-rendered web panel sharing the API's models and database. |
| Deployment | **Docker** (PHP 8.3-FPM image) | Repeatable backend environment. |
| Design | **Figma** | Prototype from Milestone 02. |

---

## 🧩 Project Modules

The app is organised around four functional areas, each mapped to requirements:

1. **Discovery, Proximity & Map Filtering** — home, map and list views, search, filter sheet and quick-info card.
2. **Vendor Profile & Hygiene Breakdown** — vendor profile, hygiene checklist, follow action and daily status updates.
3. **Crowd Evidence & Review Submission** — review form, review feed, photo evidence, edit, delete and report.
4. **Vendor Dashboard & Inspector Checklist** — vendor onboarding, dashboard (hours and menu), analytics and the inspector form.

Shared features cover authentication, friends, notifications and settings.

---

## 🖥️ Administrator Web Panel

A server-rendered web panel, kept out of the mobile app, for oversight that customers and vendors never see.

| Feature | Description |
|---|---|
| Dashboard and analytics | Platform-wide statistics |
| User management | View users, create inspector accounts, suspend or reinstate accounts |
| Stall management | Review, edit and delete stalls |
| Inspection audit trail and hygiene board | See inspections per stall and which stalls are overdue |
| Moderation | Hide, unhide or delete reviews, statuses and comments; handle review reports |
| Feature flags | Switch features off without releasing a new build |

Access is restricted to administrators, and the admin session is bound to the user's IP and user agent.

---

## 📂 Project Structure

```text
Street-food-app/
├── backend/                          # Laravel API and admin panel
│   ├── app/
│   │   ├── Console/Commands/         # Daily re-verification and cleanup commands
│   │   ├── Enums/
│   │   ├── Http/
│   │   │   ├── Controllers/Api/      # Mobile API controllers
│   │   │   ├── Controllers/Admin/    # Admin panel controllers
│   │   │   ├── Middleware/           # Feature flags, admin session security
│   │   │   ├── Requests/             # Form Requests (validation)
│   │   │   └── Resources/            # JSON response shapes
│   │   ├── Models/
│   │   ├── Observers/                # Rating recalculation, notifications
│   │   ├── Policies/
│   │   └── Services/
│   ├── database/                     # Migrations, factories, seeders
│   ├── resources/                    # Blade views for the admin panel
│   ├── routes/                       # api.php and web.php
│   ├── tests/                        # PHPUnit tests
│   └── Dockerfile
│
├── mobile/                           # Flutter app
│   ├── lib/
│   │   ├── core/                     # API client, storage, theme, router, widgets
│   │   ├── features/                 # auth, consumer, vendor, statuses, social,
│   │   │                             # notifications, inspector, settings
│   │   ├── l10n/                     # app_en.arb, app_si.arb
│   │   └── main.dart
│   ├── test/
│   └── pubspec.yaml
│
└── README.md
```

---

## 🚀 Getting Started

### Backend (Laravel API and admin panel)

Requirements: PHP 8.3 or newer with the `pdo_mysql`, `pdo_sqlite`, `sqlite3`, `gd` and `fileinfo` extensions, Composer, MySQL, and Node.js for the admin assets.

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
# set your MySQL database name, username and password in .env
php artisan migrate --seed
npm install && npm run build
php artisan serve
```

The API is then available at `http://localhost:8000/api`.

To run the daily jobs locally: `php artisan schedule:work`.

### Administrator panel

The admin panel is served by the same Laravel app. Open the admin login page (see `routes/web.php` for the exact path) and sign in with the administrator account created by the seeder. **[Add the seeded admin email here.]**

### Docker (optional)

```bash
cd backend
docker build -t streetbite-backend .
```

### Mobile app (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

Point the app at your running API before you start it. **[Add the exact setting here, for example the base URL in `lib/core/api/api_client.dart`.]** On an Android emulator, the host machine is reachable at `http://10.0.2.2:8000`. Debug builds allow plain HTTP so the emulator can reach a local server.

To build an installable Android package:

```bash
flutter build apk --release
```

---

## 🧪 Testing

**Automated tests**

```bash
# Backend (uses an in-memory SQLite database)
cd backend
php artisan test

# Mobile
cd mobile
flutter test
```

The backend tests cover authentication and roles, stall onboarding, menu management, hygiene and review endpoints, inspections, photo checks, statuses, moderation, suspension, feature flags and the admin pages. The mobile tests cover the API client, token storage, validators, authentication, localization and screen logic.

**Usability testing**

Milestone 02 prototype testing used 5 participants (3 consumers, 1 proxy vendor, 1 proxy inspector) with a moderated think-aloud method, measured against Task Completion Rate (target ≥ 80%), Single Ease Question (target ≥ 5.5 / 7) and System Usability Scale (target ≥ 70). Results for the working app are in the final report. **[Add the report or docs link.]**

---

## ⚠️ Known Limitations

- Google sign-in is a placeholder.
- The map is drawn inside the app, with pins placed by coordinates; it does not use live map tiles or directions.
- Notifications appear inside the app only; there are no push notifications.
- Only English and Sinhala are supported; Tamil is not available.

---

## 👥 Team — Group WD_07

| Name | Student ID | Module Owned |
|---|---|---|
| Liyanage L.P.S | IT23640184 | Module 1 — Discovery, Proximity & Map Filtering |
| Prabhath L A K G | IT23685116 | Module 2 — Vendor Profile & Hygiene Breakdown |
| Chathuranga GN | IT23603172 | Module 3 — Crowd Evidence & Review Submission |
| G.S Oudeen | IT23533714 | Module 4 — Vendor Dashboard & Inspector Checklist |

---

## 🎨 Design & Prototype Links

- **High-Fidelity Design:** [Figma — HCI Assignment 2](https://www.figma.com/design/0iCJJnWWAw5dovOkgHs152/HCI-assignment2)
- **Low-Fidelity Wireframes:** [Figma — Low-Fidelity HCI](https://www.figma.com/design/V8mMRi7lkxoBTNbIG1DoNO/Low-Fidelity---HCI)

---

## 📄 License

This project was developed for academic purposes as part of the IT3060 Human-Computer Interaction module at SLIIT. All rights reserved by the respective group members unless otherwise stated.
