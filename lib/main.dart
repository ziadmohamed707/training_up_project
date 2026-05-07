import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/final_onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'utils/app_constants.dart';
import 'utils/app_styles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final appDocDir = await getApplicationDocumentsDirectory();
  final hiveDir = Directory('${appDocDir.path}/.training_up_hive');
  if (!await hiveDir.exists()) {
    await hiveDir.create(recursive: true);
  }

  Hive.init(hiveDir.path);
  await Hive.openBox(AppConstants.hiveAppBox);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Training Up',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.white,
      ),
      initialRoute: '/home',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/final-onboarding': (context) => const FinalOnboardingScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
