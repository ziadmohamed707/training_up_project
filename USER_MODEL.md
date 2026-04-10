# User Model & Profile Management

## API User Model

The user model from the backend API includes all these fields:

```json
{
    "username": "ziad",
    "email": "ziadm707.zm@gmail.com",
    "phone": "01024375442",
    "role": "trainee",
    "full_name": "ziad Mohamed",
    "profile": null,
    "age": null,
    "weight": null,
    "height": null,
    "goal": null,
    "bmi": null
}
```

## Field Descriptions

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `username` | string | Unique username | "ziad" |
| `email` | string | User email address | "ziadm707.zm@gmail.com" |
| `phone` | string | Phone number | "01024375442" |
| `role` | string | User role (admin, coach, trainee) | "trainee" |
| `full_name` | string | Full name of user | "ziad Mohamed" |
| `profile` | object/null | Profile metadata | null |
| `age` | integer/null | User age in years | null |
| `weight` | number/null | Current weight (kg) | null |
| `height` | number/null | Height (cm) | null |
| `goal` | string/null | Fitness goal (weight_loss, gain_muscle, etc.) | null |
| `bmi` | number/null | Body Mass Index (calculated) | null |

---

## How Profile Data Flows in the App

### 1. **On Login**
- User enters username/email and password
- API returns user object with all fields
- Token saved to local storage (`SharedPreferences`)

### 2. **On Home Screen Load**
- App calls `GET /api/profile/` with saved token
- API returns current user profile data
- Data stored in `_profileData` state variable
- Data also cached to Hive for offline access

### 3. **On Profile Screen View**
```
Profile Screen
  ├─ Displays: full_name, age, weight, height, role
  ├─ Shows: membership status based on role
  ├─ Calculates: BMI, macronutrient goals
  └─ Allows: Edit button to update fields
```

### 4. **On Edit Profile**
- User can edit: full_name, phone, email, age, weight, height
- Clicking "Save" calls `PUT /api/profile/` with updated data
- API validates and stores changes
- App updates local cache and displays updated profile

---

## API Endpoints for Profile

### Get Profile
```
GET /api/profile/
Authorization: Token {user_token}

Response (200):
{
    "username": "ziad",
    "email": "ziadm707.zm@gmail.com",
    "phone": "01024375442",
    "role": "trainee",
    "full_name": "ziad Mohamed",
    "profile": null,
    "age": null,
    "weight": null,
    "height": null,
    "goal": null,
    "bmi": null
}
```

### Update Profile
```
PUT /api/profile/
Authorization: Token {user_token}
Content-Type: application/json

Request body (send only fields you want to update):
{
    "phone": "01024375442",
    "email": "ziadm707.zm@gmail.com",
    "full_name": "ziad Mohamed",
    "age": 25,
    "weight": 75,
    "height": 180,
    "goal": "gain_muscle"
}

Response (200):
{
    "message": "Profile updated successfully"
}
```

---

## Code Implementation

### Profile Fetching (ProfileScreen)
**File**: `lib/screens/profile_screen.dart`
```dart
Future<void> _fetchProfileFromAPI() async {
  try {
    final result = await _apiService.getProfile();
    if (result['success'] && result['data'] != null) {
      final profileData = Map<String, dynamic>.from(result['data']);
      setState(() {
        _cachedProfileData = profileData;
      });
      // Cache to Hive
      await _appBox?.put(
        AppConstants.keyCachedProfileData,
        jsonEncode(profileData),
      );
    }
  } catch (_) {
    // Silently fail, use cached data
  }
}
```

### Profile Display Helpers
```dart
String get _fullName {
  final raw = (_effectiveProfileData['full_name'] ?? '').toString().trim();
  if (raw.isNotEmpty) return raw;
  return widget.fallbackName;
}

String get _membershipLabel {
  final role = (_effectiveProfileData['role'] ?? '').toString().toLowerCase();
  switch (role) {
    case 'coach': return 'Coach member';
    case 'admin': return 'Admin member';
    case 'trainee': return 'Basic member';
    default: return 'Basic member';
  }
}

String _metricValue(String key, String fallback, String suffix) {
  final value = _effectiveProfileData[key];
  if (value is num) {
    final normalized = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$normalized$suffix';
  }
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return '$fallback$suffix';
  return raw.endsWith(suffix) ? raw : '$raw$suffix';
}
```

### Profile Update (EditProfileScreen)
**File**: `lib/screens/edit_profile_screen.dart`
```dart
Future<void> _save() async {
  setState(() {
    _isSaving = true;
  });

  try {
    final api = ApiService();
    final age = int.tryParse(_ageController.text) ?? 21;
    final weight = num.tryParse(_weightController.text) ?? 55;
    final height = num.tryParse(_heightController.text) ?? 170;
    
    // Update profile via API
    await api.updateProfile(
      phone: _phoneController.text,
      email: _emailController.text,
      fullName: _fullNameController.text,
      age: age,
      weight: weight,
      height: height,
    );

    // Update local cache
    final updatedData = {
      ...widget.initialData,
      'full_name': _fullNameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'age': _ageController.text,
      'current_weight': _weightController.text,
      'height': _heightController.text,
    };

    final box = Hive.box(AppConstants.hiveAppBox);
    await box.put(
      AppConstants.keyCachedProfileData,
      updatedData,
    );

    Navigator.of(context).pop(updatedData);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  } finally {
    setState(() { _isSaving = false; });
  }
}
```

---

## Storage & Caching

### Where Data is Stored

1. **In Memory** - `_cachedProfileData` in ProfileScreen state
2. **SharedPreferences** - Auth token only (`auth_token`)
3. **Hive Database** - Full profile data cached locally
   - Key: `cached_profile_data`
   - Value: JSON-encoded user profile

### Offline Access

Profile data is cached in Hive, so users can:
- View their profile when offline
- See last-known data (name, age, weight, etc.)
- Attempts to update offline will fail (requires internet)

---

## Role-Based Features

The `role` field determines user capabilities:

| Role | Capabilities |
|------|--------------|
| **trainee** | View exercises, log progress, view own profile |
| **coach** | Create exercises, manage trainees, view trainee progress |
| **admin** | Full system access, manage all users and content |

---

## Fields Not Yet Used in UI

- `profile` - Reserved for profile picture/metadata (API returns null)
- `bmi` - Calculated by API, displayed in profile but not editable
- `goal` - Currently not in edit form but can be added

---

## Future Enhancements

- [ ] Add goal selector to edit profile screen
- [ ] Add profile picture upload
- [ ] Add password change option
- [ ] Add two-factor authentication
- [ ] Add profile completion progress indicator
- [ ] Show BMI health status (underweight, normal, overweight, obese)

