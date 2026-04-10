# Training Up - Flutter Fitness App

A comprehensive fitness and training mobile application built with Flutter, integrating with the TrainUp API.

## Features

### Authentication
- User registration with email verification
- Login with username/password
- Social login options (Google & Facebook) - UI ready
- Forgot password functionality
- JWT token-based authentication

### Onboarding
- Beautiful splash screen with app branding
- 3-screen onboarding flow introducing app features
- Smooth page indicators and navigation

### Profile Setup (6-Step Process)
1. Age selection with scroll wheel
2. Current weight input (KG/LBS)
3. Goal weight input (KG/LBS)
4. Height input (CM/FEET)
5. Fitness level selection (Beginner/Intermediate/Advanced)
6. Goal selection (Weight loss/Gain muscle/Improve fitness)

### Home Screen
- Personalized greeting with user name
- Search functionality
- Featured exercise cards
- Goal selector (Loose Weight, Gain Weight, Body Building, Health)
- Category browsing (Gym, Cardio, Stretch, Full Body)
- Popular exercises listing
- Meal plans with calorie information
- Additional exercises recommendations
- Bottom navigation bar

### Navigation Drawer
- User profile display
- Dashboard
- My Progress
- Training
- Categories
- Notifications
- My Favorites
- App Settings
- Contact Support
- Sign Out

## API Integration

Base URL: `https://trainingg.pythonanywhere.com/api/`

### Implemented Endpoints
- `POST /register/` - User registration
- `POST /verify-email/` - Email verification
- `POST /login/` - User login
- `GET /profile/` - Get user profile
- `PUT /profile/` - Update user profile
- `POST /change-password/` - Change password
- `POST /logout/` - User logout
- `DELETE /delete-account/` - Delete account
- `GET /my-role/` - Get user role

## Project Structure

```
lib/
├── models/
│   ├── user_model.dart
│   └── profile_setup_model.dart
├── services/
│   └── api_service.dart
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── forgot_password_screen.dart
│   ├── verify_email_screen.dart
│   ├── profile_setup_screen.dart
│   ├── final_onboarding_screen.dart
│   └── home_screen.dart
├── widgets/
│   ├── custom_button.dart
│   └── custom_text_field.dart
├── utils/
│   ├── app_styles.dart
│   └── app_constants.dart
└── main.dart
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.2.0                    # HTTP requests
  provider: ^6.1.1                # State management
  shared_preferences: ^2.2.2      # Local storage
  smooth_page_indicator: ^1.1.0   # Page indicators
  font_awesome_flutter: ^10.7.0   # Icons
```

## Setup & Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Screen Flow

```
Splash Screen
    ↓
Onboarding (3 screens) → Login Screen → Home Screen
                            ↓
                         Register Screen → Verify Email → Profile Setup (6 steps) → Final Onboarding → Home Screen
                            ↓
                         Forgot Password
```

## API Authentication

The app uses Token Authentication. After successful login or registration:
- Token is stored in SharedPreferences
- Token is automatically included in API request headers: `Authorization: Token <token>`
- Token is cleared on logout

## Color Scheme

- Primary: Sky Blue (#87CEEB)
- Secondary: Dark Turquoise (#00CED1)
- Accent: Orange (#FFB74D)
- Background: Light Gray (#F5F5F5)
- Text Primary: Black (#000000)
- Text Secondary: Gray (#757575)

## User Roles

The app supports three user roles:
- `admin` - Administrator access
- `coach` - Coach/Trainer access
- `trainee` - Regular user access

## Future Enhancements

- [ ] Complete meal plans functionality
- [ ] Exercise details and video playback
- [ ] Progress tracking and analytics
- [ ] Social features (following coaches, sharing progress)
- [ ] In-app messaging
- [ ] Payment integration for premium features
- [ ] Workout timer and tracking
- [ ] Push notifications
- [ ] Google & Facebook authentication integration
- [ ] Dark mode support

## Notes

- The app uses a gradient background throughout for consistency
- All screens are portrait-only
- Form validation is implemented for all input fields
- Error handling with user-friendly messages
- Smooth animations and transitions between screens

## License

This project is private and not for distribution.
