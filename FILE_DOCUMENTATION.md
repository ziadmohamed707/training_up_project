# Training Up — Complete File Documentation & Code Discussion

> **App:** Training Up  
> **Framework:** Flutter (Dart)  
> **Backend:** REST API — `https://trainingg.pythonanywhere.com/api`  
> **Generated:** April 6, 2026

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack & Dependencies](#2-tech-stack--dependencies)
3. [Project Structure](#3-project-structure)
4. [Entry Point — `main.dart`](#4-entry-point--maindart)
5. [Models](#5-models)
   - [UserModel](#51-usermodel)
   - [ProfileSetupModel](#52-profilesetupmodel)
6. [Services](#6-services)
   - [ApiService](#61-apiservice)
   - [ExerciseService](#62-exerciseservice)
7. [Utilities](#7-utilities)
   - [AppConstants](#71-appconstants)
   - [AppStyles](#72-appstyles)
8. [Widgets](#8-widgets)
   - [CustomButton](#81-custombutton)
   - [CustomTextField](#82-customtextfield)
9. [Screens](#9-screens)
   - [SplashScreen](#91-splashscreen)
   - [OnboardingScreen](#92-onboardingscreen)
   - [LoginScreen](#93-loginscreen)
   - [RegisterScreen](#94-registerscreen)
   - [ForgotPasswordScreen](#95-forgotpasswordscreen)
   - [VerifyEmailScreen](#96-verifyemailscreen)
   - [ProfileSetupScreen](#97-profilesetupscreen)
   - [FinalOnboardingScreen](#98-finalonboardingscreen)
   - [HomeScreen](#99-homescreen)
   - [ExerciseDetailScreen](#910-exercisedetailscreen)
   - [FullExerciseScreen](#911-fullexercisescreen)
   - [FiltersPlanScreen](#912-filtersplanscreen)
   - [DashboardScreen](#913-dashboardscreen)
   - [MyProgressScreen](#914-myprogressscreen)
   - [MealPlansScreen](#915-mealplansscreen)
   - [ProfileScreen](#916-profilescreen)
   - [EditProfileScreen](#917-editprofilescreen)
   - [AppSettingsScreen](#918-appsettingsscreen)
10. [Data Flow & Architecture](#10-data-flow--architecture)
11. [Local Storage Strategy](#11-local-storage-strategy)
12. [API Endpoint Summary](#12-api-endpoint-summary)
13. [Navigation Map](#13-navigation-map)
14. [Code Discussion & Design Decisions](#14-code-discussion--design-decisions)

---

## 1. Project Overview

**Training Up** is a cross-platform fitness application built with Flutter. It helps users:

- Register / log in with email verification.
- Set up a fitness profile (age, weight, height, goal, fitness level).
- Browse and start exercise sessions grouped by category (Cardio, Strength, Powerlifting, etc.).
- Track daily calorie burn and workout progress.
- View meal / recipe plans.
- Monitor personal statistics via a dedicated dashboard.
- Edit their profile and manage app settings.

The app communicates with a Django REST backend hosted on PythonAnywhere, using token-based authentication. Offline resilience is achieved through a combination of **Hive** (fast NoSQL) and **SharedPreferences** for local caching.

---

## 2. Tech Stack & Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK | UI framework |
| `http` | ^1.2.0 | HTTP REST calls |
| `provider` | ^6.1.1 | State management (profile setup wizard) |
| `shared_preferences` | ^2.2.2 | Auth token & flags persistence |
| `hive` | ^2.2.3 | Fast local cache (profile, calorie history) |
| `smooth_page_indicator` | ^1.1.0 | Onboarding page dots |
| `font_awesome_flutter` | ^10.7.0 | Extended icon set |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

**Dev dependencies:** `flutter_lints ^6.0.0`, `flutter_test`

---

## 3. Project Structure

```
lib/
├── main.dart                    # App entry point & route table
├── models/
│   ├── user_model.dart          # User entity + JSON serialization
│   └── profile_setup_model.dart # Profile wizard data container
├── services/
│   ├── api_service.dart         # All HTTP calls to the backend (793 lines)
│   └── exercise_service.dart    # Exercise loading from assets + API (420 lines)
├── utils/
│   ├── app_constants.dart       # App-wide string/key constants
│   └── app_styles.dart          # Color palette & text styles
├── widgets/
│   ├── custom_button.dart       # Reusable ElevatedButton wrapper
│   └── custom_text_field.dart   # Reusable TextFormField with password toggle
└── screens/
    ├── splash_screen.dart
    ├── onboarding_screen.dart
    ├── login_screen.dart
    ├── register_screen.dart
    ├── forgot_password_screen.dart
    ├── verify_email_screen.dart
    ├── profile_setup_screen.dart
    ├── final_onboarding_screen.dart
    ├── home_screen.dart
    ├── exercise_detail_screen.dart
    ├── full_exercise_screen.dart
    ├── filters_plan_screen.dart
    ├── dashboard_screen.dart
    ├── my_progress_screen.dart
    ├── meal_plans_screen.dart
    ├── profile_screen.dart
    ├── edit_profile_screen.dart
    └── app_settings_screen.dart
```

---

## 4. Entry Point — `main.dart`

**File:** `lib/main.dart`

### Responsibilities

1. **Orientation lock** — enforces portrait-only mode via `SystemChrome.setPreferredOrientations`.
2. **Hive initialization** — sets up a `.training_up_hive` directory under `~/Documents/` (falls back to system temp) and opens the `app_cache_box` box.
3. **Route registration** — defines all named routes for the app.
4. **Theme** — applies `AppColors.primary` (sky blue) as seed color with Material 3.

### Route Table

| Route | Screen |
|---|---|
| `/` | `SplashScreen` |
| `/onboarding` | `OnboardingScreen` |
| `/login` | `LoginScreen` |
| `/register` | `RegisterScreen` |
| `/forgot-password` | `ForgotPasswordScreen` |
| `/profile-setup` | `ProfileSetupScreen` |
| `/final-onboarding` | `FinalOnboardingScreen` |
| `/home` | `HomeScreen` |

> **Note:** `initialRoute` is set to `/home` (not `/`), meaning `SplashScreen` is only reached via explicit navigation. This is a design shortcut — the splash logic actually sits in the route, but the app launches directly into `HomeScreen` during development to skip the splash delay.

### Key Code Pattern

```dart
Hive.init(hiveDir.path);
await Hive.openBox(AppConstants.hiveAppBox);
runApp(const MyApp());
```

---

## 5. Models

### 5.1 `UserModel`

**File:** `lib/models/user_model.dart`

A plain Dart class representing the authenticated user.

#### Fields

| Field | Type | Description |
|---|---|---|
| `id` | `int?` | Server-assigned user ID (`user_id`) |
| `username` | `String` | Login username |
| `email` | `String` | User email |
| `phone` | `String?` | Optional phone number |
| `role` | `String` | `admin`, `coach`, or `trainee` |
| `fullName` | `String` | Display name |
| `token` | `String?` | Auth token returned by the backend |

#### Methods

- `UserModel.fromJson(Map)` — factory constructor mapping API response keys.
- `toJson()` — serializes back to a `Map` for storage or sending to API.

#### Code Discussion

The `id` field maps from `json['user_id']` rather than `json['id']`, which is aligned with the Django backend convention. The `token` field is embedded in the model but also persisted separately via `ApiService.saveToken()` — this is intentional redundancy for convenience.

---

### 5.2 `ProfileSetupModel`

**File:** `lib/models/profile_setup_model.dart`

A mutable data container used exclusively during the profile setup wizard.

#### Fields

| Field           | Type      | Default | Description |
|-----------------|-----------|---------|---------------------------------------------------|
| `age`           | `int?`    |     —   | User age                                          |
| `currentWeight` | `double?` |     —   | Current body weight                               |
| `goalWeight`    | `double?` |     —   | Target weight                                     |
| `height`        | `double?` |     —   | Body height                                       |
| `fitnessLevel`  | `String?` |     —   | `beginner` / `intermediate` / `advanced`          |
| `goal`          | `String?` |     —   | `weight_loss` / `gain_muscle` / `improve_fitness` |
| `weightUnit`    | `String?` | `'kg'`  | `kg` or `lbs`                                     |
| `heightUnit`    | `String?` | `'cm'`  | `cm` or `feet`                                    |
|-------------------------------------------------------------------------------------------|

#### Methods

- `toJson()` — serializes to `Map` for the profile setup API call.

#### Code Discussion

This model has **no `fromJson`** — it is a write-only wizard model. It is created fresh each setup session and disposed after submission. All reading of persisted profile data happens through `ApiService.getProfile()` or the Hive cache.

---

## 6. Services

### 6.1 `ApiService`

**File:** `lib/services/api_service.dart`  
**Size:** ~793 lines

The single HTTP client for the entire application. All API calls return `Map<String, dynamic>` with keys `success` (bool), `data` (on success), and `error` (on failure).

#### Base URL

```dart
static const String baseUrl = 'https://trainingg.pythonanywhere.com/api';
```

#### Token Management

| Method | Description |
|---|---|
| `getToken()` | Reads from in-memory cache, then SharedPreferences |
| `saveToken(token)` | Persists to memory + SharedPreferences |
| `clearToken()` | Removes from both stores (used on logout) |

Token is passed in every authenticated request as:
```
Authorization: Token <token>
```

#### API Methods Summary

| Method                   | Endpoint                     | Auth | Description                                  |
|--------------------------|------------------------------|------|----------------------------------------------|
| `register(...)`          | `POST /register/`            | ❌   | Creates a new account; saves token on success|
| `verifyEmail(...)`       | `POST /verify-email/`        | ❌   | Validates OTP code                           |
| `login(...)`             | `POST /login/`               | ❌   | Returns token on success                     |
| `getProfile()`           | `GET /profile/`              | ✅   | Fetches user + fitness profile               |
| `updateProfile(...)`     | `PUT /profile/`              | ✅   | Updates editable fields                      |
| `setupProfile(...)`      | `POST /profile-setup/`       | ✅   | Initial profile creation after registration  |
| `forgotPassword(...)`    | `POST /forgot-password/`     | ❌   | Sends reset code to email                    |
| `resetPassword(...)`     | `POST /reset-password/`      | ❌   | Applies new password with code               |
| `getMyExerciseSummary()` | `GET /my-exercises/summary/` | ✅   | Completed/in-progress exercise counts        |
| `markExercise(...)`      | `POST /my-exercises/`        | ✅   | Logs a started exercise                      |
| `getMyExercises()`       | `GET /my-exercises/`         | ✅   | Lists all logged exercises                   |
| `getExercises(...)`      | `GET /exercises/`            | ✅   | Paginated exercise list                      |
| `getExerciseById(id)`    | `GET /exercises/{id}/`       | ✅   | Single exercise detail                       |
| `getMealPlans()`         | `GET /meal-plans/`           | ✅   | Recipe/meal list                             |
| `getMealPlanById(id)`    | `GET /meal-plans/{id}/`      | ✅   | Single recipe detail                         |
| `logout()`               | Clears token locally         | —---| No server call                                |

#### Code Discussion

- **Uniform response contract** — every method wraps the result in `{'success': bool, 'data': ..., 'error': ...}`. This means callers never need to deal with raw HTTP status codes or exceptions.
- **Graceful degradation** — all methods catch exceptions and return `{'success': false, 'error': '...'}` instead of throwing. This enables safe `result['success']` checks throughout the UI.
- **In-memory token cache** — `_token` is stored in memory after the first read, avoiding repeated SharedPreferences disk reads on every request.

---

### 6.2 `ExerciseService`

**File:** `lib/services/exercise_service.dart`  
**Size:** ~420 lines

Responsible for loading exercise data from **bundled JSON assets** and merging it with data from the **live API**.

#### Asset Structure

Exercises are stored as JSON files under:
```
assets/exercises_by_category/
  _index.json              ← master index of all exercise file paths
  cardio/
  strength/
  olympic_weightlifting/
  plyometrics/
  powerlifting/
  stretching/
  strongman/
```

#### Key Methods

| Method | Description |
|---|---|
| `listJsonKeys()` | Returns all exercise keys (asset paths + API items) |
| `loadExerciseByKey(key)` | Loads a single exercise by key, returns normalized map |
| `_normalizeApiExercise(source)` | Merges API fields to a consistent schema |
| `_inferAssetImageForApiExercise(data, keys)` | Fuzzy-matches an API exercise name to a local asset image |
| `_normalizeCategoryFolder(value)` | Normalizes category names to folder names (`Olympic Weightlifting` → `olympic_weightlifting`) |
| `_nameCandidates(rawName)` | Generates multiple file-name candidates for fuzzy image lookup |

#### Code Discussion

- **Dual-source architecture** — exercises can come from either bundled assets (offline, fast) or the live API (up-to-date). API exercises get a special `api:` prefix key to distinguish them.
- **Fuzzy image matching** — `_inferAssetImageForApiExercise` generates multiple naming variants (replacing spaces, commas, dashes) and searches asset keys to find a matching image, enabling API exercises to display asset-bundled images.
- **Lazy cache** — `_assetKeysCache` is a `Future<Set<String>>?` that is initialized once and reused, preventing redundant asset scanning.
- **Image URL normalization** — `_normalizeApiImagePath` handles the backend returning relative paths, absolute paths, or full URLs.

---

## 7. Utilities

### 7.1 `AppConstants`

**File:** `lib/utils/app_constants.dart`

A pure static constants class. No instances, no methods.

#### Constant Groups

| Group | Constants |
|---|---|
| App identity | `appName`, `appTagline` |
| Roles | `roleAdmin`, `roleCoach`, `roleTrainee` |
| Fitness levels | `beginnerLevel`, `intermediateLevel`, `advancedLevel` |
| Goals | `goalWeightLoss`, `goalGainMuscle`, `goalImproveFitness` |
| SharedPreferences keys | `keyToken`, `keyUserId`, `keyUserRole`, `keyOnboardingComplete`, `keyProfileSetupComplete`, `keyCachedProfileData`, `keyLocalProfileExtras`, `keyDailyBurnedCaloriesByUser` |
| Hive | `hiveAppBox` |

#### Code Discussion

Centralizing all string keys here prevents typo bugs in key lookups across SharedPreferences and Hive. Any key change only needs to be made in one place.

---

### 7.2 `AppStyles`

**File:** `lib/utils/app_styles.dart`

Defines the global design system used across all screens.

#### `AppColors`

| Name | Hex | Usage |
|---|---|---|
| `primary` | `#87CEEB` | Sky Blue — buttons, active states, focus borders |
| `secondary` | `#00CED1` | Dark Turquoise — secondary accents |
| `accent` | `#FFB74D` | Orange — highlights |
| `textPrimary` | `#000000` | Main text |
| `textSecondary` | `#757575` | Subtitles, hints |
| `background` | `#F5F5F5` | Screen backgrounds, input fills |
| `error` | `#FF5252` | Validation errors, snackbars |
| `success` | `#4CAF50` | Success indicators |
| `backgroundGradient` | Blue → White | Top-to-bottom gradient for auth screens |

#### `AppTextStyles`

| Style | Font Size | Weight | Usage |
|---|---|---|---|
| `heading1` | 32px | 900 | App title on splash |
| `heading2` | 24px | bold | Screen titles |
| `heading3` | 20px | bold | Section headers |
| `bodyLarge` | 16px | normal | Main body text |
| `bodyMedium` | 14px | normal | Secondary text |
| `bodySmall` | 12px | normal | Captions, sub-labels |
| `button` | 16px | bold | Button labels (white) |

---

## 8. Widgets

### 8.1 `CustomButton`

**File:** `lib/widgets/custom_button.dart`

A reusable, full-width `ElevatedButton` wrapper with a built-in loading state.

#### Props

| Prop | Type | Default | Description |
|---|---|---|---|
| `text` | `String` | required | Button label |
| `onPressed` | `VoidCallback` | required | Tap handler |
| `isLoading` | `bool` | `false` | Shows spinner, disables button |
| `backgroundColor` | `Color?` | `AppColors.primary` | Override background |
| `textColor` | `Color?` | `AppColors.white` | Override text color |
| `width` | `double?` | `double.infinity` | Fixed width |
| `height` | `double` | `56` | Button height |

#### Code Discussion

When `isLoading` is `true`, `onPressed` is passed as `null` to `ElevatedButton`, which Flutter uses to disable the button automatically. The spinner is a fixed 24×24 `CircularProgressIndicator` centered in the button — no layout shift.

---

### 8.2 `CustomTextField`

**File:** `lib/widgets/custom_text_field.dart`

A reusable `TextFormField` with a label, consistent styling, and a built-in password visibility toggle.

#### Props

| Prop           | Type                         | Default  | Description                       |
|----------------|------------------------------|----------|-----------------------------------|
| `label`        | `String`                     | required | Label above the field             |
| `hintText`     | `String?`                    | —        | Placeholder text                  |
| `controller`   | `TextEditingController`      | required | Input controller                  |
| `isPassword`   | `bool`                       | `false`  | Enables obscure text + eye toggle |
| `keyboardType` | `TextInputType`              | `text`.  | Input keyboard type               |
| `validator`    | `String? Function(String?)?` | —        | Form validation                   |
| `suffixIcon`   | `Widget?`                    | —        | Custom trailing icon              |
| `enabled`      | `bool`                       | `true`.  | Disables editing                  |
| `maxLines`     | `int`                        | `1`      | For multi-line fields             |

#### Code Discussion

The component is a `StatefulWidget` solely to manage `_obscureText` toggle state — demonstrating the single-responsibility principle. The `isPassword` and `suffixIcon` props are mutually exclusive in rendering: when `isPassword` is true, the eye icon takes priority and `suffixIcon` is ignored.

---

## 9. Screens

### 9.1 `SplashScreen`

**File:** `lib/screens/splash_screen.dart`

**Type:** `StatefulWidget`

Displayed for 3 seconds on cold launch. Handles auth-aware routing.

#### Routing Logic

```
onboardingComplete == false  →  /onboarding
token != null                →  /home
else                         →  /login
```

#### UI

- Full-screen gradient background (`AppColors.backgroundGradient`).
- Centered "TRAINING UP" branding with `primary` color accent on "UP".
- `CircularProgressIndicator` pinned to the bottom.

---

### 9.2 `OnboardingScreen`

**File:** `lib/screens/onboarding_screen.dart`

**Type:** `StatefulWidget`

A multi-page swipe walkthrough shown on first launch. Uses `smooth_page_indicator` for page dots.

After completion, sets `keyOnboardingComplete = true` in SharedPreferences and navigates to `/login`.

---

### 9.3 `LoginScreen`

**File:** `lib/screens/login_screen.dart`

**Type:** `StatefulWidget`

#### State

| Variable              | Type                    | Description                      |
|-----------------------|-------------------------|----------------------------------|
| `_formKey`            | `GlobalKey<FormState>`  | Form validation key              |
| `_emailController`.   | `TextEditingController` | Username input (labeled "Email") |
| `_passwordController` | `TextEditingController` | Password input                   |
| `_isLoading`          | `bool`                  | Button loading state             |

#### Flow

1. User fills in username + password.
2. `_login()` validates the form, calls `ApiService.login()`.
3. On success → `pushReplacementNamed('/home')`.
4. On failure → `SnackBar` with error message in `AppColors.error`.

#### Code Discussion

> ⚠️ The field is labeled "Email address" in the UI but passes `_emailController.text` as the `username` parameter. This is intentional — the backend uses username for login, but the UX label says "Email" for user familiarity. The user can enter either their username or email depending on the backend's accept policy.

---

### 9.4 `RegisterScreen`

**File:** `lib/screens/register_screen.dart`

**Type:** `StatefulWidget`

Multi-field registration form.

#### Collected Fields

`username`, `fullName`, `phone` (optional), `email`, `password`, `confirmPassword`, `role` (dropdown: trainee / coach)

#### Validation

- Username: non-empty, min 3 chars.
- Password confirm: must match password.
- Standard non-empty checks on all required fields.

#### Flow

1. Validates form.
2. Calls `ApiService.register(...)`.
3. On success → `pushNamedAndRemoveUntil('/profile-setup', ...)` (clears back stack).
4. On failure → error `SnackBar`.

---

### 9.5 `ForgotPasswordScreen`

**File:** `lib/screens/forgot_password_screen.dart`

**Type:** `StatefulWidget`

Two-step password reset flow:
1. Enter email → calls `ApiService.forgotPassword()` → shows success.
2. User receives OTP code by email, enters new password + code → calls `ApiService.resetPassword()`.

---

### 9.6 `VerifyEmailScreen`

**File:** `lib/screens/verify_email_screen.dart`

**Type:** `StatefulWidget`

Receives the user's email (passed as a route argument or via constructor) and a 6-digit OTP. Calls `ApiService.verifyEmail()`.

On success → navigates to `/profile-setup`.

---

### 9.7 `ProfileSetupScreen`

**File:** `lib/screens/profile_setup_screen.dart`

**Type:** `StatefulWidget` + `ChangeNotifierProvider`

A **multi-step wizard** (6 pages) using `PageController`.

#### `ProfileSetupProvider` (ChangeNotifier)

Lives at the top of the screen widget tree via `ChangeNotifierProvider`. Exposes setter methods that update the underlying `ProfileSetupModel` and call `notifyListeners()`.

| Setter                             | Updates                       |
|------------------------------------|-------------------------------|
| `setAge(int)`                      | `age`                         |
| `setCurrentWeight(double, String)` | `currentWeight`, `weightUnit` |
| `setGoalWeight(double, String)`.   | `goalWeight`, `weightUnit`    |
| `setHeight(double, String)`.       | `height`, `heightUnit`        |
| `setFitnessLevel(String)`          | `fitnessLevel`                |
| `setGoal(String)`                  | `goal`                        |

#### Pages

1. Age selection
2. Current weight (kg / lbs toggle)
3. Goal weight (kg / lbs toggle)
4. Height (cm / feet toggle)
5. Fitness level (Beginner / Intermediate / Advanced)
6. Goal (Weight Loss / Gain Muscle / Improve Fitness)

Each page calls the corresponding provider setter. `_nextStep()` advances the `PageController`. After the last page, navigates to `/final-onboarding`.

#### Code Discussion

This is the **only screen using Provider** in the project. The `ProfileSetupProvider` is scoped locally (not app-wide), which is the correct usage — it only needs to live for the duration of the wizard. All other screens use `setState` directly.

---

### 9.8 `FinalOnboardingScreen`

**File:** `lib/screens/final_onboarding_screen.dart`

**Type:** `StatefulWidget`

A "you're all set" landing page shown after profile setup. Sends the collected `ProfileSetupModel` data to `ApiService.setupProfile()`, sets `keyProfileSetupComplete = true`, and navigates to `/home`.

---

### 9.9 `HomeScreen`

**File:** `lib/screens/home_screen.dart`  
**Size:** ~1 466 lines — the largest screen in the project.

**Type:** `StatefulWidget`

The main hub of the app. Implements bottom navigation with 4 tabs and hosts multiple embedded sub-screens.

#### State

| Variable              | Type                         | Description                   |
|-----------------------|------------------------------|-------------------------------|
| `_selectedIndex`      | `int`                        | Active bottom nav tab (0–3)   |
| `_userName`           | `String`                     | First name shown in greeting  |
| `_profileData`        | `Map<String, dynamic>`       | Full profile from API / cache |
| `_exercises`          | `List<Map<String, dynamic>>` | All loaded exercises          |
| `_isLoadingExercises` | `bool`                       | Exercise loading state.       |
| `_selectedCategory`   | `String?`                    | Active category filter        |
| `_selectedLevel`      | `String?`                    | Active level filter           |
| `_selectedGoal`       | `String`                     | Active goal tab               |
| `_scaffoldKey`        | `GlobalKey<ScaffoldState>`.  | For drawer access             |

#### Bottom Navigation Tabs

| Index | Content                                             |
|-------|-----------------------------------------------------|
| 0     | Home feed (exercise cards, categories, goal filter) |
| 1     | `FullExerciseScreen` (embedded)                     |
| 2.    | `MealPlansScreen` (embedded)                        |
| 3     | `ProfileScreen` (embedded)                          |

#### Home Tab Features

- **Greeting header** — "Hello, {firstName}!" with profile avatar / initials.
- **Goal selector** — horizontal chips: Loose Weight, Gain Weight, Body Building, Health.
- **Category bar** — 7 horizontal icon+label chips.
- **Exercise cards** — loaded in batches of 10 with progressive UI updates.
- **Drawer** — links to Dashboard, My Progress, Edit Profile, App Settings.

#### Exercise Loading

```dart
// Progressive batch rendering for perceived performance
const batchSize = 10;
for (var i = 0; i < keys.length; i++) {
  final item = await service.loadExerciseByKey(key);
  if (i % batchSize == 0) {
    setState(() { _exercises = List.from(accumulated); });
    await Future.delayed(const Duration(milliseconds: 8)); // yield to UI
  }
}
```

#### Code Discussion

- **Dual profile loading** — `_loadLocalUserProfile()` runs first (instant, from Hive) then `_loadUserProfile()` fetches from the API and updates the UI. This gives perceived zero-loading time while keeping data fresh.
- **Size concern** — at ~1 466 lines, `HomeScreen` is doing too much. A future refactor should extract the drawer, home tab content, and category bar into separate widget classes.

---

### 9.10 `ExerciseDetailScreen`

**File:** `lib/screens/exercise_detail_screen.dart`  
**Size:** ~1 382 lines

**Type:** `StatefulWidget`

Displays full detail for a single exercise and handles workout session initiation.

#### Props

| Prop                 | Type                    | Description                          |
|----------------------|-------------------------|--------------------------------------|
| `data`               | `Map<String, dynamic>?` | Pre-loaded exercise data             |
| `path`               | `String?`               | Asset path to load data from         |
| `imagePath`          | `String?`               | Resolved image path                  |
| `fromInProgressCard` | `bool`                  | Whether opened from in-progress list |
| `inProgressCount`    | `int`                   | Count of other in-progress exercises |

#### Key Features

- **Start Workout** — confirms with a bottom sheet, then calls `ApiService.markExercise()`. Calculates estimated calorie burn based on user weight × MET × duration, stores in Hive under the date key.
- **Duration picker** — editable text field for custom workout minutes.
- **Related exercises** — lists exercises in the same category below the main detail.
- **Image rendering** — handles both asset paths and HTTP URLs with fallback to icon.
- **Calorie burn formula:**

$$\text{calories} = \text{MET} \times \text{weightKg} \times \frac{\text{durationMin}}{60}$$

#### Code Discussion

- The `_exerciseId` getter checks `_data?['id']`. Asset-bundled exercises have no server ID (null), while API exercises have numeric IDs. The `markExercise` API accepts `null` gracefully, but calorie tracking still works locally regardless.
- Calorie data is stored in Hive at `keyDailyBurnedCaloriesByUser → {userKey} → {YYYY-MM-DD} → int`. This per-user, per-date structure allows multi-user support on the same device.

---

### 9.11 `FullExerciseScreen`

**File:** `lib/screens/full_exercise_screen.dart`  
**Size:** ~348 lines

**Type:** `StatefulWidget`

A tabbed exercise browser showing all exercises organized by category.

#### Tabs

`Cardio | Olympic Weightlifting | Plyometrics | Powerlifting | Strength | Stretching | Strongman`

Tapping a card navigates to `ExerciseDetailScreen`.

#### Props

| Prop       | Type   | Default | Description                                                     |
|------------|--------|---------|-----------------------------------------------------------------|
| `embedded` | `bool` | `false` | When true, hides its own Scaffold (used inside HomeScreen tabs) |

---

### 9.12 `FiltersPlanScreen`

**File:** `lib/screens/filters_plan_screen.dart`  
**Size:** ~244 lines

**Type:** `StatefulWidget`

A filter selection sheet. Returns a `FiltersPlanResult` object to the caller via `Navigator.pop(result)`.

#### Filter Options

| Filter        | Options                                                       |
|---------------|---------------------------------------------------------------|
| Category      | All, Cardio, Warm-Up, Running, Yoga, Stretching, Arms, Boxing |
| Exercise Type | All, Biceps, Back, Shoulders, Triceps, Legs                   |
| Level         | Beginner, Average, Hard                                       |
| Meal.         | Breakfast, Lunch, Dinner                                      |
| Time          | 10–15 Min, 15–30 Min, 30–45 Min                               |

#### `FiltersPlanResult`

```dart
class FiltersPlanResult {
  final String? category;
  final String? level;
  final String? meal;
  final String? time;
  final String? exercise;
}
```

---

### 9.13 `DashboardScreen`

**File:** `lib/screens/dashboard_screen.dart`  
**Size:** ~628 lines

**Type:** `StatefulWidget`

A personal fitness statistics dashboard.

#### State

| Variable        | Type                   | Description                      |
|-----------------|------------------------|----------------------------------|
| `_period`.      | `String`               | `'Today'` / `'Week'` / `'Month'` |
| `_profile`      | `Map<String, dynamic>` | User profile data                |
| `_summary`.     | `Map<String, dynamic>` | Exercise summary from API        |
| `_burnedByDate` | `Map<String, int>`     | Calorie history from Hive        |
| `_isLoading`.   | `bool`                 | Loading state                    |

#### Metric Cards (2×2 Grid)

| Card                | Value                                        | Unit.  | Ring Color |
|---------------------|----------------------------------------------|--------|------------|
| Weight              | `profile.weight`                             | kg.    | Sky Blue.  |
| Height              | `profile.height`                             | cm.    | Sky Blue.  |
| Exercise Completion | `completed / (completed + inProgress) * 100` | % done.| Sky Blue.  |
| Calories Burned.    | Period sum from Hive                         | kcal.  | Sky Blue.  |

Additional stats: **Active Days**, **Total Exercises**, period selector chips.

#### Period Calculation Logic

```dart
// Week: Monday–Sunday of current week
// Month: 1st – last day of current calendar month
// Today: current date only
```

Calorie data is pulled from Hive by date key (`YYYY-MM-DD`) and summed for the selected period.

#### Code Discussion

- `_safeProgress(value, max)` clamps progress values to `[0.0, 1.0]` to prevent `CircularProgressIndicator` crashes from out-of-range values.
- Hive data is loaded per-user: `keyDailyBurnedCaloriesByUser → username → dateKey`. If profile load fails, it falls back to the Hive cache, ensuring the dashboard still works offline.

---

### 9.14 `MyProgressScreen`

**File:** `lib/screens/my_progress_screen.dart`  
**Size:** ~760 lines

**Type:** `StatefulWidget`

A detailed progress tracker showing exercise history and calorie burn trends.

#### Features

- Period tabs (Today / Week / Month) — same logic as DashboardScreen.
- Exercise completion rate chart.
- Calorie burn bar chart rendered manually with `CustomPaint` or `Container` height proportions.
- In-progress vs completed exercise breakdown.
- Active days counter.

#### Code Discussion

The calorie and exercise data loading logic is **duplicated** from `DashboardScreen` (`_loadBurnedCaloriesFromHive`, `_mapFromRaw`, `_dateKey`). This is a refactoring opportunity — these helpers should be extracted to a shared utility or mixin.

---

### 9.15 `MealPlansScreen`

**File:** `lib/screens/meal_plans_screen.dart`  
**Size:** ~471 lines

**Type:** `StatefulWidget`

Fetches and displays meal recipes from the API.

#### State

| Variable            | Type                         | Description                     |
|---------------------|------------------------------|---------------------------------|
| `_recipes`          | `List<Map<String, dynamic>>` | All fetched recipes             |
| `_selectedCategory` | `String`                     | Active filter (`'All'` default) |
| `_isLoading`        | `bool`                       | Loading state                   |

#### `_normalizeRecipe` method

Normalizes inconsistent API field names into a standard schema:
- `Cuisine` ← `name` / `title` / `cuisine`
- `Category` ← `category`
- `Cooking_Time` ← `cooking_time` / `time`
- `Difficulty` ← `difficulty` / `level`
- `Ingredients` ← `ingredients` / `description`
- `cook_steps` ← `Cook_Steps` (List\<String\>)

#### Recipe Detail Dialog

Opens a full-screen `Dialog` with ingredients, cooking method, and step-by-step cooking instructions.

#### Props

| Prop       | Type   | Default | Description                                |
|------------|--------|---------|--------------------------------------------|
| `embedded` | `bool` | `false` | Hides Scaffold when used inside HomeScreen |

---

### 9.16 `ProfileScreen`

**File:** `lib/screens/profile_screen.dart`  
**Size:** ~1 094 lines

**Type:** `StatefulWidget` with `WidgetsBindingObserver`

The user's profile hub, displaying personal stats, exercise history, and an in-progress exercise list.

#### Props

| Prop | Type | Description |
|-----------------|------------------------|-------------------------------------------|
| `profileData`   | `Map<String, dynamic>` | Initial data (overridden by fetched data) |
| `fallbackName`  | `String`               | Name shown if profile is empty            |
| `onEditProfile` | `VoidCallback?`        | Callback when edit is tapped              |

#### Features

- Reads from both the passed `profileData` prop and Hive cache, merging them.
- Listens to `AppLifecycleState.resumed` to refresh data when the app returns to foreground.
- Shows: BMI calculation, today's calorie burn, exercise summary (completed / in-progress / total).
- Lists in-progress exercises with navigation to `ExerciseDetailScreen`.
- Avatar: first letter of full name in a colored circle.

#### `_effectiveProfileData` getter

```dart
Map<String, dynamic> get _effectiveProfileData => {
  ..._cachedProfileData,
  ...widget.profileData, // widget data wins
};
```

#### Code Discussion

Using `WidgetsBindingObserver` for lifecycle events is the correct Flutter pattern for refreshing data when the user returns from another screen or app. This avoids the complexity of a global state manager for this use case.

---

### 9.17 `EditProfileScreen`

**File:** `lib/screens/edit_profile_screen.dart`  
**Size:** ~485 lines

**Type:** `StatefulWidget`

Editable form for updating profile fields.

#### Editable Fields

`fullName`, `phone`, `email`, `weight`, `targetWeight`, `height`, `age`, `weightUnit` (KG/LBS), `heightUnit` (CM/FEET), `gender`

#### Data Loading Priority

1. Widget `initialData` prop (passed from caller).
2. Hive cache (`keyCachedProfileData`) — loaded in `initState`.

On save:
1. Calls `ApiService.updateProfile(...)`.
2. On success, updates Hive cache and pops back.
3. Shows `SnackBar` on failure.

---

### 9.18 `AppSettingsScreen`

**File:** `lib/screens/app_settings_screen.dart`  
**Size:** ~194 lines

**Type:** `StatefulWidget`

App-level preferences screen.

#### Settings

| Setting         | Type       | State                                         |
|-----------------|------------|-----------------------------------------------|
| Change Password | Navigation | → `ForgotPasswordScreen`                      |
| Dark Mode       | `Switch`   | `_darkMode` bool (UI only, not persisted yet) |
| Language        | Dropdown   | `_language` string (UI only)                  |

#### Code Discussion

> ⚠️ **Known limitation:** Dark mode and language selection are currently local state only — they reset on restart. Persistence via SharedPreferences or Hive, and actual theme switching via a `ThemeProvider`, should be implemented as follow-up work.

---

## 10. Data Flow & Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        UI Layer                         │
│  Screens  ←→  Widgets  ←→  Provider (ProfileSetup only) │
└────────────────────────┬────────────────────────────────┘
                         │ calls
┌────────────────────────▼────────────────────────────────┐
│                    Service Layer                        │
│        ApiService          ExerciseService              │
│     (HTTP + Token)     (Assets + API merge)             │
└──────────┬─────────────────────────┬────────────────────┘
           │                         │
    ┌──────▼──────┐          ┌───────▼───────┐
    │  Backend    │          │  Asset Bundle │
    │  REST API   │          │  JSON Files   │
    └─────────────┘          └───────────────┘
           │
    ┌──────▼──────────────────┐
    │   Local Storage         │
    │  SharedPreferences      │  ← token, flags, small strings
    │  Hive (app_cache_box)   │  ← profile cache, calorie history
    └─────────────────────────┘
```

---

## 11. Local Storage Strategy

| Store                | Key                             | Data                              | Written by                        |
|----------------------|---------------------------------|-----------------------------------|-----------------------------------|
| SharedPreferences    | `auth_token`                    | JWT/DRF token string              | `ApiService.saveToken()`          |
| SharedPreferences    | `onboarding_complete`           | bool                              | `OnboardingScreen`                |
| SharedPreferences    | `profile_setup_complete`        | bool                              | `FinalOnboardingScreen`           |
| Hive `app_cache_box` | `cached_profile_data`           | `Map<String, dynamic>`            | `HomeScreen`, `EditProfileScreen` |
| Hive `app_cache_box` | `daily_burned_calories_by_user` | `Map<userKey, Map<dateKey, int>>` | `ExerciseDetailScreen`            |

### Hive Calorie Data Schema

```
daily_burned_calories_by_user:
  "username_or_email":
    "2026-04-01": 450
    "2026-04-02": 230
    "2026-04-06": 610
```

This per-user bucketing supports multiple accounts on the same device.

---

## 12. API Endpoint Summary

**Base URL:** `https://trainingg.pythonanywhere.com/api`

|Method| Path                     |Auth | Used By                                                |
|------|--------------------------|-----|--------------------------------------------------------|
| POST | `/register/`             | No  | `RegisterScreen`                                       |
| POST | `/verify-email/`         | No  | `VerifyEmailScreen`                                    |
| POST | `/login/`                | No  | `LoginScreen`                                          |
| POST | `/forgot-password/`      | No  | `ForgotPasswordScreen`                                 |
| POST | `/reset-password/`       | No  | `ForgotPasswordScreen`                                 |
| GET  | `/profile/`              | Yes | `HomeScreen`, `DashboardScreen`, `ProfileScreen`       |
| PUT  | `/profile/`              | Yes | `EditProfileScreen`                                    |
| POST | `/profile-setup/`.       | Yes | `FinalOnboardingScreen`                                |
| GET  | `/exercises/`            | Yes | `ExerciseService`                                      |
| GET  | `/exercises/{id}/`       | Yes | `ExerciseService`                                      |
| GET  | `/my-exercises/`         | Yes | `ProfileScreen`                                        |
| GET  | `/my-exercises/summary/` | Yes | `DashboardScreen`, `MyProgressScreen`, `ProfileScreen` |
| POST | `/my-exercises/`         | Yes | `ExerciseDetailScreen`                                 |
| GET  | `/meal-plans/`           | Yes | `MealPlansScreen`                                      |
| GET  | `/meal-plans/{id}/`      | Yes | `MealPlansScreen`                                      |

---

## 13. Navigation Map

```
SplashScreen (/)
    ├── /onboarding  (first launch)
    │       └── /login
    ├── /home        (has token)
    └── /login       (no token)

/login
    ├── /home        (success)
    ├── /register
    └── /forgot-password

/register
    └── /profile-setup  (success, stack cleared)

/profile-setup
    └── /final-onboarding

/final-onboarding
    └── /home  (stack cleared)

/home  (bottom nav hub)
    ├── Tab 0: Home Feed
    │       ├── ExerciseDetailScreen (push)
    │       │       └── (pop back)
    │       ├── FiltersPlanScreen (push, returns FiltersPlanResult)
    │       └── DashboardScreen (drawer push)
    ├── Tab 1: FullExerciseScreen (embedded)
    ├── Tab 2: MealPlansScreen (embedded)
    └── Tab 3: ProfileScreen (embedded)
            ├── EditProfileScreen (push)
            └── ExerciseDetailScreen (push)
    
    Drawer:
        ├── DashboardScreen (push)
        ├── MyProgressScreen (push)
        ├── EditProfileScreen (push)
        └── AppSettingsScreen (push)
```

---

## 14. Code Discussion & Design Decisions

### ✅ Strengths

1. **Consistent API response contract** — `{success, data, error}` pattern in `ApiService` makes error handling uniform and safe throughout all screens.

2. **Offline-first profile** — loading Hive cache first and API second gives instant perceived performance for returning users.

3. **Asset + API exercise merging** — `ExerciseService` cleanly combines offline JSON assets with live API data, with fuzzy image resolution bridging the two sources.

4. **Progressive exercise loading** — batching exercise loads with `Future.delayed(8ms)` yields the UI thread between batches, preventing jank on large datasets.

5. **Local scoped Provider** — using `ChangeNotifierProvider` only for the profile setup wizard is the correct narrow-scope usage, avoiding global state bloat.

6. **Per-user Hive storage** — calorie data is keyed by username, allowing multiple accounts on the same device without data leakage.

---

### ⚠️ Areas for Improvement

1. **`HomeScreen` size (~1 466 lines)** — should be decomposed into: `HomeTabContent`, `HomeDrawer`, `ExerciseCategoryBar`, `GoalSelector`, `ExerciseCardList`.

2. **Duplicated utility methods** — `_mapFromRaw`, `_dateKey`, `_loadBurnedCaloriesFromHive`, and `_currentUserStorageKey` appear in `DashboardScreen`, `MyProgressScreen`, `ProfileScreen`, and `ExerciseDetailScreen`. Extract to a shared `CalorieStorage` service or mixin.

3. **AppSettingsScreen state not persisted** — dark mode and language are UI-only. Add theme and locale persistence + a `ThemeProvider`.

4. **No error boundary for Hive failures** — most `catch (_)` blocks silently swallow Hive errors. Consider adding structured error logging.

5. **`initialRoute` vs actual flow** — `main.dart` sets `initialRoute: '/home'` but the intent may be `/` (SplashScreen). Confirm and align.

6. **No unit tests for services** — `ApiService` and `ExerciseService` have no test coverage. Mocking `http.Client` and `rootBundle` would be straightforward.

7. **`LoginScreen` label mismatch** — field labeled "Email address" sends value as `username`. Add inline documentation or rename to match.

---

*End of Documentation*
