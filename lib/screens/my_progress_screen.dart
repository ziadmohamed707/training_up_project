import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../services/api_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_styles.dart';

class MyProgressScreen extends StatefulWidget {
  const MyProgressScreen({super.key});

  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> {
  final ApiService _apiService = ApiService();
  String _period = 'Today';
  Map<String, dynamic> _summary = const {};
  Map<String, int> _burnedByDate = const {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final summaryResult = await _apiService.getMyExerciseSummary();
      final burnedByDate = await _loadBurnedCaloriesFromHive();

      if (!mounted) return;
      setState(() {
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

  Map<String, dynamic>? _mapFromRaw(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  Future<Map<String, int>> _loadBurnedCaloriesFromHive() async {
    try {
      final box = Hive.box(AppConstants.hiveAppBox);
      final profileRaw = box.get(AppConstants.keyCachedProfileData);
      final profile = _mapFromRaw(profileRaw) ?? const <String, dynamic>{};

      final username = (profile['username'] ?? '').toString().trim();
      final email = (profile['email'] ?? '').toString().trim();
      final userKey = username.isNotEmpty
          ? username.toLowerCase()
          : (email.isNotEmpty ? email.toLowerCase() : 'unknown_user');

      final rootRaw = box.get(AppConstants.keyDailyBurnedCaloriesByUser);
      final root = _mapFromRaw(rootRaw) ?? const <String, dynamic>{};
      final bucket = _mapFromRaw(root[userKey]) ?? const <String, dynamic>{};

      final map = <String, int>{};
      bucket.forEach((key, value) {
        // dates only: YYYY-MM-DD
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
          map[key] = int.tryParse(value.toString()) ?? 0;
        }
      });
      return map;
    } catch (_) {
      return const {};
    }
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

  int _burnedToday() {
    return _burnedForDate(_todayDate());
  }

  int _burnedThisWeek() {
    final now = _todayDate();
    final start = now.subtract(Duration(days: now.weekday - 1));
    var total = 0;
    for (var i = 0; i < 7; i++) {
      total += _burnedForDate(start.add(Duration(days: i)));
    }
    return total;
  }

  int _burnedThisMonth() {
    final now = _todayDate();
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
  }

  int _periodBurnedCalories() {
    switch (_period) {
      case 'Week':
        return _burnedThisWeek();
      case 'Month':
        return _burnedThisMonth();
      default:
        return _burnedToday();
    }
  }

  void _onPeriodSelected(String value) {
    if (_period == value) return;
    setState(() {
      _period = value;
    });
  }

  DateTime _weekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  DateTime _monthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  int _weekOfMonth(DateTime date) {
    final first = _monthStart(date);
    final offset = first.weekday - 1; // Mon=0 .. Sun=6
    return ((date.day + offset - 1) ~/ 7) + 1;
  }

  List<String> _chartDays() {
    final now = _todayDate();
    switch (_period) {
      case 'Month':
        return ['M1', 'M2', 'M3', 'M4'];
      case 'Week':
        return ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7'];
      case 'Today':
      default:
        const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return List.generate(7, (i) {
          final d = now.subtract(Duration(days: 6 - i));
          return names[d.weekday - 1];
        });
    }
  }

  int _chartHighlightIndex(List<String> labels) {
    if (labels.isEmpty) return -1;
    switch (_period) {
      case 'Today':
        return labels.length - 1;
      case 'Week':
        return _todayDate().weekday - 1;
      case 'Month':
        return _weekOfMonth(_todayDate()) - 1;
      default:
        return -1;
    }
  }

  List<double> _chartValues() {
    final now = _todayDate();
    final raw = <double>[];

    switch (_period) {
      case 'Month':
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final weeks = _weekOfMonth(DateTime(now.year, now.month, daysInMonth));
        for (var w = 1; w <= weeks; w++) {
          var total = 0;
          for (var day = 1; day <= daysInMonth; day++) {
            final d = DateTime(now.year, now.month, day);
            if (_weekOfMonth(d) == w) {
              total += _burnedForDate(d);
            }
          }
          raw.add(total.toDouble());
        }
        break;
      case 'Today':
        for (var i = 0; i < 7; i++) {
          final d = now.subtract(Duration(days: 6 - i));
          raw.add(_burnedForDate(d).toDouble());
        }
        break;
      case 'Week':
      default:
        final start = _weekStart(now);
        for (var i = 0; i < 7; i++) {
          raw.add(_burnedForDate(start.add(Duration(days: i))).toDouble());
        }
        break;
    }

    final maxValue = raw.fold<double>(0, (prev, e) => e > prev ? e : prev);
    if (maxValue <= 0) {
      return List<double>.filled(raw.length, 0.08);
    }
    return raw.map((v) => (v / maxValue).clamp(0.08, 1.0)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final completedExercises = (_summary['completed_exercises'] ?? 0) as num;
    final inProgressExercises = (_summary['in_progress_exercises'] ?? 0) as num;
    final startedOrCompleted = (completedExercises + inProgressExercises)
        .toDouble();

    final totalProgress = startedOrCompleted > 0 ? 1.0 : 0.0;
    final inProgressRatio = startedOrCompleted > 0
        ? (inProgressExercises / startedOrCompleted).clamp(0, 1).toDouble()
        : 0.0;
    final completionRatio = startedOrCompleted > 0
        ? (completedExercises / startedOrCompleted).clamp(0, 1).toDouble()
        : 0.0;
    final completionPct = startedOrCompleted > 0
        ? ((completedExercises / startedOrCompleted) * 100)
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
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
                                  'MY PROGRESS',
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
                          const SizedBox(height: 10),
                          Text(
                            'Activity',
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
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
                          _activityChart(),
                          const SizedBox(height: 18),
                          Text(
                            'Measurement',
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 0.92,
                            children: [
                              _MetricCard(
                                icon: Icons.directions_walk,
                                title: 'Total',
                                center: '${startedOrCompleted.toInt()}',
                                unit: 'Exercises',
                                progress: totalProgress,
                              ),
                              _MetricCard(
                                icon: Icons.nights_stay_outlined,
                                title: 'In Progress',
                                center: '${inProgressExercises.toInt()}',
                                unit: 'Exercises',
                                progress: inProgressRatio,
                              ),
                              _WorkoutCard(
                                completed: '${_periodBurnedCalories()}',
                                label: 'kcal burned',
                              ),
                              _MetricCard(
                                icon: Icons.local_fire_department_outlined,
                                title: 'Completed',
                                center: '${completionPct.toStringAsFixed(0)}%',
                                unit: 'Progress',
                                progress: completionRatio,
                              ),
                            ],
                          ),
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
    final selected = _period == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onPeriodSelected(label),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black : const Color(0xFFEAEAEA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _activityChart() {
    final days = _chartDays();
    final values = _chartValues();
    final highlightedIndex = _chartHighlightIndex(days);
    const barWidth = 30.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 230,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final spacing = days.length > 1
                    ? (width - barWidth) / (days.length - 1)
                    : 0.0;

                return Stack(
                  children: [
                    ...List.generate(days.length, (index) {
                      final h = 74 + (values[index] * 96);
                      final highlighted = index == highlightedIndex;
                      return Positioned(
                        left: spacing * index,
                        bottom: 0,
                        child: Container(
                          width: barWidth,
                          height: h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: highlighted
                                ? const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x4D9EDAF0),
                                      Color(0xCC95D3EA),
                                    ],
                                  )
                                : const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFFF0F0F0),
                                      Color(0xFFBDBDBD),
                                    ],
                                  ),
                          ),
                        ),
                      );
                    }),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LinePainter(
                          values: values,
                          barWidth: barWidth,
                        ),
                      ),
                    ),
                    if (highlightedIndex >= 0)
                      Positioned(
                        left:
                            (spacing * highlightedIndex) + (barWidth - 22) / 2,
                        top: 8,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0x666BC8EA),
                            border: Border.all(
                              color: const Color(0xFF9EDAF0),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days
                .map(
                  (d) => SizedBox(
                    width: 40,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: days.indexOf(d) == highlightedIndex
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
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

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String center;
  final String unit;
  final double progress;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.center,
    required this.unit,
    required this.progress,
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
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _RingPainter(progress: progress),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        center,
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(unit, style: AppTextStyles.bodyMedium),
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

class _WorkoutCard extends StatelessWidget {
  final String completed;
  final String label;

  const _WorkoutCard({required this.completed, this.label = 'Excercise'});

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
              const Icon(Icons.sports_gymnastics, size: 18),
              const Spacer(),
              Text(
                'Workout',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Center(
            child: Icon(
              Icons.self_improvement,
              size: 56,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              completed,
              style: AppTextStyles.heading3.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Center(child: Text(label, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
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

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter({required this.progress});

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
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      6.28318 * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final double barWidth;

  _LinePainter({required this.values, this.barWidth = 30});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final path = Path();
    final paint = Paint()
      ..color = const Color(0xFF9EDAF0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final spacing = values.length > 1
        ? (size.width - barWidth) / (values.length - 1)
        : 0.0;

    for (var i = 0; i < values.length; i++) {
      final x = (i * spacing) + (barWidth / 2);
      final y = size.height - (values[i] * (size.height - 60)) - 24;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = ((i - 1) * spacing) + (barWidth / 2);
        final prevY = size.height - (values[i - 1] * (size.height - 60)) - 24;
        final controlX = (prevX + x) / 2;
        path.cubicTo(controlX, prevY, controlX, y, x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
