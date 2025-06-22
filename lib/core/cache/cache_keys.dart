// File: lib/core/cache/cache_keys.dart

/// Contains all keys used for Hive boxes and entries.
class CacheKeys {
  // Box names
  static const String authBox = 'authBox';
  static const String userProfileBox = 'userProfileBox';
  static const String dashboardCacheBox = 'dashboardCacheBox';
  static const String patientRegistrationQueueBox = 'patientRegistrationQueueBox';
  static const String appSettingsBox = 'appSettingsBox';

  // AuthBox keys
  static const String authTokenKey = 'authToken'; // Also used by flutter_secure_storage

  // UserProfileBox keys
  static const String userProfileKey = 'userProfile';

  // DashboardCacheBox keys
  static const String dashboardDataKey = 'dashboardData';
  static const String dashboardLastFetchedKey = 'dashboardLastFetched';

  // AppSettingsBox keys
  static const String themeModeKey = 'themeMode';
  static const String languageCodeKey = 'languageCode';
}
