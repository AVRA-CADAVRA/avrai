class AppConstants {
  // App Info
  static const String appName = 'avrai';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String spotsCollection = 'spots';
  static const String listsCollection = 'lists';

  // Storage Paths
  static const String userImagesPath = 'user_images';
  static const String spotImagesPath = 'spot_images';

  // Local Storage Keys
  static const String userKey = 'current_user';
  static const String offlineModeKey = 'offline_mode';
  static const String lastSyncKey = 'last_sync';

  // Error Messages
  static const String networkError =
      'Network error. Please check your connection.';
  static const String offlineError =
      'You are offline. Some features may be limited.';
  static const String authError = 'Authentication failed. Please try again.';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultElevation = 2.0;
}
