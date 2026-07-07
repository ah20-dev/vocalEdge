class AppConfig {
  static const String appName = 'Vocal Edge - AI';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-powered vocal coaching app';
  
  // API Configuration
  static const String backendUrl = 'YOUR_BACKEND_URL';
  
  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableBetaFeatures = false;
  
  // App Limits
  static const int maxRecordingDurationSeconds = 300; // 5 minutes
  static const int maxDailyLessons = 5;
  static const int streakResetDays = 7;
}
