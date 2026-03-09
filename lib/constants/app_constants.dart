/// App Constants - Centralized constants for the application
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Niyot';
  static const String appVersion = '1.0.0';

  // API
  static const int apiTimeout = 30000; // 30 seconds
  static const int apiConnectTimeout = 10000; // 10 seconds

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Animation
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // Debounce
  static const Duration searchDebounce = Duration(milliseconds: 500);

  // Cache
  static const int maxCacheSize = 100;

  // Regex Patterns
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phoneRegex = r'^[0-9]{10,15}$';
  static const String passwordRegex = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$';

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserData = 'user_data';
  static const String keyTheme = 'theme';
  static const String keyLanguage = 'language';
  static const String keyOnboardingCompleted = 'onboarding_completed';

  // Date Formats
  static const String dateFormatDisplay = 'MMM dd, yyyy';
  static const String dateFormatDisplayWithTime = 'MMM dd, yyyy hh:mm a';
  static const String dateFormatApi = 'yyyy-MM-dd';
  static const String dateFormatApiWithTime = 'yyyy-MM-dd HH:mm:ss';
  static const String dateFormatMonthYear = 'MMMM yyyy';
  static const String dateFormatDayMonth = 'dd MMM';
}
