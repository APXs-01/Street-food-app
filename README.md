# StreetBite — Street-Food Vendor Locator with Hygiene Ratings

[![Flutter](https://img.shields.io/badge/Flutter-Mobile_App-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Laravel](https://img.shields.io/badge/Laravel-Backend_API-FF2D20?logo=laravel&logoColor=white)](https://laravel.com/)
[![Firebase](https://img.shields.io/badge/Firebase-Realtime_%26_Notifications-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Google Maps](https://img.shields.io/badge/Google_Maps-Location_Services-4285F4?logo=googlemaps&logoColor=white)](https://developers.google.com/maps)
[![MySQL](https://img.shields.io/badge/MySQL-Database-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Filament](https://img.shields.io/badge/Filament-Admin_Panel-FDAE4B?logoColor=black)](https://filamentphp.com/)
[![Figma](https://img.shields.io/badge/Figma-UI%2FUX_Design-F24E1E?logo=figma&logoColor=white)](https://www.figma.com/)

A mobile app that helps consumers discover nearby street-food vendors with verified hygiene ratings, and gives vendors a simple way to build trust and grow their customer base — without needing complex technology.

Built as part of **IT3060 — Human Computer Interaction**, SLIIT (3rd Year, 2nd Semester), Group **WD_07**.

---

## 📱 Overview

Street food is a daily reality for many people, but there's no reliable way to check a stall's hygiene before buying — and clean, hardworking vendors have no way to prove it. **StreetBite** solves this by combining:

- **Verified hygiene ratings**, backed by a 5-point inspection checklist (water source, utensil/glove hygiene, waste disposal, food covering, and overall cleanliness).
- **Crowd-sourced photo evidence**, automatically timestamped to prevent outdated or misleading images.
- **A live map** to discover nearby vendors, filterable by hygiene rating and distance.
- **A minimal-tap vendor dashboard**, available in Sinhala, for busy vendors with limited smartphone experience.
- **A health inspector submission flow**, so ratings are grounded in real, structured evaluation — not just self-reported claims.

---

## ✨ Core Features

| Feature | Requirement | Description |
|---|---|---|
| Map-based discovery | FR-05 | Search and filter nearby vendors by hygiene rating and distance |
| Live vendor status | FR-09 | Real-time open/closed status and operating hours on the map |
| Hygiene rating & breakdown | FR-01, FR-10, FR-11 | Overall score plus a 5-point checklist breakdown, including verified water source |
| PHI-verified badge | FR-03 | Official inspection badge, distinct from crowd-sourced ratings |
| Daily menu | FR-08 | Vendors can display and update their daily menu and mark items as freshly prepared |
| Photo & review submission | FR-02, FR-07 | Consumers submit star ratings, written reviews, and photo evidence |
| Automatic photo timestamping | NFR-04 | In-app camera burns a visible timestamp into captures — no gallery uploads, to prevent outdated evidence |
| Sinhala vendor dashboard | FR-04, NFR-02 | Minimal-tap, localized interface for vendors |
| Inspector checklist submission | FR-06 | Structured Pass/Fail evaluation form for health inspectors |
| Periodic re-verification | NFR-06 | Ratings are re-checked over time rather than treated as a permanent badge |
| Low-bandwidth friendly | NFR-03, NFR-07 | Optimized for basic phones and slower mobile connections |

---

## 🛠️ Tech Stack

| Layer | Technology | Why |
|---|---|---|
| Mobile App | **Flutter** | Single codebase for Android and iOS, strong performance on low-end devices, and localization support for Sinhala |
| Backend / API | **Laravel** | Fast REST API development, built-in authentication with Sanctum for three distinct roles (consumer, vendor, inspector), and scheduled jobs for periodic rating re-verification |
| Real-time & Notifications | **Firebase (Firestore / FCM)** | Live status updates, map pin synchronization, and push notifications without constant API polling |
| Maps | **Google Maps Flutter Plugin** | Live vendor pins, radius filtering, and location services |
| Database | **MySQL / PostgreSQL** | Relational data management for vendors, users, reviews, ratings, and inspection records |
| Design & Prototyping | **Figma** | Shared component library and collaborative prototyping across all modules during the design phase |
| Super Admin Panel | **Laravel Filament** | Web-based admin dashboard integrated with the same Laravel backend and models, avoiding the need for a separate frontend |

---

## 🧩 Project Modules

The app is structured around four functional modules, each mapped to a set of requirements:

1. **Discovery, Proximity & Map Filtering** — map view, search, radius/hygiene filter sheet, and quick-info vendor card.
2. **Vendor Profile & Hygiene Breakdown** — vendor profile, PHI badge, 5-point checklist, verified water-source tag, and daily menu.
3. **Crowd Evidence & Review Submission** — photo proof gallery, review/rating modal, and timestamped in-app camera.
4. **Vendor Dashboard & Inspector Checklist** — Sinhala vendor dashboard, operating hours and menu management, and inspector submission form.

---

## 🖥️ Super Admin Web Panel

A separate, web-based control panel — kept out of the mobile app entirely — for platform-level oversight that consumers and vendors never see.

| Feature | Description |
|---|---|
| User Management | View, suspend, or verify consumer and vendor accounts |
| Vendor Oversight | Review self-onboarded stalls; edit, remove, or flag suspicious listings |
| Inspector Accounts | Create and manage certified health inspector logins |
| Hygiene Rating Oversight | View all ratings, manually trigger re-verification, and override disputed scores |
| Review & Photo Moderation | Remove fake reviews or inappropriate photos and audit timestamp integrity |
| Checklist Criteria Management | Edit the 5-point hygiene checklist categories without a code deployment |
| Analytics Dashboard | Platform-wide statistics — active vendors, average ratings, and flagged content |
| Content & Localization | Manage Sinhala, English, and Tamil translation strings |
| Dispute Resolution | Handle vendor appeals against a low rating or a review |

Built with **Laravel Filament**, sharing the same models and database as the mobile app's API. Admin actions — such as suspending a vendor — can therefore take effect across the platform without a separate synchronization step.

---

## 📂 Suggested Project Structure

```text
streetbite/
├── backend/                      # Laravel API + Filament Admin Panel
│   ├── app/
│   │   ├── Models/
│   │   ├── Http/
│   │   │   ├── Controllers/
│   │   │   └── Middleware/
│   │   └── Filament/
│   │       └── Resources/         # Admin panel CRUD resources
│   │           ├── UserResource.php
│   │           ├── VendorResource.php
│   │           ├── InspectorResource.php
│   │           ├── RatingResource.php
│   │           └── ReviewResource.php
│   ├── database/
│   │   └── migrations/
│   ├── routes/
│   │   └── api.php
│   └── .env.example
│
├── mobile/                        # Flutter app
│   ├── lib/
│   │   ├── modules/
│   │   │   ├── discovery/         # Module 1 — Map & Filtering
│   │   │   ├── vendor_profile/    # Module 2 — Profile & Hygiene Breakdown
│   │   │   ├── reviews/           # Module 3 — Photo/Review Submission
│   │   │   └── vendor_dashboard/  # Module 4 — Dashboard & Inspector Checklist
│   │   ├── shared/
│   │   │   ├── widgets/
│   │   │   └── services/
│   │   └── main.dart
│   └── pubspec.yaml
│
└── README.md
```

---

## 🚀 Getting Started

### Backend (Laravel API)

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

### Super Admin Panel (Laravel Filament)

From the `backend` directory, install Filament and configure the admin panel:

```bash
composer require filament/filament:"^3.0" -W
php artisan filament:install --panels
php artisan make:filament-user
```

The final command creates your first super admin login.

Once configured, the admin panel is available at `http://localhost:8000/admin` using the same Laravel backend and database as the mobile app's API.

### Mobile App (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

> **Note:** Configure your Google Maps API key and Firebase configuration files (`google-services.json` / `GoogleService-Info.plist`) before running the app.

---

## 🧪 Testing

Usability testing was conducted with 5 participants (3 consumers, 1 proxy vendor, and 1 proxy health inspector) using a moderated think-aloud method, measured against:

- **Task Completion Rate (TCR)** — target ≥ 80%
- **Single Ease Question (SEQ)** — target ≥ 5.5 / 7
- **System Usability Scale (SUS)** — target ≥ 70

See `/docs/usability-testing.md` (or the Milestone 02 report) for full task scripts, participant profiles, and findings.

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
