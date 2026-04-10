import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile_setup_model.dart';
import '../utils/app_styles.dart';
import '../widgets/custom_button.dart';

class ProfileSetupProvider extends ChangeNotifier {
  final ProfileSetupModel _profile = ProfileSetupModel();

  ProfileSetupModel get profile => _profile;

  void setAge(int age) {
    _profile.age = age;
    notifyListeners();
  }

  void setCurrentWeight(double weight, String unit) {
    _profile.currentWeight = weight;
    _profile.weightUnit = unit;
    notifyListeners();
  }

  void setGoalWeight(double weight, String unit) {
    _profile.goalWeight = weight;
    _profile.weightUnit = unit;
    notifyListeners();
  }

  void setHeight(double height, String unit) {
    _profile.height = height;
    _profile.heightUnit = unit;
    notifyListeners();
  }

  void setFitnessLevel(String level) {
    _profile.fitnessLevel = level;
    notifyListeners();
  }

  void setGoal(String goal) {
    _profile.goal = goal;
    notifyListeners();
  }
}

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete profile setup
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/final-onboarding', (route) => false);
    }
  }

  void _skipAll() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/final-onboarding', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileSetupProvider(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          if (_currentStep > 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      TextButton(
                        onPressed: _skipAll,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    children: [
                      _AgeStep(onNext: _nextStep),
                      _CurrentWeightStep(onNext: _nextStep),
                      _GoalWeightStep(onNext: _nextStep),
                      _HeightStep(onNext: _nextStep),
                      _FitnessLevelStep(onNext: _nextStep),
                      _GoalStep(onNext: _nextStep),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Age Step
class _AgeStep extends StatefulWidget {
  final VoidCallback onNext;

  const _AgeStep({required this.onNext});

  @override
  State<_AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<_AgeStep> {
  int _selectedAge = 27;
  final FixedExtentScrollController _scrollController =
      FixedExtentScrollController(initialItem: 27 - 18);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 1 of 6', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Text(
            'HOW OLD ARE YOU?',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 200,
            child: ListWheelScrollView.useDelegate(
              controller: _scrollController,
              itemExtent: 50,
              perspective: 0.005,
              diameterRatio: 1.2,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedAge = index + 18;
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 83,
                builder: (context, index) {
                  final age = index + 18;
                  final isSelected = age == _selectedAge;
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.black
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$age',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Spacer(),
          CustomButton(
            text: 'NEXT STEPS',
            onPressed: () {
              context.read<ProfileSetupProvider>().setAge(_selectedAge);
              widget.onNext();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Current Weight Step
class _CurrentWeightStep extends StatefulWidget {
  final VoidCallback onNext;

  const _CurrentWeightStep({required this.onNext});

  @override
  State<_CurrentWeightStep> createState() => _CurrentWeightStepState();
}

class _CurrentWeightStepState extends State<_CurrentWeightStep> {
  String _selectedUnit = 'KG';
  final TextEditingController _weightController = TextEditingController(
    text: '87',
  );

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 2 of 6', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Text(
            'HOW MUCH DO YOU WEIGHT?',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildUnitButton('LBS'), _buildUnitButton('KG')],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 250,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.heading1,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      Text(
                        _selectedUnit.toLowerCase(),
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          CustomButton(
            text: 'NEXT STEPS',
            onPressed: () {
              final weight = double.tryParse(_weightController.text) ?? 0;
              context.read<ProfileSetupProvider>().setCurrentWeight(
                weight,
                _selectedUnit.toLowerCase(),
              );
              widget.onNext();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUnitButton(String unit) {
    final isSelected = _selectedUnit == unit;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUnit = unit;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          unit,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// Goal Weight Step
class _GoalWeightStep extends StatefulWidget {
  final VoidCallback onNext;

  const _GoalWeightStep({required this.onNext});

  @override
  State<_GoalWeightStep> createState() => _GoalWeightStepState();
}

class _GoalWeightStepState extends State<_GoalWeightStep> {
  String _selectedUnit = 'KG';
  final TextEditingController _weightController = TextEditingController(
    text: '60',
  );

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 3 of 6', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Text(
            'WHAT\'S YOUR GOAL WEIGHT?',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildUnitButton('LBS'), _buildUnitButton('KG')],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 250,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.heading1,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      Text(
                        _selectedUnit.toLowerCase(),
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          CustomButton(
            text: 'NEXT STEPS',
            onPressed: () {
              final weight = double.tryParse(_weightController.text) ?? 0;
              context.read<ProfileSetupProvider>().setGoalWeight(
                weight,
                _selectedUnit.toLowerCase(),
              );
              widget.onNext();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUnitButton(String unit) {
    final isSelected = _selectedUnit == unit;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUnit = unit;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          unit,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// Height Step
class _HeightStep extends StatefulWidget {
  final VoidCallback onNext;

  const _HeightStep({required this.onNext});

  @override
  State<_HeightStep> createState() => _HeightStepState();
}

class _HeightStepState extends State<_HeightStep> {
  String _selectedUnit = 'CM';
  final TextEditingController _heightController = TextEditingController(
    text: '85',
  );

  @override
  void dispose() {
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 4 of 6', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Text(
            'HOW MUCH DO YOU HEIGHT?',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildUnitButton('FEET'),
                      _buildUnitButton('CM'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 250,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heightController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.heading1,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      Text(
                        _selectedUnit.toLowerCase(),
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          CustomButton(
            text: 'NEXT STEPS',
            onPressed: () {
              final height = double.tryParse(_heightController.text) ?? 0;
              context.read<ProfileSetupProvider>().setHeight(
                height,
                _selectedUnit.toLowerCase(),
              );
              widget.onNext();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUnitButton(String unit) {
    final isSelected = _selectedUnit == unit;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUnit = unit;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          unit,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// Fitness Level Step
class _FitnessLevelStep extends StatefulWidget {
  final VoidCallback onNext;

  const _FitnessLevelStep({required this.onNext});

  @override
  State<_FitnessLevelStep> createState() => _FitnessLevelStepState();
}

class _FitnessLevelStepState extends State<_FitnessLevelStep> {
  String _selectedLevel = 'beginner';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 5 of 6', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Text(
            'WHAT\'S YOUR FITNESS LEVEL?',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 60),
          _buildLevelButton('BEGINNER', 'beginner'),
          const SizedBox(height: 16),
          _buildLevelButton('Intermediate', 'intermediate'),
          const SizedBox(height: 16),
          _buildLevelButton('Advanced', 'advanced'),
          const Spacer(),
          CustomButton(
            text: 'NEXT STEPS',
            onPressed: () {
              context.read<ProfileSetupProvider>().setFitnessLevel(
                _selectedLevel,
              );
              widget.onNext();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLevelButton(String label, String value) {
    final isSelected = _selectedLevel == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLevel = value;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.black : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// Goal Step
class _GoalStep extends StatefulWidget {
  final VoidCallback onNext;

  const _GoalStep({required this.onNext});

  @override
  State<_GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends State<_GoalStep> {
  String _selectedGoal = 'improve_fitness';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 6 of 6', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Text(
            'WHAT\'S YOUR GOAL',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 60),
          _buildGoalButton('Weight loss', 'weight_loss', Icons.scale),
          const SizedBox(height: 16),
          _buildGoalButton('Gain muscle', 'gain_muscle', Icons.fitness_center),
          const SizedBox(height: 16),
          _buildGoalButton(
            'Improve fitness',
            'improve_fitness',
            Icons.trending_up,
          ),
          const Spacer(),
          CustomButton(
            text: 'FINISH STEPS',
            onPressed: () {
              context.read<ProfileSetupProvider>().setGoal(_selectedGoal);
              widget.onNext();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGoalButton(String label, String value, IconData icon) {
    final isSelected = _selectedGoal == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = value;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.black : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
