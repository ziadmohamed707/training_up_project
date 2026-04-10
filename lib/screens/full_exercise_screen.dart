import 'package:flutter/material.dart';

import '../services/exercise_service.dart';
import '../utils/app_styles.dart';
import 'exercise_detail_screen.dart';
import 'meal_plans_screen.dart';

class FullExerciseScreen extends StatefulWidget {
  final bool embedded;

  const FullExerciseScreen({super.key, this.embedded = false});

  @override
  State<FullExerciseScreen> createState() => _FullExerciseScreenState();
}

class _FullExerciseScreenState extends State<FullExerciseScreen> {
  static const List<String> _tabs = [
    'Cardio',
    'Olympic Weightlifting',
    'Plyometrics',
    'Powerlifting',
    'Strength',
    'Stretching',
    'Strongman',
  ];

  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = true;
  String _selectedTab = 'Cardio';

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);

    try {
      final service = ExerciseService();
      final keys = await service.listJsonKeys();
      final loaded = <Map<String, dynamic>>[];

      for (final key in keys) {
        if (!mounted) break;
        final item = await service.loadExerciseByKey(key);
        if (item != null) loaded.add(item);
      }

      if (mounted) {
        setState(() {
          _exercises = loaded;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _title(Map<String, dynamic> item) {
    final data = item['data'] as Map<String, dynamic>? ?? const {};
    final raw = (data['name'] ?? item['path'] ?? 'Exercise').toString();
    final base = raw.contains('/') ? raw.split('/').last : raw;
    return base.replaceAll('.json', '').replaceAll('_', ' ');
  }

  String _level(Map<String, dynamic> item) {
    final data = item['data'] as Map<String, dynamic>? ?? const {};
    final raw = (data['level'] ?? 'beginner').toString();
    if (raw.isEmpty) return 'Beginner';
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  String _duration(Map<String, dynamic> item) {
    final data = item['data'] as Map<String, dynamic>? ?? const {};
    final instructions = data['instructions'];
    final count = instructions is List
        ? instructions.whereType<String>().length
        : 0;
    final minutes = (count * 3).clamp(5, 60);
    return '$minutes min';
  }

  String _kcal(Map<String, dynamic> item) {
    final data = item['data'] as Map<String, dynamic>? ?? const {};
    final instructions = data['instructions'];
    final count = instructions is List
        ? instructions.whereType<String>().length
        : 0;
    final minutes = (count * 3).clamp(5, 60);
    return '${90 + (minutes * 3)} kcal';
  }

  bool _matchesTab(Map<String, dynamic> item) {
    final data = item['data'] as Map<String, dynamic>? ?? const {};
    final path = (item['path'] as String? ?? '').toLowerCase();
    final category = (data['category'] ?? '').toString().toLowerCase();
    final normalizedTab = _selectedTab.toLowerCase().replaceAll(' ', '_');

    return path.contains('/$normalizedTab/') ||
        category.contains(_selectedTab.toLowerCase()) ||
        category.contains(normalizedTab.replaceAll('_', ' '));
  }

  List<Map<String, dynamic>> get _filteredExercises =>
      _exercises.where(_matchesTab).toList();

  Future<void> _openExercise(Map<String, dynamic> item) async {
    final service = ExerciseService();
    final path = (item['path'] as String?) ?? '';
    final imagePath = item['image'] as String?;
    final data = item['data'] as Map<String, dynamic>?;

    Map<String, dynamic>? fresh;
    if (path.isNotEmpty) {
      fresh = await service.loadExerciseByKey(path);
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          data: (fresh?['data'] as Map<String, dynamic>?) ?? data,
          path: path,
          imagePath: (fresh?['image'] as String?) ?? imagePath,
        ),
      ),
    );
  }

  Widget _tabChip(String label) {
    final selected = _selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _exerciseRow(Map<String, dynamic> item) {
    final imagePath = item['image'] as String?;
    final isNetworkImage =
        imagePath != null &&
        (imagePath.startsWith('http://') || imagePath.startsWith('https://'));

    return InkWell(
      onTap: () => _openExercise(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 92,
                height: 92,
                child: imagePath != null
                    ? (isNetworkImage
                          ? Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.fitness_center),
                              ),
                            )
                          : Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.fitness_center),
                              ),
                            ))
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.fitness_center),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(item),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(_kcal(item), style: AppTextStyles.bodySmall),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 12, color: Colors.grey[300]),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time, size: 14),
                      const SizedBox(width: 4),
                      Text(_duration(item), style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(_level(item), style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExercises;

    final content = SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          children: [
            Row(
              children: [
                if (widget.embedded)
                  const SizedBox(width: 48)
                else
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                Expanded(
                  child: Text(
                    'FULL EXERCISE',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.expand((tab) {
                  final isLast = tab == _tabs.last;
                  return [
                    _tabChip(tab),
                    if (!isLast) const SizedBox(width: 10),
                  ];
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No exercises for $_selectedTab',
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 20),
                      itemBuilder: (context, index) =>
                          _exerciseRow(filtered[index]),
                    ),
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Container(color: const Color(0xFFF7F7F7), child: content);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: content,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
            return;
          }
          if (index == 1) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MealPlansScreen()));
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
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
