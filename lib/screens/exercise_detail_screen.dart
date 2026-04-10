import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../services/api_service.dart';
import '../services/exercise_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_styles.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  final String? path;
  final String? imagePath;
  final bool fromInProgressCard;
  final int inProgressCount;

  const ExerciseDetailScreen({
    super.key,
    this.data,
    this.path,
    this.imagePath,
    this.fromInProgressCard = false,
    this.inProgressCount = 0,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  static const String _apiOrigin = 'https://trainingg.pythonanywhere.com';
  Map<String, dynamic>? _data;
  String? _imagePath;
  bool _isLoading = true;
  bool _isStarting = false;
  int _inProgressCounter = 0;
  double _userWeightKg = 70;
  late final TextEditingController _durationMinutesController;
  List<Map<String, dynamic>> _relatedExercises = const [];

  /// Returns the exercise ID to use with the mark API.
  /// API exercises carry an 'id' field; local exercises have no server ID.
  dynamic get _exerciseId => _data?['id'];

  Future<void> _startWorkout() async {
    final exerciseName = _displayTitle();
    final exerciseId = _exerciseId;

    // Show confirmation bottom sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(
              Icons.fitness_center,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Start $exerciseName?',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading3.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'This will log your workout session and track your progress.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Start',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isStarting = true);

    String? errorMessage;

    try {
      final api = ApiService();

      if (exerciseId != null) {
        // Call the mark API with action: "start"
        final result = await api.markMyExercise(
          exerciseId: exerciseId,
          action: 'start',
        );
        if (!result['success']) {
          errorMessage =
              result['error']?.toString() ??
              'Could not start workout. Please try again.';
        }
      }
      // If no exerciseId (local exercise), proceed without API call

      if (!mounted) return;

      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Show success feedback
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF2E7D32),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Workout Started!',
                style: AppTextStyles.heading3.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                '$exerciseName is now in progress. Give it your best!',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_kcal()} kcal  •  ${_minutes()} min',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Let\'s Go!',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start workout. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  String? _resolveImagePath(String? raw, {String? localBaseDir}) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;

    if (_isNetworkImage(value)) return value;
    if (value.startsWith('assets/')) return value;
    if (value.startsWith('/')) return '$_apiOrigin$value';

    if (localBaseDir != null && localBaseDir.isNotEmpty) {
      return '$localBaseDir/images/$value';
    }

    // Without a local base dir we cannot safely resolve bare file names.
    // Return null so caller can fallback to another image source.
    return null;
  }

  Widget _imageBox(
    String? path, {
    required BoxFit fit,
    double? width,
    double? height,
    Widget? fallback,
  }) {
    final fallbackWidget =
        fallback ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported, size: 50),
        );

    if (path == null || path.isEmpty) return fallbackWidget;

    if (_isNetworkImage(path)) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallbackWidget,
      );
    }

    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallbackWidget,
    );
  }

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _imagePath = widget.imagePath;
    _inProgressCounter = widget.inProgressCount;
    _durationMinutesController = TextEditingController(
      text: widget.fromInProgressCard ? _minutes().toString() : '',
    );
    _loadExerciseFromJson();
    _loadUserWeightForCalories();
  }

  @override
  void dispose() {
    _durationMinutesController.dispose();
    super.dispose();
  }

  int? _enteredDurationMinutes() {
    final raw = _durationMinutesController.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  double? _parseWeightKg(dynamic raw, {String? unit}) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    final cleaned = str.replaceAll(RegExp(r'[^0-9.\-]'), '');
    final value = double.tryParse(cleaned);
    if (value == null || value <= 0) return null;

    final normalizedUnit = (unit ?? '').toLowerCase();
    if (normalizedUnit == 'lbs' || normalizedUnit == 'lb') {
      return value * 0.453592;
    }
    return value;
  }

  Future<void> _loadUserWeightForCalories() async {
    double? weightKg;

    // 1) try local cache first
    try {
      final box = Hive.box(AppConstants.hiveAppBox);
      final raw = box.get(AppConstants.keyCachedProfileData);

      Map<String, dynamic>? profile;
      if (raw is Map) {
        profile = Map<String, dynamic>.from(raw);
      } else if (raw is String && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) profile = Map<String, dynamic>.from(decoded);
      }

      if (profile != null) {
        weightKg =
            _parseWeightKg(
              profile['weight'] ?? profile['current_weight'],
              unit: profile['weight_unit']?.toString(),
            ) ??
            _parseWeightKg(profile['weight']);
      }
    } catch (_) {
      // ignore cache issues
    }

    if (!mounted) return;
    setState(() {
      _userWeightKg = (weightKg ?? 70).clamp(35, 220).toDouble();
    });
  }

  double _estimatedMet() {
    final category = (_data?['category'] ?? '').toString().toLowerCase();
    final level = (_data?['level'] ?? '').toString().toLowerCase();
    final force = (_data?['force'] ?? '').toString().toLowerCase();

    var met = switch (category) {
      'cardio' => 8.0,
      'strength' => 6.0,
      'powerlifting' => 6.5,
      'olympic_weightlifting' => 7.0,
      'plyometrics' => 8.5,
      'stretching' => 2.5,
      'strongman' => 8.0,
      _ => 5.5,
    };

    if (level == 'advanced') met += 0.7;
    if (level == 'intermediate') met += 0.3;
    if (level == 'beginner') met -= 0.2;

    if (force == 'pull' || force == 'push') met += 0.2;

    return met.clamp(2.0, 12.0);
  }

  int _kcalForMinutes(int minutes) {
    final met = _estimatedMet();
    final kcal = (met * 3.5 * _userWeightKg / 200) * minutes;
    return kcal.round();
  }

  int _displayMinutes() {
    if (!widget.fromInProgressCard) return _minutes();
    return _enteredDurationMinutes() ?? _minutes();
  }

  int _displayKcal() {
    if (!widget.fromInProgressCard) return _kcal();
    return _kcalForMinutes(_displayMinutes());
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, dynamic>? _mapFromRaw(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  Future<String> _currentUserStorageKey() async {
    try {
      final box = Hive.box(AppConstants.hiveAppBox);
      final profile = _mapFromRaw(box.get(AppConstants.keyCachedProfileData));
      if (profile != null) {
        final username = (profile['username'] ?? '').toString().trim();
        if (username.isNotEmpty) return username.toLowerCase();
        final email = (profile['email'] ?? '').toString().trim();
        if (email.isNotEmpty) return email.toLowerCase();
      }
    } catch (_) {
      // ignore
    }
    return 'unknown_user';
  }

  Future<void> _saveBurnedCaloriesToLocal({
    required int calories,
    required int durationMinutes,
  }) async {
    final box = Hive.box(AppConstants.hiveAppBox);
    final userKey = await _currentUserStorageKey();
    final today = _dateKey(DateTime.now());

    final rootRaw = box.get(AppConstants.keyDailyBurnedCaloriesByUser);
    final root = _mapFromRaw(rootRaw) ?? <String, dynamic>{};

    final userBucket = _mapFromRaw(root[userKey]) ?? <String, dynamic>{};
    final previous = int.tryParse((userBucket[today] ?? 0).toString()) ?? 0;
    userBucket[today] = previous + calories;

    // Optional latest-entry metadata for quick display/debug
    userBucket['last_entry'] = {
      'exercise': _displayTitle(),
      'minutes': durationMinutes,
      'calories': calories,
      'at': DateTime.now().toIso8601String(),
    };

    root[userKey] = userBucket;
    await box.put(AppConstants.keyDailyBurnedCaloriesByUser, root);
  }

  String _displayUserWeightText() {
    final rounded = _userWeightKg.roundToDouble();
    final hasDecimal = (_userWeightKg - rounded).abs() >= 0.05;
    final value = hasDecimal
        ? _userWeightKg.toStringAsFixed(1)
        : rounded.toInt().toString();
    return '$value kg';
  }

  Future<void> _completeExerciseFromInProgress() async {
    final exerciseId = _exerciseId;
    if (exerciseId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot complete this exercise yet.')),
      );
      return;
    }

    final duration = _enteredDurationMinutes();
    if (duration == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid duration in minutes.'),
        ),
      );
      return;
    }

    final totalCalories = _kcalForMinutes(duration);

    setState(() => _isStarting = true);
    try {
      final api = ApiService();
      final result = await api.markMyExercise(
        exerciseId: exerciseId,
        action: 'completed',
        traineeNote:
            'duration_minutes=$duration, total_calories=$totalCalories',
      );

      if (!mounted) return;
      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error']?.toString() ??
                  'Could not mark as completed. Please try again.',
            ),
          ),
        );
        return;
      }

      await _saveBurnedCaloriesToLocal(
        calories: totalCalories,
        durationMinutes: duration,
      );

      setState(() {
        _inProgressCounter = (_inProgressCounter - 1).clamp(0, 999999);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Completed in $duration min • $totalCalories kcal burned.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not mark as completed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _loadExerciseFromJson() async {
    final jsonPath = widget.path;
    if (jsonPath == null || jsonPath.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // First try: load JSON directly from the provided path.
    try {
      final raw = await rootBundle.loadString(jsonPath);
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic> && mounted) {
        String? resolvedImage = _imagePath;
        final images = decoded['images'];
        if ((resolvedImage == null || resolvedImage.isEmpty) &&
            images is List) {
          final firstImage = images.isNotEmpty ? images.first : null;
          if (firstImage is String && firstImage.isNotEmpty) {
            final baseDir = jsonPath.substring(0, jsonPath.lastIndexOf('/'));
            resolvedImage = '$baseDir/images/$firstImage';
          }
        }

        setState(() {
          _data = decoded;
          _imagePath = resolvedImage;
          _isLoading = false;
        });
        await _loadRelatedExercises();
        return;
      }
    } catch (_) {
      // fallback to service-based loading below
    }

    // Fallback: use service resolution.
    try {
      final service = ExerciseService();
      final loaded = await service.loadExerciseByKey(jsonPath);
      if (loaded != null && mounted) {
        setState(() {
          _data = loaded['data'] as Map<String, dynamic>? ?? _data;
          _imagePath = (loaded['image'] as String?) ?? _imagePath;
          _isLoading = false;
        });
        await _loadRelatedExercises();
        return;
      }
    } catch (_) {
      // keep existing fallback values
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String _displayTitle() {
    final raw = (_data?['name'] ?? widget.path ?? 'Exercise').toString();
    final base = raw.contains('/') ? raw.split('/').last : raw;
    return base.replaceAll('.json', '').replaceAll('_', ' ');
  }

  String _level() =>
      _capitalize((_data?['level'] ?? 'beginner').toString().toLowerCase());

  String _category() =>
      _capitalize((_data?['category'] ?? 'workout').toString().toLowerCase());

  String _weightGoal() {
    final force = (_data?['force'] ?? '').toString().toLowerCase();
    if (force == 'pull') return 'Gain';
    if (force == 'push') return 'Lose';
    return 'Lose';
  }

  List<String> _instructions() {
    final raw = _data?['instructions'];
    if (raw is List) return raw.whereType<String>().toList();
    return const [];
  }

  List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return [raw.trim()];
    }
    return const [];
  }

  String _exerciseName(Map<String, dynamic> data, [String? path]) {
    final raw = (data['name'] ?? path ?? 'Exercise').toString();
    final base = raw.contains('/') ? raw.split('/').last : raw;
    return _capitalize(base.replaceAll('.json', '').replaceAll('_', ' '));
  }

  int _scoreExercise(Map<String, dynamic> candidate, String? candidatePath) {
    final current = _data;
    if (current == null) return -1;
    if (candidatePath != null && candidatePath == widget.path) return -1;

    final currentCategory = (current['category'] ?? '')
        .toString()
        .toLowerCase();
    final candidateCategory = (candidate['category'] ?? '')
        .toString()
        .toLowerCase();
    final currentLevel = (current['level'] ?? '').toString().toLowerCase();
    final candidateLevel = (candidate['level'] ?? '').toString().toLowerCase();
    final currentEquipment = (current['equipment'] ?? '')
        .toString()
        .toLowerCase();
    final candidateEquipment = (candidate['equipment'] ?? '')
        .toString()
        .toLowerCase();

    final currentPrimary = _stringList(
      current['primaryMuscles'],
    ).map((item) => item.toLowerCase()).toSet();
    final candidatePrimary = _stringList(
      candidate['primaryMuscles'],
    ).map((item) => item.toLowerCase()).toSet();
    final currentSecondary = _stringList(
      current['secondaryMuscles'],
    ).map((item) => item.toLowerCase()).toSet();
    final candidateSecondary = _stringList(
      candidate['secondaryMuscles'],
    ).map((item) => item.toLowerCase()).toSet();

    var score = 0;

    if (currentCategory.isNotEmpty && currentCategory == candidateCategory) {
      score += 4;
    }
    if (currentLevel.isNotEmpty && currentLevel == candidateLevel) {
      score += 2;
    }
    if (currentEquipment.isNotEmpty && currentEquipment == candidateEquipment) {
      score += 2;
    }

    score += currentPrimary.intersection(candidatePrimary).length * 5;
    score += currentPrimary.intersection(candidateSecondary).length * 3;
    score += currentSecondary.intersection(candidatePrimary).length * 2;

    final currentForce = (current['force'] ?? '').toString().toLowerCase();
    final candidateForce = (candidate['force'] ?? '').toString().toLowerCase();
    if (currentForce.isNotEmpty && currentForce == candidateForce) {
      score += 1;
    }

    return score;
  }

  String _recommendationReason(Map<String, dynamic> candidate) {
    final current = _data;
    if (current == null) return 'Trainer pick for your current session';

    final currentPrimary = _stringList(
      current['primaryMuscles'],
    ).map((item) => item.toLowerCase()).toSet();
    final candidatePrimary = _stringList(candidate['primaryMuscles']);
    final sharedPrimary = candidatePrimary.where(
      (item) => currentPrimary.contains(item.toLowerCase()),
    );

    if (sharedPrimary.isNotEmpty) {
      return 'Targets ${sharedPrimary.take(2).join(' & ')} like this exercise';
    }

    final candidateEquipment = (candidate['equipment'] ?? '').toString();
    final currentEquipment = (current['equipment'] ?? '').toString();
    if (candidateEquipment.isNotEmpty &&
        candidateEquipment.toLowerCase() == currentEquipment.toLowerCase()) {
      return 'Uses the same equipment for a smooth trainer progression';
    }

    final candidateCategory = (candidate['category'] ?? '').toString();
    final currentCategory = (current['category'] ?? '').toString();
    if (candidateCategory.isNotEmpty &&
        candidateCategory.toLowerCase() == currentCategory.toLowerCase()) {
      return 'Fits the same training category in your program';
    }

    return 'Recommended by your trainer to complement this movement';
  }

  Future<void> _loadRelatedExercises() async {
    final current = _data;
    if (current == null || widget.path == null || widget.path!.isEmpty) {
      if (mounted) {
        setState(() {
          _relatedExercises = const [];
        });
      }
      return;
    }

    try {
      final service = ExerciseService();
      final all = await service.loadAllExercises();
      final ranked =
          all
              .map((item) {
                final data = item['data'];
                if (data is! Map<String, dynamic>) return null;
                final score = _scoreExercise(data, item['path'] as String?);
                if (score <= 0) return null;
                return {
                  ...item,
                  'score': score,
                  'reason': _recommendationReason(data),
                };
              })
              .whereType<Map<String, dynamic>>()
              .toList()
            ..sort(
              (a, b) => ((b['score'] as int?) ?? 0).compareTo(
                (a['score'] as int?) ?? 0,
              ),
            );

      if (mounted) {
        setState(() {
          _relatedExercises = ranked.take(3).toList();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _relatedExercises = const [];
        });
      }
    }
  }

  int _minutes() {
    final count = _instructions().length;
    return (count * 3).clamp(5, 60);
  }

  int _kcal() {
    return _kcalForMinutes(_minutes());
  }

  Widget _chip(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _programItem(
    String title, {
    String? imagePath,
    String? subtitle,
    String? helperText,
  }) {
    final resolvedProgramImage = _resolveImagePath(imagePath);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _imageBox(
              resolvedProgramImage,
              width: 86,
              height: 70,
              fit: BoxFit.cover,
              fallback: Container(
                width: 86,
                height: 70,
                color: Colors.grey[300],
                child: const Icon(Icons.fitness_center),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle ?? '🔥 ${_kcal()} kcal  |  ⏱ ${_minutes()} min',
                  style: AppTextStyles.bodySmall,
                ),
                if (helperText != null) ...[
                  const SizedBox(height: 2),
                  Text(helperText, style: AppTextStyles.bodySmall),
                ],
                const SizedBox(height: 2),
                Text(_level(), style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _displayTitle();
    final instructions = _instructions();
    final description = instructions.isNotEmpty
        ? instructions.first
        : 'Follow the guided steps and keep proper form during every repetition.';
    final equipment = (_data?['equipment'] ?? 'N/A').toString();
    final mechanic = (_data?['mechanic'] ?? 'N/A').toString();
    final primaryMuscles = (_data?['primaryMuscles'] is List)
        ? (_data!['primaryMuscles'] as List).whereType<String>().toList()
        : <String>[];
    final localBaseDir =
        (widget.path != null &&
            widget.path!.isNotEmpty &&
            !widget.path!.startsWith('api:') &&
            widget.path!.contains('/'))
        ? widget.path!.substring(0, widget.path!.lastIndexOf('/'))
        : null;
    final rawGallery = (_data?['images'] is List)
        ? (_data!['images'] as List)
        : const [];
    final galleryImages = rawGallery
        .whereType<String>()
        .map((img) => _resolveImagePath(img, localBaseDir: localBaseDir))
        .whereType<String>()
        .toList();
    final resolvedPrimaryImage = _resolveImagePath(
      _imagePath,
      localBaseDir: localBaseDir,
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Swipeable Images Section
          SizedBox(
            height: 320,
            width: double.infinity,
            child: galleryImages.isNotEmpty
                ? PageView.builder(
                    itemCount: galleryImages.length,
                    itemBuilder: (context, idx) {
                      final resolved = galleryImages[idx];
                      return _imageBox(
                        resolved,
                        fit: BoxFit.cover,
                        fallback: Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  )
                : (resolvedPrimaryImage != null
                      ? _imageBox(
                          resolvedPrimaryImage,
                          fit: BoxFit.fill,
                          fallback: Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.fitness_center, size: 50),
                        )),
          ),
          // Back Button
          SafeArea(
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            ),
          ),
          // Content Section
          Padding(
            padding: const EdgeInsets.only(top: 300),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            '🔥 ${_displayKcal()} kcal',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            height: 20,
                            width: 1,
                            color: Colors.grey[400],
                          ),
                          Text(
                            '⏱ ${_displayMinutes()} min',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _chip('Level', _level()),
                        const SizedBox(width: 10),
                        _chip('Category', _category()),
                        const SizedBox(width: 10),
                        _chip(
                          'Weight',
                          widget.fromInProgressCard
                              ? _displayUserWeightText()
                              : _weightGoal(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (widget.fromInProgressCard) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFE082)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.pending_actions,
                              color: Color(0xFFEF6C00),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'In Progress Counter: $_inProgressCounter',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF5D4037),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _durationMinutesController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'How long did you take? (minutes). ',
                          hintText: 'e.g. 25',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Estimated total calories: ${_displayKcal()} kcal',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Calculated using your weight: ${_displayUserWeightText()}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      title.toUpperCase(),
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 30,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Equipment: $equipment'),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Mechanic: $mechanic'),
                        ),
                        if (primaryMuscles.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3F3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Primary: ${primaryMuscles.join(', ')}',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            '3 Weeks - 20 Exercise',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.heading3.copyWith(
                              fontSize: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Schedule'),
                          ),
                        ),
                      ],
                    ),
                    if (!widget.fromInProgressCard) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Trainer Recommended Program',
                        style: AppTextStyles.heading3.copyWith(fontSize: 34),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Recommended next exercises based on the same muscles, category, and training flow.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _category(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Legs'),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Back'),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Chest'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_relatedExercises.isEmpty)
                        _programItem(
                          'Trainer is building your next block',
                          imagePath: _imagePath,
                          subtitle: _isLoading
                              ? 'Analyzing this exercise to build your trainer plan'
                              : 'Trainer recommendations are not ready yet',
                          helperText:
                              'Add more exercise data to unlock smarter recommendations',
                        ),
                      ..._relatedExercises.map((item) {
                        final data =
                            item['data'] as Map<String, dynamic>? ?? {};
                        final itemTitle = _exerciseName(
                          data,
                          item['path'] as String?,
                        );
                        final itemSubtitle =
                            (item['reason'] as String?) ??
                            'Recommended by your trainer';
                        return _programItem(
                          itemTitle,
                          imagePath: item['image'] as String?,
                          subtitle: itemSubtitle,
                        );
                      }),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isStarting
                            ? null
                            : (widget.fromInProgressCard
                                  ? _completeExerciseFromInProgress
                                  : _startWorkout),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isStarting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                widget.fromInProgressCard
                                    ? 'MARK AS COMPLETED'
                                    : 'START NOW',
                                style: TextStyle(
                                  fontSize: widget.fromInProgressCard ? 18 : 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
