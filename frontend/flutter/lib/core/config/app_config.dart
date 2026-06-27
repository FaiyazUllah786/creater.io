class AppConfig {
  static const String serverUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'https://creater-io.onrender.com',
  );

  static const String unsplashAccessKey = String.fromEnvironment(
    'UNSPLASH_ACCESS_KEY',
    defaultValue: '',
  );

  static const String unsplashSecretKey = String.fromEnvironment(
    'UNSPLASH_SECRET_KEY',
    defaultValue: '',
  );

  static const String githubClientId = String.fromEnvironment(
    'GITHUB_CLIENT_ID',
    defaultValue: '',
  );
}
