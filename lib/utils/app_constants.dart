class AppConstants {
  static const String appName = 'Training Up';
  static const String appTagline = 'We train your body to be\ngreat and fit.';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleCoach = 'coach';
  static const String roleTrainee = 'trainee';

  // Fitness Levels
  static const String beginnerLevel = 'beginner';
  static const String intermediateLevel = 'intermediate';
  static const String advancedLevel = 'advanced';

  // Goals
  static const String goalWeightLoss = 'weight_loss';
  static const String goalGainMuscle = 'gain_muscle';
  static const String goalImproveFitness = 'improve_fitness';

  // SharedPreferences Keys
  static const String keyToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyProfileSetupComplete = 'profile_setup_complete';
  static const String keyCachedProfileData = 'cached_profile_data';
  static const String keyLocalProfileExtras = 'local_profile_extras';
  static const String keyDailyBurnedCaloriesByUser =
      'daily_burned_calories_by_user';

  // Hive
  static const String hiveAppBox = 'app_cache_box';
}
