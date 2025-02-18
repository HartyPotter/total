enum Environment { dev, prod }

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  static Environment _environment = Environment.dev;
  static bool get isDev => _environment == Environment.dev;
  static bool get isProd => _environment == Environment.prod;

  // Firebase Configuration
  static const String devProjectId = 'new-total-c0e19';
  static const String prodProjectId = 'new-total-prod';

  static String get currentProjectId => isDev ? devProjectId : prodProjectId;

  // API Configuration
  static const String devApiBaseUrl = 'https://api.dev.example.com';
  static const String prodApiBaseUrl = 'https://api.example.com';

  static String get apiBaseUrl => isDev ? devApiBaseUrl : prodApiBaseUrl;

  // FCM Configuration
  static String get fcmApiEndpoint =>
      'https://fcm.googleapis.com/v1/projects/$currentProjectId/messages:send';

  // App Settings
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  static const Duration cacheTimeout = Duration(hours: 1);
  static const int maxRetryAttempts = 3;
  static const Duration apiTimeout = Duration(seconds: 30);

  // Initialize the configuration for the given environment
  static void initialize(Environment env) {
    _environment = env;
  }

  // Service Account Credentials
  static Map<String, dynamic> get serviceAccountCredentials => {
       
      };
}
