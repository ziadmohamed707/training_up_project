import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_styles.dart';
import 'full_exercise_screen.dart';

class MealPlansScreen extends StatefulWidget {
  final bool embedded;

  const MealPlansScreen({super.key, this.embedded = false});

  @override
  State<MealPlansScreen> createState() => _MealPlansScreenState();
}

class _MealPlansScreenState extends State<MealPlansScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  Map<String, dynamic> _normalizeRecipe(Map<dynamic, dynamic> e) {
    final map = e.map((k, v) => MapEntry(k.toString(), v));
    map.putIfAbsent(
      'Category',
      () => (e['Category'] ?? e['category'] ?? '').toString(),
    );
    map.putIfAbsent(
      'Cuisine',
      () =>
          (e['Cuisine'] ?? e['name'] ?? e['title'] ?? e['cuisine'] ?? 'Recipe')
              .toString(),
    );
    map.putIfAbsent(
      'Cooking_Time',
      () => (e['Cooking_Time'] ?? e['cooking_time'] ?? e['time'] ?? '-')
          .toString(),
    );
    map.putIfAbsent(
      'Difficulty',
      () =>
          (e['Difficulty'] ?? e['difficulty'] ?? e['level'] ?? '-').toString(),
    );
    map.putIfAbsent(
      'Serving_Size',
      () => (e['Serving_Size'] ?? e['serving_size'] ?? e['servings'] ?? '-')
          .toString(),
    );
    map.putIfAbsent(
      'Ingredients',
      () => (e['Ingredients'] ?? e['ingredients'] ?? e['description'] ?? '')
          .toString(),
    );
    map.putIfAbsent(
      'Cooking_Method',
      () => (e['Cooking_Method'] ?? e['cooking_method'] ?? e['method'] ?? '')
          .toString(),
    );
    // cook_steps: the API returns a List<String> of numbered steps
    final rawSteps = e['cook_steps'] ?? e['Cook_Steps'];
    map['cook_steps'] = rawSteps is List
        ? List<String>.from(rawSteps.map((s) => s.toString()))
        : <String>[];
    return map;
  }

  dynamic _recipeId(Map<String, dynamic> recipe) {
    return recipe['id'] ?? recipe['recipe_id'] ?? recipe['pk'];
  }

  Future<void> _openRecipeDetails(Map<String, dynamic> recipe) async {
    final id = _recipeId(recipe);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe details are not available.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _apiService.getRecipeDetails(id);
    if (!mounted) return;
    Navigator.of(context).pop();

    Map<String, dynamic> details = recipe;
    if (result['success'] == true && result['data'] is Map) {
      details = _normalizeRecipe(Map<String, dynamic>.from(result['data']));
    }

    final title = (details['Cuisine'] ?? details['name'] ?? 'Recipe')
        .toString();
    final category = (details['Category'] ?? '-').toString();
    final meta = _subtitleMeta(details);
    final ingredients = (details['Ingredients'] ?? '').toString();
    final method = (details['Cooking_Method'] ?? '').toString();
    final cookSteps = details['cook_steps'] is List<String>
        ? details['cook_steps'] as List<String>
        : <String>[];

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.restaurant_menu, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      category,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(meta, style: AppTextStyles.bodySmall),
                if (ingredients.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Ingredients',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(ingredients, style: AppTextStyles.bodyMedium),
                ],
                if (cookSteps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Steps',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...cookSteps
                      .asMap()
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key + 1}. ',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ] else if (method.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Method',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(method, style: AppTextStyles.bodyMedium),
                ],
              ],
            ),
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

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.getRecipes();

      if (!result['success']) {
        if (mounted) {
          setState(() {
            _recipes = [];
            _isLoading = false;
          });
        }
        return;
      }

      final decoded = result['data'];

      if (decoded is List) {
        final mapped = decoded
            .whereType<Map>()
            .map((e) => _normalizeRecipe(e))
            .toList();

        if (mounted) {
          setState(() {
            _recipes = mapped;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _categories {
    final values =
        _recipes
            .map((r) => (r['Category'] ?? '').toString().trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['All', ...values];
  }

  List<Map<String, dynamic>> get _filteredRecipes {
    if (_selectedCategory == 'All') return _recipes;
    return _recipes
        .where(
          (r) =>
              (r['Category'] ?? '').toString().toLowerCase() ==
              _selectedCategory.toLowerCase(),
        )
        .toList();
  }

  String _ingredientsPreview(Map<String, dynamic> recipe) {
    final raw = (recipe['Ingredients'] ?? '').toString();
    return raw;
  }

  String _subtitleMeta(Map<String, dynamic> recipe) {
    final time = (recipe['Cooking_Time'] ?? '-').toString();
    final difficulty = (recipe['Difficulty'] ?? '-').toString();
    final serving = (recipe['Serving_Size'] ?? '-').toString();
    return '$difficulty  •  $time min  •  $serving servings';
  }

  Widget _categoryChip(String label) {
    final selected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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

  Widget _recipeTile(Map<String, dynamic> recipe) {
    final cuisine = (recipe['Cuisine'] ?? 'Cuisine').toString();
    final category = (recipe['Category'] ?? 'Meal').toString();
    final method = (recipe['Cooking_Method'] ?? '').toString();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openRecipeDetails(recipe),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    cuisine,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF7FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(category, style: AppTextStyles.bodySmall),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_subtitleMeta(recipe), style: AppTextStyles.bodySmall),
            const SizedBox(height: 8),
            Text(
              _ingredientsPreview(recipe),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium,
            ),
            if (method.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Method: $method', style: AppTextStyles.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecipes;

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
                    'MEAL PLANS',
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
                children: _categories.expand((c) {
                  final isLast = c == _categories.last;
                  return [
                    _categoryChip(c),
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
                        'No meal plans found',
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _recipeTile(filtered[index]),
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
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
            return;
          }
          if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FullExerciseScreen()),
            );
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
