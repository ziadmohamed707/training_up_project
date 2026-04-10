# API Token Flow & Local Storage Documentation

## Overview
The app automatically saves and manages user authentication tokens in local storage (SharedPreferences). This allows persistent login and seamless API access across app sessions.

---

## 1. Login Flow → Token Saved

### Step 1: User Logs In
**File**: `lib/screens/login_screen.dart`
```dart
Future<void> _login() async {
  final result = await _apiService.login(
    username: _emailController.text.trim(),
    password: _passwordController.text,
  );
  
  if (result['success']) {
    Navigator.of(context).pushReplacementNamed('/home');
  }
}
```

### Step 2: API Returns Token
**File**: `lib/services/api_service.dart` → `login()` method
```dart
Future<Map<String, dynamic>> login({
  required String username,
  required String password,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/login/'),
    body: jsonEncode({'username': username, 'password': password}),
  );
  
  final data = jsonDecode(response.body);
  
  if (response.statusCode == 200 && data['token'] != null) {
    // ✅ SAVE TOKEN TO LOCAL STORAGE
    await saveToken(data['token']);
    return {'success': true, 'data': data};
  }
}
```

### Step 3: Token Persisted in SharedPreferences
**File**: `lib/services/api_service.dart` → `saveToken()` method
```dart
Future<void> saveToken(String token) async {
  _token = token;
  final prefs = await SharedPreferences.getInstance();
  // ✅ STORE IN LOCAL STORAGE (PERSISTENT)
  await prefs.setString('auth_token', token);
}
```

---

## 2. Using Saved Token for API Calls

### Every API call automatically includes the token:
**File**: `lib/services/api_service.dart` → `_getHeaders()` method
```dart
Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
  final headers = {'Content-Type': 'application/json'};

  if (includeAuth) {
    // ✅ RETRIEVE SAVED TOKEN FROM LOCAL STORAGE
    final token = await getToken();
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }
  }

  return headers;
}
```

### Retrieving Token from Local Storage:
```dart
Future<String?> getToken() async {
  if (_token != null) return _token;
  final prefs = await SharedPreferences.getInstance();
  // ✅ LOAD TOKEN FROM LOCAL STORAGE
  _token = prefs.getString('auth_token');
  return _token;
}
```

---

## 3. Fetch User Profile Using Saved Token

### HomeScreen loads profile on startup
**File**: `lib/screens/home_screen.dart`
```dart
@override
void initState() {
  super.initState();
  _loadUserProfile(); // Called on app load
}

Future<void> _loadUserProfile() async {
  final apiService = ApiService();
  // ✅ ApiService uses SAVED TOKEN from SharedPreferences
  final result = await apiService.getProfile();
  
  if (result['success']) {
    setState(() {
      _profileData = result['data'];
      _userName = result['data']['full_name'];
    });
  }
}
```

### ProfileScreen also fetches profile
**File**: `lib/screens/profile_screen.dart`
```dart
Future<void> _fetchProfileFromAPI() async {
  // ✅ Uses SAVED TOKEN to fetch profile
  final result = await _apiService.getProfile();
  
  if (result['success'] && result['data'] != null) {
    final profileData = Map<String, dynamic>.from(result['data']);
    setState(() {
      _cachedProfileData = profileData;
    });
  }
}
```

---

## 4. Local Storage Structure

### SharedPreferences keys:
- `auth_token` - User's authentication token (persisted across app restarts)

### Hive keys (additional profile caching):
- `app_box` - Contains user profile and app settings
- `cached_profile_data` - Cached profile information for offline access

---

## 5. Token Lifecycle

| Event | Action | Storage |
|-------|--------|---------|
| **User logs in** | API returns token | ✅ Saved to SharedPreferences |
| **App restarts** | Token retrieved from storage | ✅ Loaded from SharedPreferences |
| **API calls** | Token included in headers | ✅ Auto-injected by ApiService |
| **User logs out** | Token cleared | ✅ Removed from SharedPreferences |

---

## 6. Example Request Headers

Every authenticated API request includes:
```
Authorization: Token e740e3b616a8453...
Content-Type: application/json
```

---

## ✅ Current Implementation Status

- ✅ Token saved after login
- ✅ Token persisted in SharedPreferences
- ✅ Token retrieved on app restart
- ✅ Token auto-injected in all API requests
- ✅ Profile fetched using saved token
- ✅ Profile cached locally for offline access
- ✅ Token cleared on logout

## API Endpoints Using Saved Token

All these endpoints automatically use the saved token:
- `GET /api/profile/` - Get user profile
- `PUT /api/profile/` - Update user profile
- `GET /api/exercises/` - List exercises
- `GET /api/exercises/{id}/` - Exercise details
- `GET /api/my-exercise-summary/` - User progress
- `POST /api/add-trainee-progress/` - Log progress
- And all other authenticated endpoints...

---

## Testing

To verify token persistence:
1. **Login** → Token saved to SharedPreferences
2. **Close app completely** → Token remains in storage
3. **Reopen app** → App navigates to /home
4. **HomeScreen loads** → Profile fetched using saved token (no re-login needed)
5. **ProfileScreen opens** → User data displays using saved token

