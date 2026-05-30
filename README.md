<div align="center">

# 🍽️ Food App

**A Flutter mobile app for tracking nutrition and meals.**

Log food intake, view nutritional stats, and manage favorites — personalized to your body metrics and fitness goals.

![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Auth-Firebase-FFCA28?logo=firebase&logoColor=black)
![Backend](https://img.shields.io/badge/API-Node.js-339933?logo=nodedotjs&logoColor=white)
![Database](https://img.shields.io/badge/DB-PostgreSQL-4169E1?logo=postgresql&logoColor=white)
![Localized](https://img.shields.io/badge/UI-Thai-blue)

</div>

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Useful Commands](#useful-commands)
- [App Flow](#app-flow)
- [Project Structure](#project-structure)
- [Database Schema](#database-schema-postgresql)
- [Conventions](#conventions)

---

## Overview

Food App is the Flutter front end of a client–server nutrition tracker. The app
handles the UI and user authentication; a separate Node.js backend persists all
data to PostgreSQL. There is **no local database** — every read and write goes
through the backend API.

Authentication is two-layered:

1. **Firebase Auth** owns the credentials and issues a JWT ID token.
2. Every protected API call attaches that token as a `Bearer` header. The
   backend verifies it and maps the Firebase user to a PostgreSQL record.

The interface is fully localized to **Thai**, using the rounded *Mali* font for
Thai + Latin glyph coverage.

Network reads are wrapped in a lightweight in-memory cache (`RequestCache`) with
per-key TTLs, so switching tabs or re-rendering doesn't re-hit the backend.
Writes invalidate the affected keys; logout clears the whole cache.

---

## Tech Stack

| Layer        | Technology                                  |
| ------------ | ------------------------------------------- |
| Mobile       | Flutter (Dart, SDK `^3.9.2`)                |
| Auth         | Firebase Authentication                     |
| Backend API  | Node.js — `ApiConfig.baseUrl` (default `http://10.0.2.2:3000`) |
| Database     | PostgreSQL (server-side only)               |
| Networking   | `http` package (multipart for avatar upload) |
| Images       | `image_picker`, `cached_network_image`      |
| Typography   | `google_fonts` (Mali)                       |

**Direct dependencies:** `flutter`, `firebase_core`, `firebase_auth`, `http`, `http_parser`, `google_fonts`, `image_picker`, `cached_network_image`.

---

## Features

- **Sign up / Sign in** — Firebase email/password auth, synced to PostgreSQL via the backend.
- **Onboarding** — Collects body measurements, activity level, and goal type on first login.
- **Home** — Browse and search foods, plus **recommended foods** that fit your remaining daily calorie/macro budget.
- **Food search** — DB-first autocomplete and lookup; an explicit "ค้นหาด้วย AI" action falls back to a (paid) AI nutrition estimate when a dish isn't in the catalog yet.
- **Favorites** — Save frequently used foods.
- **Stats** — Nutrition summaries and charts (BMI / BMR / TDEE), with a weekly calendar strip to browse meal history by day.
- **Profile** — User info, body metrics, history, settings, and **profile photo upload** (mirrored into Firebase `photoURL`).

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.9.2`)
- A connected device or emulator (Android / iOS), or a desktop/web target
- Access to the running [backend server](#configuration)
- A Firebase project configured for this app (`firebase_options.dart` / platform config files)

### Setup

```bash
# 1. Clone and enter the project
git clone <repository-url>
cd food-app

# 2. Install dependencies
flutter pub get

# 3. (One-time) verify your toolchain
flutter doctor

# 4. Run on a connected device or emulator
flutter run
```

> **Note:** Firebase config files and `firebase_options.dart` are environment-specific
> and are **not** committed — generate them yourself (see [Configuration](#configuration)).

---

## Configuration

- **Backend URL** — set in `lib/config/api_config.dart` (`ApiConfig.baseUrl`); used app-wide.
  The default `http://10.0.2.2:3000` is the Android emulator's loopback to the host
  machine. For a physical device, use the host's LAN IP (e.g. `http://192.168.x.x:3000`);
  for the iOS simulator or desktop/web, `http://localhost:3000`.
- **Firebase** — see below.

### Firebase

The app requires valid Firebase configuration for your platforms (e.g.
`google-services.json` for Android, `GoogleService-Info.plist` for iOS, and a
generated `firebase_options.dart`). These are environment-specific and are **not**
committed — generate them with the [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup).

---

## Useful Commands

```bash
flutter run            # Run on a connected device or emulator
flutter build apk      # Build an Android APK
flutter analyze        # Static analysis / linting
flutter test           # Run the test suite
flutter pub get        # Fetch dependencies
```

---

## App Flow

```
WelcomeScreen (/)
  ├── LoginSheet
  └── RegisterSheet
        └── OnboardingScreen (/auth/onboard)   ← body metrics, activity, goal
              └── MainScreen (/main)
                    ├── HomeScreen
                    ├── FavoriteScreen
                    ├── StatsScreen
                    └── ProfileScreen
```

- **Register →** `OnboardingScreen` (3-step PageView) **→** `MainScreen`
- **Login →** `MainScreen` directly

---

## Project Structure

```
lib/
├── main.dart           # App entrypoint (MaterialApp, theme, routes)
├── config/
│   ├── api_config.dart   # Single source of truth for the backend base URL
│   ├── app_theme.dart    # AppTheme — colors (#ABD726), Mali text styles
│   └── routes.dart       # AppRoutes — named route constants
├── models/
│   ├── user.dart         # UserProfile (computed BMI / BMR / TDEE)
│   ├── body_metrics.dart # Body-metric enums & helpers
│   └── food.dart         # Food (maps food_catalog; JSON ↔ meal item)
├── screens/
│   ├── auth/             # WelcomeScreen, LoginSheet, RegisterSheet, OnboardingScreen
│   ├── profile/          # Profile sub-screens (info, history, settings, about…)
│   └── *.dart            # HomeScreen, FavoritesScreen, StatsScreen, FoodDetailScreen…
├── services/
│   ├── auth_service.dart            # Firebase auth + registration, body metrics, avatar upload
│   ├── api_service.dart            # FoodApiService — DB search/suggest + explicit AI search
│   ├── meals_service.dart          # Meals CRUD against /meals (cache-aware)
│   ├── recommendations_service.dart # GET /recommendations — remaining-budget food picks
│   └── cache/
│       └── request_cache.dart      # RequestCache — in-memory TTL cache shared by services
└── widgets/             # Reusable UI components (nav, cards, charts, week_calendar_strip…)
```

> All data is served by the backend over HTTP — there is no local SQLite layer.

---

## Database Schema (PostgreSQL)

> Owned by the backend. Listed here for reference when consuming the API.

### `users`

| Column       | Type      | Notes              |
| ------------ | --------- | ------------------ |
| id           | uuid      | PK                 |
| name         | text      |                    |
| email        | text      | unique, not null   |
| firebase_uid | text      | unique, not null   |
| photo_url    | text      | avatar URL; mirrored to Firebase `photoURL` |
| created_at   | timestamp |                    |

### `user_body_metrics`

| Column               | Type                         | Notes                            |
| -------------------- | ---------------------------- | -------------------------------- |
| id                   | uuid                         | PK                               |
| user_id              | uuid                         | FK → users                       |
| sex                  | enum(Unknown, Male, Female)  |                                  |
| height_cm            | numeric                      |                                  |
| weight_kg            | numeric                      |                                  |
| dob                  | date                         |                                  |
| activity_level       | enum                         | Sedentary → ExtremelyActive      |
| goal_type            | enum                         | LoseWeight, MaintainWeight, GainMuscle |
| dietary_restrictions | text                         |                                  |
| measured_at          | timestamp                    |                                  |

### `food_catalog`

| Column                                    | Type            | Notes                                    |
| ----------------------------------------- | --------------- | ---------------------------------------- |
| id                                        | uuid            | PK                                       |
| source_type                               | text            | not null — data source (e.g. `ai_generated`) |
| food_name                                 | text            | not null                                 |
| image_url                                 | text            |                                          |
| quantity / unit                           | numeric / text  | serving size                             |
| calories                                  | numeric         | per serving                              |
| protein_g / carbs_g / fat_g               | numeric         | macronutrients (g)                       |
| food_type                                 | food_type_enum  | category enum (values defined in DB)     |
| created_at / updated_at                   | timestamp       | not null                                 |
| **Micronutrients**                        |                 | *all optional, per serving*              |
| dietary_fb_g                              | numeric         | dietary fiber (g)                        |
| ash_g                                     | numeric         | ash (g)                                  |
| calcium_mg / phosphorus_mg / magnesium_mg | numeric         | minerals (mg)                            |
| sodium_mg / potassium_mg                  | numeric         | minerals (mg)                            |
| iron_mg / copper_mg / zinc_mg             | numeric         | trace minerals (mg)                      |
| iodine_ug                                 | numeric         | iodine (µg)                              |
| betacarotene_ug / retinol_ug / v_a_ug     | numeric         | vitamin A group (µg)                     |
| thiamin_mg / riboflavin_mg / niacin_mg    | numeric         | B vitamins (mg)                          |
| v_c_mg                                    | numeric         | vitamin C (mg)                           |
| v_e_mg                                    | numeric         | vitamin E (mg)                           |

### `meals`

| Column     | Type      | Notes                              |
| ---------- | --------- | ---------------------------------- |
| id         | uuid      | PK                                 |
| user_id    | uuid      | FK → users                         |
| date       | date      |                                    |
| meal_type  | text      | breakfast / lunch / dinner / snack |
| create_at  | timestamp |                                    |

### `meal_items`

| Column                                  | Type           | Notes                       |
| --------------------------------------- | -------------- | --------------------------- |
| id                                      | uuid           | PK                          |
| meal_id                                 | uuid           | FK → meals                  |
| food_catalog_id                         | uuid           |                             |
| food_name / image_url                   | text           | denormalized for read speed |
| quantity / unit                         | numeric / text |                             |
| calories / carbs_g / protein_g / fat_g  | numeric        |                             |

### `favorite_food`

| Column          | Type      | Notes               |
| --------------- | --------- | ------------------- |
| id              | uuid      | PK                  |
| user_id         | numeric   | FK → users          |
| food_catalog_id | text      | FK → food_catalog   |
| create_at       | timestamp |                     |

---

## Conventions

- **Commits** follow [Conventional Commits](https://www.conventionalcommits.org/):
  `<type>(<scope>): <short description>` — e.g. `feat(auth): add login page`.
  Types: `feat`, `fix`, `docs`, `refactor`, `chore`.
- **Branching** — never commit directly to `main`; branch first.
- **Theming** — reference `AppTheme` constants (in `lib/config/app_theme.dart`)
  instead of hardcoding colors or text styles.
- **Routing** — add named routes to `AppRoutes` (`lib/config/routes.dart`) and
  navigate by constant, not inline strings.
