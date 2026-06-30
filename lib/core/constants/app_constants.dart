/// Application-wide constants
class AppConstants {
  // App info
  static const String appName = 'CO2 Exist';
  static const String appVersion = '1.4.3';

  // Environment (set via --dart-define-from-file)
  static const String env = String.fromEnvironment('ENV', defaultValue: 'production');
  static bool get isStaging => env == 'staging';

  // Supabase config (overridden via --dart-define-from-file=config/staging.json)
  static const String baseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hvgxicauyuchtqcdmdgp.supabase.co',
  );
  static const String apiKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2Z3hpY2F1eXVjaHRxY2RtZGdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYyNTI0NDgsImV4cCI6MjA2MTgyODQ0OH0.5C6hBjilmgfFdXk5RLZi6cfQBzkdFNahEffXmda3vVA',
  );
  static const String serviceApiKey = String.fromEnvironment(
    'SUPABASE_SERVICE_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2Z3hpY2F1eXVjaHRxY2RtZGdwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NjI1MjQ0OCwiZXhwIjoyMDYxODI4NDQ4fQ.xgXF-qAIBROKRuYt1F27ql0SWULXKRIzU0wjPrwPSHs',
  );

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
