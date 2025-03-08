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
        "type": "service_account",
        "project_id": currentProjectId,
        "private_key_id": isDev
            ? "11b142b4a5e9c794b503b6ab567fae0c4ff31b04"
            : "PROD_PRIVATE_KEY_ID",
        "private_key": isDev
            ? "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCa3KIGtdM5m9HQ\n6FV1prhzwTcE8tOXHFn+EY1ggFJQHkIu4iq0Ljn+JAQGZtOHG+QUWjrqZZHirKQ/\nf+QaJiME00ZrKdeu/1R3xmGY5LTZTb41ENRvZEp0x4PliiXITPXzgNFqdZ8yiy+6\n4/lP8vf4TrwjJC0hRfoIZv9Xzi7Z3Krkw/mPSFAo8+n7F0Cra4kCv4iAY6HICw4J\nKcjEYThvP3jHlPcGqBhEZHz6i99HoC5s1/HK4mOEsfKWjOs5ucmgScXA3SvuoFJP\n1lT3dxS9UQXAMxbumHYc2MAd5Ntbk8b5lbvlyU6/En8VWS0MWV52OMqpXssFI82N\nsWp/p+VFAgMBAAECggEACyU0kWBl/VAWP6oY9x4H9Gdu0EUHBBR0SEbMcqo0Ql6L\nINis03Q9lD7UqKlJ3AAeissbpmGnqDVd9NFS11bwpO5CXoAPwnZ528zumpRgjQB9\nX1BWGauReD92Yf9uogXNRbh7BJBxOVqvFWJG6oFwEJzfXsrBvL1Oi2ruQaGDLway\nqKSozd5JM13Yas5oUgLXj5uHaLrxM3O7Wg4ZTLBVo2MiMV2swLmjpE9iKwD5RZKO\nFcmW9kH/VT52LlPGgKV8U6te+D8Mvlcho2uVzGMss8tj1yeRywYj93K6G5dkl0el\nYEglBmHzG9wbCMIPNyONx+p6gQXw+56URcOCZKt/wQKBgQDLXCXAOFbixxJ2L18E\nmsT38oeG54Ggxt0R8E/5PKqBhcDg6sq1IL1JzzRxs0TgYT1cKawqxJLfSJeElU65\ncVytqqueX2ta7Jmfrhoiu1RwHbtqfu+evTJKp4WVSnBzSTQ9ZXl/jOXQRjaOJiad\nTj1UipcwalLziRy1Yz+a8/8fSQKBgQDC8rWqNErQwwNwyxiRJYBzxCx7FpDrfXTT\nOJPdx6uWnXd84OLR2f3Rt5C8vRoc5x59I763E23u345uCM7GnqT9W5BVSEu7zRic\nIbkXNQbUuzlJDVXxs7NLwavOLabWNvpwy+6APElqQXfheSSYlCrAdcRHqnOdy5VW\nrDYZWcSKHQKBgBRH9FvfQosLX4P55XgIF2zC+1Ew9XSbYKDRXqh0rGyOclX8FItL\n4JTj3U8Zmdzm1b/DSDBbumoaS0Ilwdwsuhl30/XPfl1rC0cpjeG43QrxbCeK0Ur7\ng3B+lIv3CI/21Qbqf9uAqcrDtd0nYOJ/Uw6DY+CoOe2f1wUgCM/jVaZBAoGAeHpy\n1utWSUob+DsrxZf9mI3mR3OcwExaRKc0it15J63NSHna84HbIR5m7p2XY8FZ0FCk\n7pOtXvD+HvaGg61LneBWhL4XP8ryqJsWvkbhH9tM/d6l/Kfn6KuaN+NytfRoNgly\nLgIUBPzMz6WEfl8jRKoDUZ7/sMc+VcA79tLJaekCgYBl8tBiI0yjGMMVBpaGtq9c\nmRN3Y8UywixHeNejstaS5WqGGaRdeMMZkj2XYBm9HKZzBBDNo/GkH+jKQl8ld1eG\nl/SNbDds3mc69ElD5QQOSmyudxjO9FvaWygI9nUUeZhc6HAtZiEovj0twk2uDE3U\nmXZTWPbWui892f+Qc15HRQ==\n-----END PRIVATE KEY-----\n"
            : "PROD_PRIVATE_KEY",
        "client_email": isDev
            ? "firebase-adminsdk-fbsvc@new-total-c0e19.iam.gserviceaccount.com"
            : "PROD_CLIENT_EMAIL",
        "client_id": isDev ? "114512965096133257963" : "PROD_CLIENT_ID",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": isDev
            ? "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40new-total-c0e19.iam.gserviceaccount.com"
            : "PROD_CERT_URL",
        "universe_domain": "googleapis.com"
      };
}
