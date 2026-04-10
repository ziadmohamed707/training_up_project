import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_styles.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';

class FinalOnboardingScreen extends StatelessWidget {
  const FinalOnboardingScreen({super.key});

  Future<void> _getStarted(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyProfileSetupComplete, true);

    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const Spacer(),
                Text(
                  'LET\'S GET STARTED',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  'The standard chunk of Lorem Ipsum\nused since the 1500s is reproduced below\nfor those interested.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.amber[600],
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.fitness_center,
                      size: 100,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Sculpt your ',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: 'ideal body, ',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      TextSpan(
                        text: 'free your\ntrue self, transform your life.',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                CustomButton(
                  text: 'GET STARTED!',
                  onPressed: () => _getStarted(context),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
