import 'package:flutter/material.dart';

import '../utils/app_styles.dart';

class FiltersPlanResult {
  final String? category;
  final String? level;
  final String? meal;
  final String? time;
  final String? exercise;

  const FiltersPlanResult({
    this.category,
    this.level,
    this.meal,
    this.time,
    this.exercise,
  });
}

class FiltersPlanScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialLevel;

  const FiltersPlanScreen({super.key, this.initialCategory, this.initialLevel});

  @override
  State<FiltersPlanScreen> createState() => _FiltersPlanScreenState();
}

class _FiltersPlanScreenState extends State<FiltersPlanScreen> {
  String? _selectedCategory;
  String? _selectedExercise = 'All';
  String? _selectedLevel;
  String? _selectedMeal = 'Breakfast';
  String? _selectedTime = '15-30 Min';

  static const List<String> _categories = [
    'All',
    'Cardio',
    'Warm-Up',
    'Running',
    'Yoga',
    'Streching',
    'Stretch',
    'Arms',
    'Boxing',
  ];

  static const List<String> _exercise = [
    'All',
    'Biceps',
    'Back',
    'Shoulders',
    'Triceps',
    'Legs',
  ];

  static const List<String> _levels = ['Beginner', 'Average', 'Hard'];
  static const List<String> _meals = ['Breakfast', 'Lunch', 'Dinner'];
  static const List<String> _times = ['10-15 Min', '15-30 Min', '30-45 Min'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
    _selectedLevel = widget.initialLevel ?? 'Beginner';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      'FILTERS PLAN',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearAll,
                    child: Text(
                      'Clear  All',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _sectionTitle('CATEGORIES'),
              const SizedBox(height: 10),
              _wrapChips(
                _categories,
                selected: _selectedCategory,
                onSelect: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 16),
              _sectionTitle('EXERCISE'),
              const SizedBox(height: 10),
              _wrapChips(
                _exercise,
                selected: _selectedExercise,
                onSelect: (v) => setState(() => _selectedExercise = v),
              ),
              const SizedBox(height: 16),
              _sectionTitle('LEVEL'),
              const SizedBox(height: 10),
              _wrapChips(
                _levels,
                selected: _selectedLevel,
                onSelect: (v) => setState(() => _selectedLevel = v),
              ),
              const SizedBox(height: 16),
              _sectionTitle('MEAL'),
              const SizedBox(height: 10),
              _wrapChips(
                _meals,
                selected: _selectedMeal,
                onSelect: (v) => setState(() => _selectedMeal = v),
              ),
              const SizedBox(height: 16),
              _sectionTitle('TIME'),
              const SizedBox(height: 10),
              _wrapChips(
                _times,
                selected: _selectedTime,
                onSelect: (v) => setState(() => _selectedTime = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8CCFE3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: _apply,
                  child: Text(
                    'APPLY FILTERS',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _wrapChips(
    List<String> values, {
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.map((item) {
        final isSelected = selected == item;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: Container(
            constraints: const BoxConstraints(minWidth: 90),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : const Color(0xFFEAEAEA),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              item,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _clearAll() {
    setState(() {
      _selectedCategory = 'All';
      _selectedExercise = 'All';
      _selectedLevel = 'Beginner';
      _selectedMeal = 'Breakfast';
      _selectedTime = '15-30 Min';
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      FiltersPlanResult(
        category: (_selectedCategory == null || _selectedCategory == 'All')
            ? null
            : _selectedCategory,
        level: _selectedLevel,
        meal: _selectedMeal,
        time: _selectedTime,
        exercise: _selectedExercise,
      ),
    );
  }
}
