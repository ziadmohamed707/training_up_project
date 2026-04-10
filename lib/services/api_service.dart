import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://trainingg.pythonanywhere.com/api';

  String? _token;

  // Get token from storage
  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  // Save token to storage
  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear token from storage
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Helper method to get headers
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};

    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }
    }

    return headers;
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    required String role,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: await _getHeaders(includeAuth: false),
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone,
          'role': role,
          'full_name': fullName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Verify Email
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-email/'),
        headers: await _getHeaders(includeAuth: false),
        body: jsonEncode({'email': email, 'code': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Verification failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: await _getHeaders(includeAuth: false),
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Get Profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Update Profile
  Future<Map<String, dynamic>> updateProfile({
    String? phone,
    String? email,
    String? fullName,
    int? age,
    num? weight,
    num? height,
    String? goal,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (phone != null) body['phone'] = phone;
      if (email != null) body['email'] = email;
      if (fullName != null) body['full_name'] = fullName;
      if (age != null) body['age'] = age;
      if (weight != null) body['weight'] = weight;
      if (height != null) body['height'] = height;
      if (goal != null) body['goal'] = goal;

      final response = await http.put(
        Uri.parse('$baseUrl/profile/'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change-password/'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Logout
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout/'),
        headers: await _getHeaders(),
      );

      await clearToken();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': true, 'message': 'Logged out'};
      }
    } catch (e) {
      await clearToken();
      return {'success': true, 'message': 'Logged out'};
    }
  }

  // Delete Account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete-account/'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body);
      await clearToken();

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to delete account',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Get My Role
  Future<Map<String, dynamic>> getMyRole() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-role/'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'role': data['role']};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to fetch role',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Exercises list (supports optional filters)
  Future<Map<String, dynamic>> getExercises({
    String? category,
    String? level,
    String? force,
  }) async {
    try {
      final query = <String, String>{};
      if (category != null && category.trim().isNotEmpty) {
        query['category'] = category.trim();
      }
      if (level != null && level.trim().isNotEmpty) {
        query['level'] = level.trim();
      }
      if (force != null && force.trim().isNotEmpty) {
        query['force'] = force.trim();
      }

      Uri uri = Uri.parse('$baseUrl/exercises/');
      if (query.isNotEmpty) {
        uri = uri.replace(queryParameters: query);
      }

      http.Response response = await http.get(
        uri,
        headers: await _getHeaders(includeAuth: false),
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        response = await http.get(uri, headers: await _getHeaders());
      }

      final dynamic decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;

      if (response.statusCode == 200) {
        if (decoded is List) {
          return {'success': true, 'data': decoded};
        }
        if (decoded is Map<String, dynamic>) {
          if (decoded['results'] is List) {
            return {'success': true, 'data': decoded['results']};
          }
          if (decoded['data'] is List) {
            return {'success': true, 'data': decoded['data']};
          }
        }
        return {'success': true, 'data': const <dynamic>[]};
      }

      final error = decoded is Map<String, dynamic>
          ? (decoded['error'] ?? decoded['detail'])
          : null;
      return {'success': false, 'error': error ?? 'Failed to fetch exercises'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Exercise details
  Future<Map<String, dynamic>> getExerciseDetails(dynamic id) async {
    try {
      http.Response response = await http.get(
        Uri.parse('$baseUrl/exercises/$id/'),
        headers: await _getHeaders(includeAuth: false),
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        response = await http.get(
          Uri.parse('$baseUrl/exercises/$id/'),
          headers: await _getHeaders(),
        );
      }

      final dynamic data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }

      final error = data is Map<String, dynamic>
          ? (data['error'] ?? data['detail'])
          : null;
      return {
        'success': false,
        'error': error ?? 'Failed to fetch exercise details',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Create exercise (coach/admin)
  Future<Map<String, dynamic>> createExercise({
    required String exerciseId,
    required String name,
    required String category,
    required String force,
    required String level,
    String? mechanic,
    String? equipment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/exercises/'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'exercise_id': exerciseId,
          'name': name,
          'category': category,
          'force': force,
          'level': level,
          if (mechanic != null) 'mechanic': mechanic,
          if (equipment != null) 'equipment': equipment,
        }),
      );

      final dynamic data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }

      final error = data is Map<String, dynamic>
          ? (data['error'] ?? data['detail'])
          : null;
      return {'success': false, 'error': error ?? 'Failed to create exercise'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Update exercise (coach/admin)
  Future<Map<String, dynamic>> updateExercise({
    required dynamic id,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/exercises/$id/manage/'),
        headers: await _getHeaders(),
        body: jsonEncode(updates),
      );

      final dynamic data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }

      final error = data is Map<String, dynamic>
          ? (data['error'] ?? data['detail'])
          : null;
      return {'success': false, 'error': error ?? 'Failed to update exercise'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Delete exercise (coach/admin)
  Future<Map<String, dynamic>> deleteExercise(dynamic id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/exercises/$id/manage/'),
        headers: await _getHeaders(),
      );

      dynamic data;
      try {
        data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (_) {
        data = null;
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'data': data};
      }

      final error = data is Map<String, dynamic>
          ? (data['error'] ?? data['detail'])
          : null;
      return {'success': false, 'error': error ?? 'Failed to delete exercise'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Exercise categories
  Future<Map<String, dynamic>> getExerciseCategories() async {
    try {
      http.Response response = await http.get(
        Uri.parse('$baseUrl/exercise-categories/'),
        headers: await _getHeaders(includeAuth: false),
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        response = await http.get(
          Uri.parse('$baseUrl/exercise-categories/'),
          headers: await _getHeaders(),
        );
      }

      final dynamic data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      if (response.statusCode == 200) {
        if (data is List) return {'success': true, 'data': data};
        if (data is Map<String, dynamic> && data['results'] is List) {
          return {'success': true, 'data': data['results']};
        }
        return {'success': true, 'data': const <dynamic>[]};
      }

      final error = data is Map<String, dynamic>
          ? (data['error'] ?? data['detail'])
          : null;
      return {'success': false, 'error': error ?? 'Failed to fetch categories'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Start / complete / reset exercise
  Future<Map<String, dynamic>> markMyExercise({
    required dynamic exerciseId,
    required String action,
    String? traineeNote,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/my-exercises/$exerciseId/mark/'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'action': action,
          if (traineeNote != null && traineeNote.trim().isNotEmpty)
            'trainee_note': traineeNote,
        }),
      );

      final dynamic data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }

      final error = data is Map<String, dynamic>
          ? (data['error'] ?? data['detail'])
          : null;
      return {
        'success': false,
        'error': error ?? 'Failed to update exercise status',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // My exercise summary
  Future<Map<String, dynamic>> getMyExerciseSummary({String? category}) async {
    try {
      Uri uri = Uri.parse('$baseUrl/my-exercises/summary/');
      if (category != null && category.trim().isNotEmpty) {
        uri = uri.replace(queryParameters: {'category': category.trim()});
      }

      final response = await http.get(uri, headers: await _getHeaders());
      final dynamic data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }

      final error = data is Map<String, dynamic>
          ? (data['error'] ?? data['detail'])
          : null;
      return {'success': false, 'error': error ?? 'Failed to fetch summary'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // My exercise progress list
  Future<Map<String, dynamic>> getMyExerciseProgress() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-exercise-progress/'),
        headers: await _getHeaders(),
      );

      final dynamic data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;

      if (response.statusCode == 200) {
        if (data is List) return {'success': true, 'data': data};
        if (data is Map<String, dynamic> && data['results'] is List) {
          return {'success': true, 'data': data['results']};
        }
        return {'success': true, 'data': const <dynamic>[]};
      }

      final error = data is Map<String, dynamic>
          ? (data['error'] ?? data['detail'])
          : null;
      return {'success': false, 'error': error ?? 'Failed to fetch progress'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Coach: add trainee progress
  Future<Map<String, dynamic>> addTraineeProgress({
    required dynamic traineeId,
    required String stage,
    required num progressPercentage,
    String? note,
    num? currentWeight,
    num? currentHeight,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trainees/$traineeId/progress/add/'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'stage': stage,
          'progress_percentage': progressPercentage,
          if (note != null) 'note': note,
          if (currentWeight != null) 'current_weight': currentWeight,
          if (currentHeight != null) 'current_height': currentHeight,
        }),
      );

      final dynamic data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }

      final error = data is Map<String, dynamic>
          ? (data['error'] ?? data['detail'])
          : null;
      return {
        'success': false,
        'error': error ?? 'Failed to add trainee progress',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Coach: get trainee current progress
  Future<Map<String, dynamic>> getTraineeCurrentProgress(
    dynamic traineeId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trainees/$traineeId/progress/current/'),
        headers: await _getHeaders(),
      );

      final dynamic data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }

      final error = data is Map<String, dynamic>
          ? (data['error'] ?? data['detail'])
          : null;
      return {
        'success': false,
        'error': error ?? 'Failed to fetch trainee current progress',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Coach: get trainee progress timeline
  Future<Map<String, dynamic>> getTraineeProgressTimeline(
    dynamic traineeId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trainees/$traineeId/progress/timeline/'),
        headers: await _getHeaders(),
      );

      final dynamic data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      if (response.statusCode == 200) {
        if (data is List) return {'success': true, 'data': data};
        if (data is Map<String, dynamic> && data['results'] is List) {
          return {'success': true, 'data': data['results']};
        }
        return {'success': true, 'data': const <dynamic>[]};
      }

      final error = data is Map<String, dynamic>
          ? (data['error'] ?? data['detail'])
          : null;
      return {
        'success': false,
        'error': error ?? 'Failed to fetch trainee timeline',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Get Recipes
  Future<Map<String, dynamic>> getRecipes() async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/recipes/'),
        headers: await _getHeaders(),
      );

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode == 200) {
        if (decoded is List) {
          return {'success': true, 'data': decoded};
        }

        if (decoded is Map<String, dynamic>) {
          if (decoded['results'] is List) {
            return {'success': true, 'data': decoded['results']};
          }
          if (decoded['data'] is List) {
            return {'success': true, 'data': decoded['data']};
          }
        }

        return {'success': true, 'data': const <dynamic>[]};
      }

      final error = decoded is Map<String, dynamic>
          ? (decoded['error'] ?? decoded['detail'])
          : null;
      return {'success': false, 'error': error ?? 'Failed to fetch recipes'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Recipe details
  Future<Map<String, dynamic>> getRecipeDetails(dynamic id) async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/recipes/$id/'),
        headers: await _getHeaders(),
      );

      final dynamic data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }

      final error = data is Map<String, dynamic>
          ? (data['error'] ?? data['detail'])
          : null;
      return {
        'success': false,
        'error': error ?? 'Failed to fetch recipe details',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
