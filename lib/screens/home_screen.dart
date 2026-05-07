import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:training_up_project/screens/app_settings_screen.dart';
import '../services/api_service.dart';
import '../services/exercise_service.dart';
import '../utils/app_constants.dart';
import 'exercise_detail_screen.dart';
import 'full_exercise_screen.dart';
import 'meal_plans_screen.dart';
import 'profile_screen.dart';
import 'edit_profile_screen.dart';
import 'my_progress_screen.dart';
import 'dashboard_screen.dart';
import 'filters_plan_screen.dart';
import '../utils/app_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  String _userName = 'Yasso';
  Map<String, dynamic> _profileData = const {};
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoadingExercises = false;
  String? _selectedCategory;
  String? _selectedLevel;
  String _selectedGoal = 'Gain Weight';
  int _profileRefreshTrigger = 0;

  static const List<String> _goalItems = [
    'Loose Weight',
    'Gain Weight',
    'Body Building',
    'Health',
  ];

  static const List<Map<String, dynamic>> _categoryItems = [
    {'label': 'Cardio', 'icon': Icons.favorite},
    {'label': 'Olympic Weightlifting', 'icon': Icons.sports_gymnastics},
    {'label': 'Plyometrics', 'icon': Icons.directions_run},
    {'label': 'Powerlifting', 'icon': Icons.fitness_center},
    {'label': 'Strength', 'icon': Icons.sports_mma},
    {'label': 'Stretching', 'icon': Icons.self_improvement},
    {'label': 'Strongman', 'icon': Icons.sports_handball},
  ];

  @override
  void initState() {
    super.initState();
    _loadLocalUserProfile();
    _loadUserProfile();
    _loadExercises();
  }

  Future<void> _loadLocalUserProfile() async {
    try {
      final box = Hive.box(AppConstants.hiveAppBox);
      final cachedRaw = box.get(AppConstants.keyCachedProfileData);
      Map<String, dynamic>? data;

      if (cachedRaw is Map) {
        data = Map<String, dynamic>.from(cachedRaw);
      } else if (cachedRaw is String && cachedRaw.isNotEmpty) {
        final decoded = jsonDecode(cachedRaw);
        if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
          await box.put(AppConstants.keyCachedProfileData, data);
        }
      }

      if (data == null) return;
      final resolvedData = data;
      if (!mounted) return;

      setState(() {
        _profileData = resolvedData;
        final fullName = (resolvedData['full_name'] ?? '').toString().trim();
        if (fullName.isNotEmpty) {
          _userName = fullName.split(' ').first;
        }
        // Auto-set level filter from user's fitness level
        final fitnessLevel = (resolvedData['fitness_level'] ?? '')
            .toString()
            .toLowerCase();
        if (fitnessLevel.isNotEmpty) {
          _selectedLevel = _mapFitnessLevel(fitnessLevel);
        }
      });
    } catch (e) {
      debugPrint('Local profile load failed: $e');
    }
  }

  Future<void> _saveLocalUserProfile(Map<String, dynamic> data) async {
    try {
      final box = Hive.box(AppConstants.hiveAppBox);
      await box.put(
        AppConstants.keyCachedProfileData,
        Map<String, dynamic>.from(data),
      );
    } catch (e) {
      debugPrint('Local profile save failed: $e');
    }
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoadingExercises = true;
    });

    try {
      final service = ExerciseService();
      final keys = await service.listJsonKeys();

      final List<Map<String, dynamic>> accumulated = [];

      // load sequentially but yield periodically so UI stays responsive
      const batchSize = 10;
      for (var i = 0; i < keys.length; i++) {
        if (!mounted) break;
        final key = keys[i];
        final item = await service.loadExerciseByKey(key);
        if (item != null) accumulated.add(item);

        // update UI every batchSize items so user sees progress
        if (i % batchSize == 0) {
          if (!mounted) break;
          setState(() {
            _exercises = List.from(accumulated);
          });
          // yield to event loop to keep UI responsive
          await Future.delayed(const Duration(milliseconds: 8));
        }
      }

      if (mounted) {
        setState(() {
          _exercises = List.from(accumulated);
        });
      }
    } catch (e) {
      debugPrint('Exercise load failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExercises = false;
        });
      }
    }
  }

  Future<void> _loadUserProfile() async {
    final apiService = ApiService();
    final result = await apiService.getProfile();
    if (result['success'] && mounted) {
      final data = Map<String, dynamic>.from(
        result['data'] as Map<String, dynamic>? ?? const {},
      );
      setState(() {
        _profileData = data;
        _userName = data['full_name']?.toString().split(' ').first ?? 'User';
        // Auto-set level filter from user's fitness level
        final fitnessLevel = (data['fitness_level'] ?? '')
            .toString()
            .toLowerCase();
        if (fitnessLevel.isNotEmpty) {
          _selectedLevel = _mapFitnessLevel(fitnessLevel);
        }
      });
      await _saveLocalUserProfile(data);
    }
  }

  /// Maps API / profile-setup fitness level strings to the filter values
  /// used by [_matchesSelectedLevel].
  String? _mapFitnessLevel(String raw) {
    switch (raw.toLowerCase()) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
      case 'average':
        return 'Average';
      case 'advanced':
      case 'expert':
      case 'hard':
        return 'Hard';
      default:
        return null;
    }
  }

  List<Map<String, dynamic>> get _visibleExercises {
    return _exercises
        .where(_matchesSelectedGoal)
        .where(_matchesSelectedCategory)
        .where(_matchesSelectedLevel)
        .toList();
  }

  bool _matchesSelectedLevel(Map<String, dynamic> item) {
    final selectedLevel = _selectedLevel;
    if (selectedLevel == null || selectedLevel.isEmpty) return true;

    final data = item['data'] as Map<String, dynamic>? ?? const {};
    final level = (data['level'] ?? '').toString().toLowerCase();

    switch (selectedLevel.toLowerCase()) {
      case 'beginner':
        return level == 'beginner';
      case 'average':
        return level == 'intermediate' || level == 'average';
      case 'hard':
        return level == 'expert' || level == 'advanced' || level == 'hard';
      default:
        return true;
    }
  }

  bool _matchesSelectedGoal(Map<String, dynamic> item) {
    final data = item['data'] as Map<String, dynamic>? ?? const {};
    final path = (item['path'] as String? ?? '').toLowerCase();
    final category = (data['category'] ?? '').toString().toLowerCase();
    final force = (data['force'] ?? '').toString().toLowerCase();
    final level = (data['level'] ?? '').toString().toLowerCase();

    switch (_selectedGoal) {
      case 'Loose Weight':
        return path.contains('/cardio/') ||
            path.contains('/plyometrics/') ||
            category.contains('cardio') ||
            category.contains('plyometric') ||
            force == 'push';
      case 'Gain Weight':
        return path.contains('/strength/') ||
            path.contains('/powerlifting/') ||
            path.contains('/strongman/') ||
            path.contains('/olympic_weightlifting/') ||
            category.contains('strength') ||
            category.contains('powerlifting') ||
            category.contains('strongman') ||
            category.contains('weightlifting') ||
            force == 'pull';
      case 'Body Building':
        return path.contains('/strength/') ||
            path.contains('/powerlifting/') ||
            path.contains('/strongman/') ||
            category.contains('strength') ||
            category.contains('powerlifting') ||
            category.contains('strongman') ||
            level == 'intermediate' ||
            level == 'expert';
      case 'Health':
        return path.contains('/stretching/') ||
            path.contains('/cardio/') ||
            category.contains('stretch') ||
            category.contains('cardio') ||
            level == 'beginner';
      default:
        return true;
    }
  }

  bool _matchesSelectedCategory(Map<String, dynamic> item) {
    final selected = _selectedCategory;
    if (selected == null) return true;

    final data = item['data'] as Map<String, dynamic>? ?? const {};
    final path = (item['path'] as String? ?? '').toLowerCase();
    final jsonCategory = (data['category'] ?? '').toString().toLowerCase();
    final normalizedSelected = selected.toLowerCase().replaceAll(' ', '_');

    return path.contains('/$normalizedSelected/') ||
        jsonCategory.contains(selected.toLowerCase()) ||
        jsonCategory.contains(normalizedSelected.replaceAll('_', ' '));
  }

  void _toggleCategory(String label) {
    setState(() {
      _selectedCategory = _selectedCategory == label ? null : label;
    });
  }

  void _selectGoal(String label) {
    setState(() {
      _selectedGoal = label;
    });
  }

  String _exerciseTitle(Map<String, dynamic> item) {
    final data = item['data'] as Map<String, dynamic>? ?? const {};
    final raw = (data['name'] ?? data['title'] ?? item['path'] ?? 'Exercise')
        .toString();
    final base = raw.contains('/') ? raw.split('/').last : raw;
    return base.replaceAll('.json', '').replaceAll('_', ' ');
  }

  String _exerciseLevel(Map<String, dynamic> item) {
    final data = item['data'] as Map<String, dynamic>? ?? const {};
    final raw = (data['level'] ?? 'Beginner').toString().trim();
    if (raw.isEmpty) return 'Beginner';
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  String _exerciseDuration(Map<String, dynamic> item) {
    final data = item['data'] as Map<String, dynamic>? ?? const {};
    final instructions = data['instructions'];
    final count = instructions is List
        ? instructions.whereType<String>().length
        : 0;
    final minutes = (count * 3).clamp(5, 60);
    return '$minutes min';
  }

  String _exerciseCalories(Map<String, dynamic> item) {
    final data = item['data'] as Map<String, dynamic>? ?? const {};
    final instructions = data['instructions'];
    final count = instructions is List
        ? instructions.whereType<String>().length
        : 0;
    final minutes = (count * 3).clamp(5, 60);
    final calories = 90 + (minutes * 3);
    return '$calories kcal';
  }

  Future<void> _openExercise(Map<String, dynamic> item) async {
    final service = ExerciseService();
    final path = (item['path'] as String?) ?? '';
    final data = item['data'] as Map<String, dynamic>?;
    final imagePath = item['image'] as String?;

    Map<String, dynamic>? freshItem;
    if (path.isNotEmpty) {
      freshItem = await service.loadExerciseByKey(path);
    }

    final payload =
        (freshItem?['data'] as Map<String, dynamic>?) ??
        (data == null ? null : Map<String, dynamic>.from(data));
    final resolvedImagePath = (freshItem?['image'] as String?) ?? imagePath;

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          data: payload,
          path: path,
          imagePath: resolvedImagePath,
        ),
      ),
    );
    // Refresh profile after returning from any exercise
    if (mounted) {
      setState(() => _profileRefreshTrigger++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabBodies = <Widget>[
      _buildHomeTab(),
      const MealPlansScreen(embedded: true),
      const FullExerciseScreen(embedded: true),
      _buildProfileTab(),
    ];

    return WillPopScope(
      onWillPop: () async {
        // Close drawer first if open.
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.of(context).pop();
          return false;
        }

        // If user is not on Home tab, go to Home tab instead of leaving screen.
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }

        // Block default back behavior on HomeScreen.
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        body: IndexedStack(index: _selectedIndex, children: tabBodies),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildFeaturedCard(),
                const SizedBox(height: 30),
                _buildGoalSelector(),
                const SizedBox(height: 30),
                _buildCategorySection(),
                const SizedBox(height: 30),
                _buildPopularExercises(),
                const SizedBox(height: 30),
                _buildExercisesFromAssets(),
                const SizedBox(height: 30),
                _buildMealPlans(),
                const SizedBox(height: 30),
                _buildAdditionalExercises(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return ProfileScreen(
      profileData: _profileData,
      fallbackName: _userName,
      refreshTrigger: _profileRefreshTrigger,
      onEditProfile: () async {
        final updated = await Navigator.of(context).push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (_) => EditProfileScreen(initialData: _profileData),
          ),
        );

        if (!mounted || updated == null) return;
        final nextProfile = Map<String, dynamic>.from(updated);
        setState(() {
          _profileData = nextProfile;
          final fullName = (_profileData['full_name'] ?? '').toString().trim();
          if (fullName.isNotEmpty) {
            _userName = fullName.split(' ').first;
          }
        });
        await _saveLocalUserProfile(nextProfile);
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, Good Morning',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$_userName !',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
              tooltip: 'Logout',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            'Search',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.orange[600]!],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIT YOUNG MAN DOING',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'BATTLE STRETCH TRAINING',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final candidates = _visibleExercises;

                    if (candidates.isNotEmpty) {
                      await _openExercise(candidates.first);
                      return;
                    }

                    if (!mounted) return;
                    setState(() {
                      _selectedIndex = 2;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No exercise loaded yet. Open Exercise tab.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: Colors.orange[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Start Exercise',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange[300],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 50, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT YOUR GOAL',
          style: AppTextStyles.heading3.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _goalItems.expand((label) {
              final isLast = label == _goalItems.last;
              return [
                _buildGoalChip(label, _selectedGoal == label),
                if (!isLast) const SizedBox(width: 8),
              ];
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectGoal(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.black : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CATEGORY',
              style: AppTextStyles.heading3.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          // alignment: WrapAlignment.spaceBetween,
          // runAlignment: WrapAlignment.spaceBetween,
          spacing: 32,
          runSpacing: 16,
          children: _categoryItems.map((item) {
            return SizedBox(
              width: 76,
              child: _buildCategoryItem(
                item['label'] as String,
                item['icon'] as IconData,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String label, IconData icon) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => _toggleCategory(label),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.grey[800],
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: AppColors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularExercises() {
    final popularExercises = _visibleExercises.take(2).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'POPULAR EXERCISE',
              style: AppTextStyles.heading3.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (popularExercises.isEmpty)
          Text('No popular exercises available', style: AppTextStyles.bodySmall)
        else
          ...popularExercises.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == popularExercises.length - 1 ? 0 : 12,
              ),
              child: _buildExerciseCard(item),
            );
          }),
      ],
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> item) {
    final title = _exerciseTitle(item);
    final level = _exerciseLevel(item);
    final duration = _exerciseDuration(item);
    final imagePath = item['image'] as String?;

    return InkWell(
      onTap: () => _openExercise(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imagePath != null
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.fitness_center, size: 48),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.fitness_center, size: 48),
                      ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_border, size: 20),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        level,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.circle, size: 4, color: Colors.white),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealPlans() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MEAL PLANS',
              style: AppTextStyles.heading3.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildMealCard(
                'Greek salad with lettuce, green onion,',
                '150 kcal',
                Colors.pink[100]!,
              ),
              const SizedBox(width: 12),
              _buildMealCard(
                'Salad of fresh vegetables',
                '270 kcal',
                Colors.green[100]!,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExercisesFromAssets() {
    final visibleExercises = _visibleExercises;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCategory == null
                  ? 'EXERCISES'
                  : '${_selectedCategory!.toUpperCase()} EXERCISES',
              style: AppTextStyles.heading3.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visibleExercises.isEmpty && _isLoadingExercises)
          const Center(
            child: SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(),
            ),
          )
        else if (visibleExercises.isEmpty)
          Text(
            _selectedCategory == null
                ? 'No exercises found'
                : 'No exercises found for $_selectedCategory',
            style: AppTextStyles.bodySmall,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingExercises) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
              ],
              Text(
                '${visibleExercises.length} exercise${visibleExercises.length == 1 ? '' : 's'} available',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleExercises.length,
                  itemBuilder: (context, index) {
                    final item = visibleExercises[index];
                    final path = (item['path'] as String?) ?? '';
                    final fileName = path.split('/').isNotEmpty
                        ? path.split('/').last.replaceAll('.json', '')
                        : 'exercise';
                    final data = item['data'] as Map<String, dynamic>?;
                    final imagePath = item['image'] as String?;
                    final subtitle = data?['name'] ?? data?['title'] ?? '';

                    return InkWell(
                      onTap: () => _openExercise(item),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 220,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imagePath != null
                                    ? Image.asset(
                                        imagePath,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(
                                            Icons.fitness_center,
                                            size: 36,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fileName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != '')
                              Text(
                                subtitle,
                                style: AppTextStyles.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMealCard(String title, String calories, Color color) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Icon(Icons.restaurant, size: 50)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(calories, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildAdditionalExercises() {
    final additionalExercises = _visibleExercises.skip(2).take(3).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ADDITIONAL EXERCISE',
              style: AppTextStyles.heading3.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (additionalExercises.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'No additional exercises available',
              style: AppTextStyles.bodySmall,
            ),
          )
        else
          ...additionalExercises.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == additionalExercises.length - 1 ? 0 : 12,
              ),
              child: _buildAdditionalExerciseItem(item),
            );
          }),
      ],
    );
  }

  Widget _buildAdditionalExerciseItem(Map<String, dynamic> item) {
    final title = _exerciseTitle(item);
    final calories = _exerciseCalories(item);
    final duration = _exerciseDuration(item);
    final level = _exerciseLevel(item);
    final imagePath = item['image'] as String?;

    return InkWell(
      onTap: () => _openExercise(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: imagePath != null
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.fitness_center,
                            color: AppColors.white,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.fitness_center,
                          color: AppColors.white,
                        ),
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(calories, style: AppTextStyles.bodySmall),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 14),
                      const SizedBox(width: 4),
                      Text(duration, style: AppTextStyles.bodySmall),
                    ],
                  ),
                  Text(level, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: AppColors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: AppColors.white,
                      size: 35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('$_userName !', style: AppTextStyles.heading3),
                  Text('Basic member', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            _buildDrawerItem(
              Icons.dashboard,
              'Dashboard',
              () => _handleDrawerDashboard(),
            ),
            _buildDrawerItem(
              Icons.show_chart,
              'My Progress',
              () => _handleDrawerMyProgress(),
            ),
            _buildDrawerItem(
              Icons.fitness_center,
              'Training',
              () => _handleDrawerTraining(),
            ),

            // _buildDrawerItem(
            //   Icons.notifications,
            //   'Notification',
            //   () => _handleDrawerNotification(),
            // ),
            // _buildDrawerItem(
            //   Icons.favorite,
            //   'My Favorites',
            //   () => _handleDrawerFavorites(),
            // ),
            _buildDrawerItem(
              Icons.settings,
              'App Settings',
              () => _handleDrawerSettings(),
            ),
            _buildDrawerItem(
              Icons.phone,
              'Contact Support',
              () => _handleDrawerContactSupport(),
            ),
            const Divider(),
            _buildDrawerItem(Icons.logout, 'Sign Out', _handleLogout),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final apiService = ApiService();
    await apiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }

  void _closeDrawer() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _showDrawerInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _handleDrawerDashboard() {
    _closeDrawer();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  void _handleDrawerMyProgress() {
    _closeDrawer();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MyProgressScreen()));
  }

  void _handleDrawerTraining() {
    _closeDrawer();
    setState(() {
      _selectedIndex = 2;
    });
  }

  Future<void> _handleDrawerCategories() async {
    _closeDrawer();
    if (!mounted) return;

    final result = await Navigator.of(context).push<FiltersPlanResult>(
      MaterialPageRoute(
        builder: (_) => FiltersPlanScreen(
          initialCategory: _selectedCategory,
          initialLevel: _selectedLevel,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _selectedIndex = 0;
      _selectedCategory = result.category;
      _selectedLevel = result.level;
    });
  }

  void _handleDrawerNotification() {
    _closeDrawer();
    _showDrawerInfo('Notifications will be added soon');
  }

  void _handleDrawerFavorites() {
    _closeDrawer();
    _showDrawerInfo('Favorites will be added soon');
  }

  void _handleDrawerSettings() {
    _closeDrawer();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AppSettingsScreen()));
  }

  Future<void> _handleDrawerContactSupport() async {
    _closeDrawer();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Contact Support'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: support@trainingup.app'),
              SizedBox(height: 8),
              Text('Phone: +20 100 000 0000'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            // Refresh profile whenever the user opens the profile tab
            if (index == 3) {
              _profileRefreshTrigger++;
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Meal Plans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Exercise',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
