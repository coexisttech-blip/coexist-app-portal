/// Application-wide constants
class AppConstants {
  // App info
  static const String appName = 'CO2 Exist';
  static String appVersion = '';

  // Environment (set via --dart-define-from-file). No default: must be supplied.
  static const String env = String.fromEnvironment('ENV');
  static bool get isStaging => env == 'staging';

  // Supabase config — must be supplied via --dart-define-from-file=config/<env>.json
  // No defaults: a missing flag should fail loudly rather than silently hit prod.
  static const String baseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String apiKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String serviceApiKey = String.fromEnvironment('SUPABASE_SERVICE_KEY');

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String onboardingCompleteKey = 'onboarding_complete';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Pagination
  static const int defaultPageSize = 20;

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
}
