# Training Up Project – Full Documentation

## 1) Project Overview

Training Up is a Flutter fitness app that includes:
- Authentication (register/login)
- Profile management
- Home dashboard with training content
- Exercises listing/details
- Meal plans (recipes)
- Progress view

Current backend base URL:
- `https://trainingg.pythonanywhere.com/api`

Current app startup route:
- `/home` (direct to Home screen)

---

## 2) Tech Stack

- Flutter / Dart (SDK constraint in `pubspec.yaml`: `^3.10.8`)
- HTTP networking: `http`
- Local key/value: `shared_preferences`
- Local box storage: `hive`
- UI helpers:
  - `font_awesome_flutter`
  - `smooth_page_indicator`
  - `provider` (available dependency)

---

## 3) Project Structure

### Core directories
- `lib/`
  - `main.dart` – app entry, routes, Hive init
  - `services/` – API/data services
  - `screens/` – UI screens
  - `utils/` – constants and styles
  - `widgets/` – reusable widgets
- `assets/`
  - exercises dataset/images
  - recipe dataset (legacy local fallback content)
- Platform folders:
  - `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/`

### Key service files
- `lib/services/api_service.dart`
- `lib/services/exercise_service.dart`

---

## 4) Routing

Defined in `lib/main.dart`:
- `/` → `SplashScreen`
- `/onboarding` → `OnboardingScreen`
- `/login` → `LoginScreen`
- `/register` → `RegisterScreen`
- `/forgot-password` → `ForgotPasswordScreen`
- `/profile-setup` → `ProfileSetupScreen`
- `/final-onboarding` → `FinalOnboardingScreen`
- `/home` → `HomeScreen`

Notes:
- `initialRoute` is currently `/home`.
- `verify_email_screen.dart` exists but is currently commented out in source, and no active generated route is configured for it.

---

## 5) API Integration Status

This project now includes service methods for all listed TrainUp endpoints.

## Authentication / account
- `POST /register/` → `register(...)`
- `POST /verify-email/` → `verifyEmail(...)`
- `POST /login/` → `login(...)`
- `GET /profile/` → `getProfile()`
- `PUT /profile/` → `updateProfile(...)`
- `POST /change-password/` → `changePassword(...)`
- `POST /logout/` → `logout()`
- `DELETE /delete-account/` → `deleteAccount()`
- `GET /my-role/` → `getMyRole()`

## Exercises
- `GET /exercises/` (+ filters) → `getExercises(...)`
- `GET /exercises/{id}/` → `getExerciseDetails(id)`
- `POST /exercises/` → `createExercise(...)`
- `PUT /exercises/{id}/manage/` → `updateExercise(...)`
- `DELETE /exercises/{id}/manage/` → `deleteExercise(id)`
- `GET /exercise-categories/` → `getExerciseCategories()`

## Exercise progress
- `POST /my-exercises/{exercise_id}/mark/` → `markMyExercise(...)`
- `GET /my-exercises/summary/` → `getMyExerciseSummary(...)`
- `GET /my-exercise-progress/` → `getMyExerciseProgress()`

## Coach trainee progress
- `POST /trainees/{trainee_id}/progress/add/` → `addTraineeProgress(...)`
- `GET /trainees/{trainee_id}/progress/current/` → `getTraineeCurrentProgress(...)`
- `GET /trainees/{trainee_id}/progress/timeline/` → `getTraineeProgressTimeline(...)`

## Recipes
- `GET /recipes/` → `getRecipes()`
- `GET /recipes/{id}/` → `getRecipeDetails(id)`

### Header behavior
`ApiService` automatically manages token persistence in `SharedPreferences` and applies:
- `Authorization: Token <token>` for authenticated requests
- `Content-Type: application/json`

For some list endpoints, it tries public first and retries with auth on `401/403`.

---

## 6) Screen-to-API Usage

### Actively connected
- `login_screen.dart`
  - `login(...)`
- `register_screen.dart`
  - `register(...)` (includes phone)
- `home_screen.dart`
  - `getProfile()`
  - `logout()`
- `meal_plans_screen.dart`
  - `getRecipes()`
- `my_progress_screen.dart`
  - `getMyExerciseSummary()`
  - `getMyExerciseProgress()`
- `edit_profile_screen.dart`
  - `updateProfile(...)`
- exercise-related screens via `exercise_service.dart`
  - now API-first exercise loading with local asset fallback

### Not actively wired in UI flow
- Verify email screen flow (screen file commented)
- Coach-only trainee progress endpoints (service exists, no full UI flow yet)
- Exercise create/update/delete UI for coach/admin (service exists)

---

## 7) Data Layer Notes

## `api_service.dart`
Centralized HTTP service returning standardized maps:
- success cases: `{ "success": true, "data": ... }` (or `message`/`role`)
- failure cases: `{ "success": false, "error": ... }`

## `exercise_service.dart`
- Loads exercises from backend first (`/exercises/`)
- Keeps compatibility with existing UI data contract (`path`, `data`, `image`)
- Falls back to local JSON assets when API is unavailable

---

## 8) Local Storage

- Token storage: `SharedPreferences` key `auth_token`
- App box: `Hive` (`AppConstants.hiveAppBox`)
- Cached profile data stored in Hive and reused on app start

---

## 9) Setup & Run

From project root:

1. `flutter pub get`
2. `flutter run`

Optional checks:
- `flutter analyze`
- `flutter test`

---

## 10) Current Behavior Summary

- App launches to Home directly.
- Recipes are loaded from API.
- Exercises are loaded API-first, with assets fallback.
- My Progress uses backend summary/progress endpoints.
- Logout is available in Home header and drawer.

---

## 11) Recommended Next Steps

1. Re-enable and wire `verify_email_screen.dart` route and UI flow.
2. Add role-based UI:
   - coach/admin screens for exercise CRUD
   - coach screens for trainee progress endpoints
3. Add centralized error widgets/snackbars for API failures.
4. Add pagination/search for large exercise/recipe lists.
5. Add unit tests for `ApiService` and `ExerciseService`.

---

## 12) Maintainer Notes

If endpoint contracts change, update only:
- `lib/services/api_service.dart`
- normalization logic in `lib/services/exercise_service.dart`

Then keep screens unchanged as much as possible.
