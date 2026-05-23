# Food App

A Flutter mobile app for tracking nutrition and meals. Users log food intake, view nutritional stats, and manage favorites — personalized to their body metrics and fitness goals.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart) |
| Auth | Firebase Authentication |
| Backend API | Node.js at `http://192.168.1.13:3000` |
| Database | PostgreSQL |

---

## Features

- **Sign up / Sign in** — Firebase email/password auth, synced to PostgreSQL via backend
- **Onboarding** — Collects body measurements, activity level, and goal type on first login
- **Home** — Browse and search foods
- **Favorites** — Save frequently used foods
- **Stats** — View nutrition summaries and charts
- **Profile** — User info and settings

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

---

## Database Schema (PostgreSQL)

### `users`
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| name | text | |
| email | text | unique, not null |
| firebase_uid | text | unique, not null |
| created_at | timestamp | |

### `user_body_metrics`
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK → users |
| sex | enum(Unknown, Male, Female) | |
| height_cm | numeric | |
| weight_kg | numeric | |
| dob | date | |
| activity_level | enum | Sedentary → ExtremelyActive |
| goal_type | enum | LoseWeight, MaintainWeight, GainMuscle |
| dietary_restrictions | text | |
| measured_at | timestamp | |

### `food_catalog`
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| source_type | text | not null — data source identifier (e.g. `ai_generated`) |
| food_name | text | not null |
| image_url | text | |
| quantity / unit | numeric / text | serving size |
| calories | numeric | per serving |
| protein_g / carbs_g / fat_g | numeric | macronutrients (g) |
| food_type | food_type_enum | category enum (values defined in DB) |
| created_at / updated_at | timestamp | not null |
| **Micronutrients** | | all optional, per serving |
| dietary_fb_g | numeric | dietary fiber (g) |
| ash_g | numeric | ash (g) |
| calcium_mg / phosphorus_mg / magnesium_mg | numeric | minerals (mg) |
| sodium_mg / potassium_mg | numeric | minerals (mg) |
| iron_mg / copper_mg / zinc_mg | numeric | trace minerals (mg) |
| iodine_ug | numeric | iodine (µg) |
| betacarotene_ug / retinol_ug / v_a_ug | numeric | vitamin A group (µg) |
| thiamin_mg / riboflavin_mg / niacin_mg | numeric | B vitamins (mg) |
| v_c_mg | numeric | vitamin C (mg) |
| v_e_mg | numeric | vitamin E (mg) |

### `meals`
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK → users |
| date | date | |
| meal_type | text | breakfast / lunch / dinner / snack |
| create_at | timestamp | |

### `meal_items`
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| meal_id | uuid | FK → meals |
| food_catalog_id | uuid | |
| food_name / image_url | text | denormalized for read speed |
| quantity / unit | numeric / text | |
| calories / carbs_g / protein_g / fat_g | numeric | |

### `favorite_food`
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | numeric | FK → users |
| food_catalog_id | text | FK → food_catalog |
| create_at | timestamp | |

---

## Project Structure

```
lib/
├── config/         # Theme (AppTheme) and named routes (AppRoutes)
├── data/
│   ├── database.dart       # Singleton SQLite instance (AppDatabase)
│   └── daos/               # Data access objects per table
├── models/         # UserProfile (with BMI/BMR/TDEE), Food
├── screens/
│   ├── auth/       # LoginSheet, RegisterSheet, OnboardingScreen
│   └── ...         # HomeScreen, FavoriteScreen, StatsScreen, ProfileScreen
├── services/
│   ├── auth_service.dart   # Firebase auth + backend registration
│   └── api_service.dart    # Food search API
└── widgets/        # Reusable UI components
```
