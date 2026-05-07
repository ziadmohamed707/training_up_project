import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../services/api_service.dart';
import '../services/exercise_service.dart';
import 'exercise_detail_screen.dart';
import '../utils/app_constants.dart';
import '../utils/app_styles.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final String fallbackName;
  final VoidCallback? onEditProfile;
  final int refreshTrigger;

  const ProfileScreen({
    super.key,
    this.profileData = const {},
    required this.fallbackName,
    this.onEditProfile,
    this.refreshTrigger = 0,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic> _cachedProfileData = const {};
  Box<dynamic>? _appBox;
  final ApiService _apiService = ApiService();
  final ExerciseService _exerciseService = ExerciseService();
  Map<String, dynamic> _exerciseSummary = const {};
  bool _isSummaryLoading = false;
  int _todayBurnedCalories = 0;
  Map<String, Map<String, dynamic>> _exerciseLookupByName = const {};

  Map<String, dynamic> get _effectiveProfileData => {
    ...widget.profileData,
    ..._cachedProfileData,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectHiveProfileCache();
    _refreshAll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app comes to foreground
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshAll();
    }
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      _refreshAll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _connectHiveProfileCache() {
    try {
      _appBox = Hive.box(AppConstants.hiveAppBox);
      _readCachedProfile();
    } catch (_) {
      // Hive may not be initialized in tests.
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchProfileFromAPI(),
      _fetchExerciseSummaryFromAPI(),
      _loadTodayBurnedCalories(),
    ]);
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

  String _currentUserStorageKey() {
    final username = (_effectiveProfileData['username'] ?? '')
        .toString()
        .trim();
    if (username.isNotEmpty) return username.toLowerCase();
    final email = (_effectiveProfileData['email'] ?? '').toString().trim();
    if (email.isNotEmpty) return email.toLowerCase();
    return 'unknown_user';
  }

  Future<void> _loadTodayBurnedCalories() async {
    try {
      final box = Hive.box(AppConstants.hiveAppBox);
      final rawRoot = box.get(AppConstants.keyDailyBurnedCaloriesByUser);
      final root = _mapFromRaw(rawRoot) ?? <String, dynamic>{};

      final userKey = _currentUserStorageKey();
      final userBucket = _mapFromRaw(root[userKey]) ?? <String, dynamic>{};
      final today = _dateKey(DateTime.now());
      final total = int.tryParse((userBucket[today] ?? 0).toString()) ?? 0;

      if (!mounted) return;
      setState(() {
        _todayBurnedCalories = total;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _todayBurnedCalories = 0;
      });
    }
  }

  Future<void> _fetchProfileFromAPI() async {
    try {
      final result = await _apiService.getProfile();
      if (result['success'] && result['data'] != null) {
        final profileData = Map<String, dynamic>.from(result['data']);

        // Merge local-only extras (gender, goal_weight) that are not in the API response
        try {
          final extras = _appBox?.get(AppConstants.keyLocalProfileExtras);
          if (extras is Map) {
            final localExtras = Map<String, dynamic>.from(extras);
            localExtras.forEach((key, value) {
              if (value != null) profileData.putIfAbsent(key, () => value);
            });
          }
        } catch (_) {
          // Ignore
        }

        if (!mounted) return;
        setState(() {
          _cachedProfileData = profileData;
        });
        // Update cache to Hive with fresh data (includes merged local extras)
        try {
          await _appBox?.put(
            AppConstants.keyCachedProfileData,
            Map<String, dynamic>.from(profileData),
          );
        } catch (_) {
          // Ignore Hive errors
        }
      }
    } catch (_) {
      // Silently fail, use cached data
    }
  }

  Future<void> _fetchExerciseSummaryFromAPI() async {
    if (!mounted) return;
    setState(() {
      _isSummaryLoading = true;
    });

    try {
      final result = await _apiService.getMyExerciseSummary();
      if (result['success'] && result['data'] is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(result['data']);
        if (!mounted) return;
        setState(() {
          _exerciseSummary = data;
        });
      }
    } catch (_) {
      // keep current values on failure
    } finally {
      if (mounted) {
        setState(() {
          _isSummaryLoading = false;
        });
      }
    }
  }

  String _normalizedExerciseName(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _ensureExerciseLookup() async {
    if (_exerciseLookupByName.isNotEmpty) return;

    try {
      final allExercises = await _exerciseService.loadAllExercises();
      final lookup = <String, Map<String, dynamic>>{};

      for (final item in allExercises) {
        final data = item['data'];
        if (data is! Map<String, dynamic>) continue;
        final name = (data['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        lookup[_normalizedExerciseName(name)] = item;
      }

      if (!mounted) return;
      setState(() {
        _exerciseLookupByName = lookup;
      });
    } catch (_) {
      // keep empty on failure
    }
  }

  Future<void> _openExerciseDetailsFromName(
    String exerciseName, {
    bool fromInProgressCard = false,
  }) async {
    await _ensureExerciseLookup();
    if (!mounted) return;

    final key = _normalizedExerciseName(exerciseName);
    final item = _exerciseLookupByName[key];

    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercise details are not available yet.'),
        ),
      );
      return;
    }

    final data = item['data'];
    if (data is! Map<String, dynamic>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercise details are not available yet.'),
        ),
      );
      return;
    }

    final inProgressCount = _asStringList(
      _exerciseSummary['in_progress_exercises_names'],
    ).length;

    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          data: data,
          path: item['path']?.toString(),
          imagePath: item['image']?.toString(),
          fromInProgressCard: fromInProgressCard,
          inProgressCount: inProgressCount,
        ),
      ),
    );

    if (completed == true && mounted) {
      await _fetchExerciseSummaryFromAPI();
      await _loadTodayBurnedCalories();
    }
  }

  void _readCachedProfile() {
    try {
      final raw = _appBox?.get(AppConstants.keyCachedProfileData);
      Map<String, dynamic> mapped = const {};

      if (raw is Map) {
        mapped = Map<String, dynamic>.from(raw);
      } else if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          mapped = Map<String, dynamic>.from(decoded);
        }
      }

      if (!mounted) return;
      setState(() {
        _cachedProfileData = mapped;
      });
    } catch (_) {
      // Ignore malformed local cache.
    }
  }

  String get _fullName {
    final raw = (_effectiveProfileData['full_name'] ?? '').toString().trim();
    if (raw.isNotEmpty) return raw;
    return widget.fallbackName;
  }

  String get _displayName {
    final firstName = _fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .firstOrNull;
    final display = (firstName ?? widget.fallbackName).trim();
    if (display.isEmpty) return 'USER!';
    return '${display.toUpperCase()} !';
  }

  String get _membershipLabel {
    final role = (_effectiveProfileData['role'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    switch (role) {
      case 'coach':
        return 'Coach member';
      case 'admin':
        return 'Admin member';
      case 'trainee':
        return 'Trainee';
      default:
        return 'Trainee';
    }
  }

  String _metricValue(String key, String fallback, String suffix) {
    final value = _profileValue(key);
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

  dynamic _profileValue(String key) {
    final direct = _effectiveProfileData[key];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct;
    }

    // Backward/alternate API key support.
    switch (key) {
      case 'current_weight':
        return _effectiveProfileData['weight'];
      default:
        return direct;
    }
  }

  double _asDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return fallback;
    final normalized = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(normalized) ?? fallback;
  }

  int _asInt(dynamic value, int fallback) {
    return _asDouble(value, fallback.toDouble()).round();
  }

  double _calculateBMI() {
    final weightKg = _asDouble(_profileValue('current_weight'), 55);
    final heightCm = _asDouble(_effectiveProfileData['height'], 170);
    final heightM = heightCm / 100;
    if (heightM <= 0) return 0;
    return weightKg / (heightM * heightM);
  }

  double _calculateBMR() {
    final weightKg = _asDouble(
      _profileValue('current_weight'),
      55,
    ).clamp(35.0, 220.0);
    final heightCm = _asDouble(
      _effectiveProfileData['height'],
      170,
    ).clamp(120.0, 230.0);
    final age = _asInt(_effectiveProfileData['age'], 21).clamp(12, 85);
    final gender = (_effectiveProfileData['gender'] ?? 'female')
        .toString()
        .trim()
        .toLowerCase();

    return gender == 'male'
        ? (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5
        : (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
  }

  String _goalType() {
    final directGoal = (_effectiveProfileData['goal'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (directGoal.contains('loss') || directGoal.contains('loose')) {
      return 'weight_loss';
    }
    if (directGoal.contains('gain') ||
        directGoal.contains('muscle') ||
        directGoal.contains('build')) {
      return 'gain_muscle';
    }

    final currentWeight = _asDouble(_profileValue('current_weight'), 55);
    final goalWeight = _asDouble(
      _effectiveProfileData['goal_weight'],
      currentWeight,
    );
    if (goalWeight < currentWeight - 0.5) return 'weight_loss';
    if (goalWeight > currentWeight + 0.5) return 'gain_muscle';
    return 'improve_fitness';
  }

  Map<String, int> _calculatedMacros() {
    final weightKg = _asDouble(
      _profileValue('current_weight'),
      55,
    ).clamp(35.0, 220.0);
    final heightCm = _asDouble(
      _effectiveProfileData['height'],
      170,
    ).clamp(120.0, 230.0);
    final age = _asInt(_effectiveProfileData['age'], 21).clamp(12, 85);
    final gender = (_effectiveProfileData['gender'] ?? 'female')
        .toString()
        .trim()
        .toLowerCase();
    final goal = _goalType();

    final bmr = gender == 'male'
        ? (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5
        : (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;

    final maintenanceCalories = bmr * 1.4;
    final calories = switch (goal) {
      'weight_loss' => maintenanceCalories - 350,
      'gain_muscle' => maintenanceCalories + 300,
      _ => maintenanceCalories,
    }.clamp(1200, 4200).toDouble();

    final proteinPerKg = switch (goal) {
      'weight_loss' => 2.0,
      'gain_muscle' => 2.2,
      _ => 1.6,
    };
    final protein = (weightKg * proteinPerKg).round();

    final fatRatio = switch (goal) {
      'weight_loss' => 0.30,
      'gain_muscle' => 0.25,
      _ => 0.28,
    };
    final fat = ((calories * fatRatio) / 9).round();

    final carbCalories = calories - (protein * 4) - (fat * 9);
    final carbs = (carbCalories / 4).round().clamp(40, 700);

    return {
      'protein': protein.clamp(40, 320),
      'carbs': carbs,
      'fat': fat.clamp(25, 180),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 14),
                _buildAvatar(),
                const SizedBox(height: 14),
                Center(
                  child: Column(
                    children: [
                      Text(
                        _displayName,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _membershipLabel,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _buildStatsRow(),
                const SizedBox(height: 30),
                _buildSectionTitle('Current Excersises'),
                const SizedBox(height: 16),
                _buildGoalsRow(),
                const SizedBox(height: 24),
                _buildSectionTitle('Completed Excersises'),
                const SizedBox(height: 16),
                _buildCompletedExercisesRow(),
                const SizedBox(height: 28),
                _buildSectionTitle('MACRONUTRIENT GOALS'),
                const SizedBox(height: 18),
                _buildMacrosRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const SizedBox(
          width: 40,
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.transparent,
          ),
        ),
        Expanded(
          child: Text(
            'PROFILE',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: IconButton(
            onPressed: widget.onEditProfile,
            padding: EdgeInsets.zero,
            splashRadius: 20,
            icon: const Icon(Icons.edit_outlined, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final initials = _fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Center(
      child: Container(
        width: 120,
        height: 120,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF164E63), width: 3),
          color: const Color(0xFFFFF2DE),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB2EBF2), Color(0xFF7DD3FC)],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 22,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE0B2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials.isEmpty ? 'YU' : initials,
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF164E63),
                    ),
                  ),
                ),
              ),
              const Positioned(
                bottom: 14,
                child: Icon(
                  Icons.fitness_center,
                  size: 24,
                  color: Color(0xFF164E63),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final bmi = _calculateBMI().toStringAsFixed(1);
    final bmr = _calculateBMR().toStringAsFixed(0);

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            value: _metricValue('current_weight', '55', ' kg'),
            label: 'Weight',
          ),
        ),
        _buildDivider(),
        Expanded(
          child: _buildStatItem(
            value: _metricValue('height', '170', ' cm'),
            label: 'Height',
          ),
        ),
        _buildDivider(),
        Expanded(
          child: _buildStatItem(
            value: _metricValue('age', '18', ' year'),
            label: 'Age',
          ),
        ),
        _buildDivider(),
        Expanded(
          child: _buildStatItem(value: '$bmi', label: 'BMI'),
        ),
        _buildDivider(),
        Expanded(
          child: _buildStatItem(value: '${int.parse(bmr)} ', label: 'kcal BMR'),
        ),
      ],
    );
  }

  Widget _buildStatItem({required String value, required String label}) {
    // Handle compound suffixes like 'kcal', 'kg', 'cm', 'year'
    String digits = value;
    String suffix = '';

    if (value.contains('kcal')) {
      digits = value.replaceAll('kcal', '').trim();
      suffix = 'kcal';
    } else if (value.contains(' kg')) {
      digits = value.replaceAll(' kg', '').trim();
      suffix = 'kg';
    } else if (value.contains(' cm')) {
      digits = value.replaceAll(' cm', '').trim();
      suffix = 'cm';
    } else if (value.contains(' year')) {
      digits = value.replaceAll(' year', '').trim();
      suffix = 'year';
    } else {
      // Fallback: extract numbers and decimals
      digits = value.replaceAll(RegExp(r'[^0-9.]'), '');
      suffix = value.replaceFirst(digits, '').trim();
    }

    return Column(
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
        const SizedBox(height: 4),

        RichText(
          text: TextSpan(
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
            children: [
              TextSpan(text: digits),
              if (suffix.isNotEmpty)
                TextSpan(
                  text: ' $suffix',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.grey.withValues(alpha: 0.25),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildGoalsRow() {
    final items = _goalSummaryItems();

    if (_isSummaryLoading && items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isNotEmpty) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((item) {
            final isLast = item == items.last;
            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 12),
              child: _buildApiGoalItem(
                item,
                onTap: () => _openExerciseDetailsFromName(
                  item.name,
                  fromInProgressCard: true,
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EAF1)),
      ),
      child: Text(
        'No exercises in progress yet.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<_GoalSummaryItem> _goalSummaryItems() {
    final inProgress = _asStringList(
      _exerciseSummary['in_progress_exercises_names'],
    );

    return inProgress
        .map((name) => _GoalSummaryItem(name: name, status: 'In Progress'))
        .toList();
  }

  List<_GoalSummaryItem> _completedSummaryItems() {
    final completed = _asStringList(
      _exerciseSummary['completed_exercises_names'],
    );

    return completed
        .map((name) => _GoalSummaryItem(name: name, status: 'Completed'))
        .toList();
  }

  Widget _buildCompletedExercisesRow() {
    final completedItems = _completedSummaryItems();

    if (_isSummaryLoading && completedItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (completedItems.isNotEmpty) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: completedItems.map((item) {
            final isLast = item == completedItems.last;
            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 12),
              child: _buildApiGoalItem(
                item,
                onTap: () => _openExerciseDetailsFromName(item.name),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EAF1)),
      ),
      child: Text(
        'No completed exercises yet.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildApiGoalItem(_GoalSummaryItem item, {VoidCallback? onTap}) {
    final Color chipBg;
    final Color chipFg;

    switch (item.status) {
      case 'Completed':
        chipBg = const Color(0xFFE8F5E9);
        chipFg = const Color(0xFF2E7D32);
        break;
      case 'In Progress':
        chipBg = const Color(0xFFFFF4E5);
        chipFg = const Color(0xFFEF6C00);
        break;
      default:
        chipBg = const Color(0xFFEFF3F8);
        chipFg = const Color(0xFF455A64);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 180,
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4EAF1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.status,
                style: AppTextStyles.bodySmall.copyWith(
                  color: chipFg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacrosRow() {
    final macros = _calculatedMacros();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MacroCard(
                title: 'Protein',
                grams: '${macros['protein']}',
                unit: 'Grams per day',
                icon: Icons.egg_alt_outlined,
                iconBackground: Color(0xFFFFF1C9),
                iconColor: Color(0xFFC98A00),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MacroCard(
                title: 'Carbs',
                grams: '${macros['carbs']}',
                unit: 'Grams per day',
                icon: Icons.bakery_dining_outlined,
                iconBackground: Color(0xFFFFE0E0),
                iconColor: Color(0xFFC23B3B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MacroCard(
                title: 'Fat',
                grams: '${macros['fat']}',
                unit: 'Grams per day',
                icon: Icons.eco_outlined,
                iconBackground: Color(0xFFE7F7DD),
                iconColor: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE0B2)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE0B2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Burned Calories Today',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_todayBurnedCalories kcal',
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalSummaryItem {
  final String name;
  final String status;

  const _GoalSummaryItem({required this.name, required this.status});
}

class _MacroCard extends StatelessWidget {
  final String title;
  final String grams;
  final String unit;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _MacroCard({
    required this.title,
    required this.grams,
    required this.unit,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 30),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          grams,
          style: AppTextStyles.heading3.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(height: 1.3),
        ),
      ],
    );
  }
}
