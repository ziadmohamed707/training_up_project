import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../services/api_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_styles.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  String _period = 'Today';
  Map<String, dynamic> _profile = const {};
  Map<String, dynamic> _summary = const {};
  Map<String, int> _burnedByDate = const {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Map<String, dynamic>? _mapFromRaw(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  int _burnedForDate(DateTime date) {
    return _burnedByDate[_dateKey(date)] ?? 0;
  }

  String _currentUserStorageKey(Map<String, dynamic> profile) {
    final username = (profile['username'] ?? '').toString().trim();
    if (username.isNotEmpty) return username.toLowerCase();
    final email = (profile['email'] ?? '').toString().trim();
    if (email.isNotEmpty) return email.toLowerCase();
    return 'unknown_user';
  }

  Future<Map<String, int>> _loadBurnedCaloriesFromHive(
    Map<String, dynamic> profile,
  ) async {
    try {
      final box = Hive.box(AppConstants.hiveAppBox);
      final rootRaw = box.get(AppConstants.keyDailyBurnedCaloriesByUser);
      final root = _mapFromRaw(rootRaw) ?? const <String, dynamic>{};
      final userKey = _currentUserStorageKey(profile);
      final bucket = _mapFromRaw(root[userKey]) ?? const <String, dynamic>{};

      final map = <String, int>{};
      bucket.forEach((key, value) {
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
          map[key] = int.tryParse(value.toString()) ?? 0;
        }
      });
      return map;
    } catch (_) {
      return const {};
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final profileResult = await _apiService.getProfile();
      final summaryResult = await _apiService.getMyExerciseSummary();

      var profileData = <String, dynamic>{};
      if (profileResult['success'] == true && profileResult['data'] is Map) {
        profileData = Map<String, dynamic>.from(profileResult['data'] as Map);
      } else {
        try {
          final box = Hive.box(AppConstants.hiveAppBox);
          final cached = _mapFromRaw(
            box.get(AppConstants.keyCachedProfileData),
          );
          if (cached != null) profileData = cached;
        } catch (_) {
          // ignore cache read errors
        }
      }

      final burnedByDate = await _loadBurnedCaloriesFromHive(profileData);

      if (!mounted) return;
      setState(() {
        _profile = profileData;
        _summary = Map<String, dynamic>.from(
          summaryResult['success'] == true && summaryResult['data'] is Map
              ? summaryResult['data'] as Map
              : const {},
        );
        _burnedByDate = burnedByDate;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _periodBurnedCalories() {
    final now = _todayDate();
    switch (_period) {
      case 'Week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        var total = 0;
        for (var i = 0; i < 7; i++) {
          total += _burnedForDate(start.add(Duration(days: i)));
        }
        return total;
      case 'Month':
        final start = DateTime(now.year, now.month, 1);
        final nextMonth = now.month == 12
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, now.month + 1, 1);
        final days = nextMonth.difference(start).inDays;
        var total = 0;
        for (var i = 0; i < days; i++) {
          total += _burnedForDate(start.add(Duration(days: i)));
        }
        return total;
      default:
        return _burnedForDate(now);
    }
  }

  int _periodActiveDays() {
    final now = _todayDate();
    switch (_period) {
      case 'Week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        var active = 0;
        for (var i = 0; i < 7; i++) {
          if (_burnedForDate(start.add(Duration(days: i))) > 0) active++;
        }
        return active;
      case 'Month':
        final start = DateTime(now.year, now.month, 1);
        final nextMonth = now.month == 12
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, now.month + 1, 1);
        final days = nextMonth.difference(start).inDays;
        var active = 0;
        for (var i = 0; i < days; i++) {
          if (_burnedForDate(start.add(Duration(days: i))) > 0) active++;
        }
        return active;
      default:
        return _burnedForDate(now) > 0 ? 1 : 0;
    }
  }

  int _periodDaysCount() {
    final now = _todayDate();
    switch (_period) {
      case 'Week':
        return 7;
      case 'Month':
        final start = DateTime(now.year, now.month, 1);
        final nextMonth = now.month == 12
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, now.month + 1, 1);
        return nextMonth.difference(start).inDays;
      default:
        return 1;
    }
  }

  double _safeProgress(num value, num max) {
    if (max <= 0) return 0.0;
    return (value / max).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final completed = (_summary['completed_exercises'] ?? 0) as num;
    final inProgress = (_summary['in_progress_exercises'] ?? 0) as num;
    final startedOrCompleted = completed + inProgress;

    final age = (_profile['age'] ?? 0) as num;
    final weight = (_profile['weight'] ?? 0) as num;
    final height = (_profile['height'] ?? 0) as num;
    final burned = _periodBurnedCalories();
    final activeDays = _periodActiveDays();
    final completionPct = startedOrCompleted > 0
        ? ((completed / startedOrCompleted) * 100)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 20,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'DASHBOARD',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.heading3.copyWith(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _periodChip('Today'),
                              const SizedBox(width: 10),
                              _periodChip('Week'),
                              const SizedBox(width: 10),
                              _periodChip('Month'),
                            ],
                          ),
                          const SizedBox(height: 18),
                          GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 0.91,
                            children: [
                              _DashboardMetricCard(
                                icon: Icons.monitor_weight_outlined,
                                title: 'Weight',
                                centerTop: weight > 0
                                    ? weight.toStringAsFixed(1)
                                    : '--',
                                centerBottom: 'kg',
                                progress: _safeProgress(weight, 150),
                                ringColor: const Color(0xFF95D6EC),
                              ),
                              _DashboardMetricCard(
                                icon: Icons.height,
                                title: 'Height',
                                centerTop: height > 0
                                    ? height.toStringAsFixed(0)
                                    : '--',
                                centerBottom: 'cm',
                                progress: _safeProgress(height, 220),
                                ringColor: const Color(0xFF95D6EC),
                              ),
                              _HeartCard(
                                value: completionPct.toStringAsFixed(0),
                                unit: '% done',
                              ),
                              _DashboardMetricCard(
                                icon: Icons.local_fire_department_outlined,
                                title: 'Calories',
                                centerTop: '$burned',
                                centerBottom: 'kcal',
                                progress: _safeProgress(burned, 1200),
                                ringColor: const Color(0xFF95D6EC),
                              ),
                              _DashboardMetricCard(
                                icon: Icons.fitness_center,
                                title: 'Exercises',
                                centerTop: '${startedOrCompleted.toInt()}',
                                centerBottom: 'count',
                                progress: _safeProgress(startedOrCompleted, 20),
                                ringColor: const Color(0xFF95D6EC),
                              ),
                              _DashboardMetricCard(
                                icon: Icons.today_outlined,
                                title: 'Active Days',
                                centerTop: '$activeDays',
                                centerBottom: '/ ${_periodDaysCount()}',
                                progress: _safeProgress(
                                  activeDays,
                                  _periodDaysCount(),
                                ),
                                ringColor: const Color(0xFF95D6EC),
                              ),
                            ],
                          ),
                          if (age > 0) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Age: ${age.toInt()} years',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            _bottomNavMock(),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(String label) {
    final isSelected = _period == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = label),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : const Color(0xFFEAEAEA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNavMock() {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.22)),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_outlined, label: 'Home', selected: true),
          _NavItem(icon: Icons.restaurant_menu, label: 'Meal Plans'),
          _NavItem(icon: Icons.fitness_center, label: 'Exercise'),
          _NavItem(icon: Icons.person_outline, label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String centerTop;
  final String centerBottom;
  final double progress;
  final Color ringColor;

  const _DashboardMetricCard({
    required this.icon,
    required this.title,
    required this.centerTop,
    required this.centerBottom,
    required this.progress,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const Spacer(),
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 108,
              height: 108,
              child: CustomPaint(
                painter: _RingPainter(progress: progress, ringColor: ringColor),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        centerTop,
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        centerBottom,
                        style: TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _HeartCard extends StatelessWidget {
  final String value;
  final String unit;

  const _HeartCard({required this.value, this.unit = 'Progress'});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_border, size: 18),
              const Spacer(),
              Text(
                'Completion',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 52,
            child: CustomPaint(painter: _HeartWavePainter()),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              value,
              style: AppTextStyles.heading3.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Center(child: Text(unit, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;

  _RingPainter({required this.progress, required this.ringColor});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFFDCDCDC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.57,
        6.28318 * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor;
  }
}

class _HeartWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF94B657)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final mutedPaint = Paint()
      ..color = const Color(0xFFC5C5C5)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final majorXs = [0.06, 0.16, 0.24, 0.36, 0.50, 0.58, 0.70, 0.80, 0.90];
    final majorHeights = [0.36, 0.62, 0.48, 0.72, 0.52, 0.66, 0.58, 0.46, 0.54];

    for (var i = 0; i < majorXs.length; i++) {
      final x = size.width * majorXs[i];
      final h = size.height * majorHeights[i];
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        linePaint,
      );
    }

    final minorXs = [0.11, 0.30, 0.43, 0.64, 0.75, 0.86];
    final minorHeights = [0.22, 0.28, 0.18, 0.24, 0.20, 0.16];

    for (var i = 0; i < minorXs.length; i++) {
      final x = size.width * minorXs[i];
      final h = size.height * minorHeights[i];
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        mutedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: selected ? Colors.black : Colors.grey),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? Colors.black : Colors.grey,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
