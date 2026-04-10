import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_styles.dart';
import '../utils/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'PERFECT BODY\nDOING ',
      highlightedText: 'CROSSFIT',
      subtitle: 'EXERCISES',
      image: 'assets/images/onboarding1.png',
    ),
    OnboardingItem(
      title: 'SHOT STRONG\n',
      highlightedText: 'TIMELESS',
      subtitle: 'MAN TRAINING',
      image: 'assets/images/onboarding2.png',
    ),
    OnboardingItem(
      title: 'HEALTHY MUSCULAR\n',
      highlightedText: 'SPORTSWOMAN',
      subtitle: 'STANDING',
      image: 'assets/images/onboarding3.png',
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingComplete, true);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(_items[index]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _items.length,
                      effect: const ExpandingDotsEffect(
                        activeDotColor: AppColors.primary,
                        dotColor: Colors.grey,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: const Text(
                            'SKIP',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (_currentPage == _items.length - 1) {
                              _completeOnboarding();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Text(
                            _currentPage == _items.length - 1 ? 'DONE' : 'NEXT',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.fitness_center,
                size: 100,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 60),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: item.title,
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 28,
                    height: 1.2,
                  ),
                ),
                TextSpan(
                  text: item.highlightedText,
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 28,
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1.copyWith(fontSize: 28),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingItem {
  final String title;
  final String highlightedText;
  final String subtitle;
  final String image;

  OnboardingItem({
    required this.title,
    required this.highlightedText,
    required this.subtitle,
    required this.image,
  });
}
