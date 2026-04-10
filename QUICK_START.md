# Training Up App - Quick Start Guide

## Testing the App

### Test Credentials
You can test the app with these example credentials:

**Registration:**
- Full Name: Test User
- Phone: +1234567890
- Email: test@example.com
- Password: test123

**Login:**
- Username: test@example.com (or the username you registered with)
- Password: test123

## App Navigation Flow

### First Time Users:
1. **Splash Screen** (3 seconds)
2. **Onboarding** (3 screens) - Can skip
3. **Login/Register**
4. **Email Verification** - Enter 4-digit code
5. **Profile Setup** (6 steps) - Can skip
6. **Final Onboarding**
7. **Home Screen**

### Returning Users:
1. **Splash Screen**
2. **Login Screen**
3. **Home Screen**

## Key Features to Test

### Authentication Flow
1. **Registration:**
   - Go to Register screen
   - Fill in all fields
   - Click "CREATE ACCOUNT"
   - You'll receive a verification code via email
   - Enter the 4-digit code
   - Complete profile setup

2. **Login:**
   - Enter username/email and password
   - Click "LOGIN"
   - Redirects to home screen

3. **Forgot Password:**
   - Click "Forgot Password?" on login screen
   - Enter email
   - Click "RESET PASSWORD"

### Profile Setup
1. **Age:** Scroll to select age (18-100)
2. **Current Weight:** Toggle LBS/KG, enter weight
3. **Goal Weight:** Toggle LBS/KG, enter goal
4. **Height:** Toggle FEET/CM, enter height
5. **Fitness Level:** Select Beginner/Intermediate/Advanced
6. **Goal:** Select Weight loss/Gain muscle/Improve fitness

### Home Screen Features
- **Search Bar:** Tap to search (UI only)
- **Featured Card:** "Start Exercise" button
- **Goal Selector:** Tap chips to select goal
- **Categories:** Tap category icons
- **Popular Exercises:** View exercise cards with details
- **Meal Plans:** Scroll horizontally through meal cards
- **Additional Exercises:** View exercise list
- **Bottom Navigation:** Navigate between sections
- **Drawer Menu:** Open from top-left icon
  - View profile
  - Access settings
  - Sign out

## API Integration Status

### ✅ Fully Integrated
- User Registration
- Email Verification
- User Login
- Get Profile
- Update Profile
- Change Password
- Logout
- Delete Account
- Get User Role

### 🚧 UI Ready (No API Yet)
- Exercises listing
- Meal plans
- Categories
- Search functionality
- Social login (Google/Facebook)

## Common Testing Scenarios

### Scenario 1: New User Registration
```
1. Launch app
2. Wait for splash screen
3. View onboarding or tap "SKIP"
4. Tap "Register!" on login screen
5. Fill registration form
6. Tap "CREATE ACCOUNT"
7. Enter verification code from email
8. Complete 6-step profile setup
9. View home screen
```

### Scenario 2: Existing User Login
```
1. Launch app
2. Wait for splash screen
3. Skip onboarding (if first time)
4. Enter credentials
5. Tap "LOGIN"
6. View home screen
```

### Scenario 3: Password Recovery
```
1. Go to login screen
2. Tap "Forgot Password?"
3. Enter email
4. Tap "RESET PASSWORD"
5. Check email for reset instructions
```

### Scenario 4: Logout
```
1. Open drawer from home screen
2. Scroll to bottom
3. Tap "Sign Out"
4. Confirm logout
5. Redirected to login screen
```

## Design Highlights

### Colors
- **Primary Blue:** Main buttons, highlights
- **Orange:** Featured content, call-to-action
- **Black:** Selected items, primary text
- **Gray:** Inactive items, secondary text
- **White:** Backgrounds, containers

### Typography
- **Headings:** Bold, uppercase for emphasis
- **Body Text:** Regular weight, easy to read
- **Small Text:** For labels and metadata

### Components
- **Rounded Corners:** 12px radius on most containers
- **Shadows:** Subtle elevation on cards
- **Gradients:** Background gradient throughout app
- **Icons:** Font Awesome + Material Icons

## Error Handling

The app includes error handling for:
- Network errors
- Invalid credentials
- Missing required fields
- Email verification failures
- API timeouts

Error messages are displayed as:
- **SnackBars** for temporary messages
- **Inline errors** in form fields
- **Loading indicators** during API calls

## Performance Notes

- Images are placeholder icons (replace with actual images in production)
- API calls include loading states
- Smooth transitions between screens
- Optimized list rendering
- Cached authentication token

## Troubleshooting

### App won't start:
```bash
flutter clean
flutter pub get
flutter run
```

### API not connecting:
- Check internet connection
- Verify API base URL: `https://trainingg.pythonanywhere.com/api/`
- Check API server status

### Login fails:
- Verify credentials
- Ensure email is verified
- Check API response in logs

### Verification code not received:
- Check spam folder
- Ensure email is correct
- Try resend code (if implemented)

## Development Commands

```bash
# Run app
flutter run

# Run on specific device
flutter run -d <device-id>

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Run tests
flutter test

# Check for errors
flutter analyze

# Format code
flutter format .
```

## Notes for Developers

1. **Token Management:** Token is stored in SharedPreferences and auto-included in API headers
2. **Navigation:** Uses named routes for easy navigation
3. **State Management:** Provider is included but not yet fully implemented
4. **Validation:** Form validation on all input fields
5. **Responsive:** Works on various screen sizes (portrait only)

## Next Steps

After testing the basic flow:
1. Add actual exercise data
2. Implement search functionality
3. Add workout tracking
4. Integrate social login
5. Add push notifications
6. Implement meal planning
7. Add progress tracking charts

---

**Need Help?**
- Check the API documentation
- Review the code comments
- Test on multiple devices
- Report issues with screenshots and logs
