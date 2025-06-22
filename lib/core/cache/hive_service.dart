// File: lib/core/cache/hive_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rural_health_app/core/cache/cache_keys.dart';

// Import your HiveObject models here as they are created
// e.g., import 'package:rural_health_app/features/auth/data/models/user_model.dart';
// e.g., import 'package:rural_health_app/features/dashboard/data/models/patient_model.dart';
// e.g., import 'package:rural_health_app/features/patient_registration/data/models/patient_registration_payload.dart';


@lazySingleton
class HiveService {
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    // Register Adapters - uncomment and add your model adapters
    // Hive.registerAdapter(UserModelAdapter()); // Example: Generate with build_runner
    // Hive.registerAdapter(PatientModelAdapter()); // Example
    // Hive.registerAdapter(PatientRegistrationPayloadAdapter()); // Example
    // Hive.registerAdapter(DashboardDataModelAdapter()); // Example for dashboard API response caching

    // Open boxes
    await Hive.openBox<String>(CacheKeys.authBox); // For storing auth token (alternative to flutter_secure_storage or for user profile)
    await Hive.openBox(CacheKeys.userProfileBox); // For storing user model
    await Hive.openBox(CacheKeys.dashboardCacheBox); // For dashboard data
    await Hive.openBox(CacheKeys.patientRegistrationQueueBox); // For offline patient registration

    _isInitialized = true;
    print("Hive initialized successfully.");
  }

  Future<void> saveData<T>(String boxName, String key, T data) async {
    if (!_isInitialized) await init();
    final box = await Hive.openBox<T>(boxName);
    await box.put(key, data);
  }

  Future<T?> getData<T>(String boxName, String key) async {
    if (!_isInitialized) await init();
    final box = await Hive.openBox<T>(boxName);
    return box.get(key);
  }

  Future<List<T>> getAllData<T>(String boxName) async {
    if (!_isInitialized) await init();
    final box = await Hive.openBox<T>(boxName);
    return box.values.toList();
  }

  Future<void> deleteData<T>(String boxName, String key) async {
    if (!_isInitialized) await init();
    final box = await Hive.openBox<T>(boxName);
    await box.delete(key);
  }

  Future<void> clearBox<T>(String boxName) async {
    if (!_isInitialized) await init();
    final box = await Hive.openBox<T>(boxName);
    await box.clear();
  }

  Future<void> close() async {
    if (_isInitialized) {
      await Hive.close();
      _isInitialized = false;
    }
  }

  // Specific methods for convenience

  // Example for storing user session (token could be here or flutter_secure_storage)
  Future<void> cacheUserSession(String token, dynamic userJson) async {
    await saveData(CacheKeys.authBox, CacheKeys.authTokenKey, token);
    await saveData(CacheKeys.userProfileBox, CacheKeys.userProfileKey, userJson);
  }

  Future<String?>getAuthToken() async {
    return await getData<String>(CacheKeys.authBox, CacheKeys.authTokenKey);
  }

  Future<dynamic> getUserProfile() async {
    return await getData<dynamic>(CacheKeys.userProfileBox, CacheKeys.userProfileKey);
  }

  Future<void> clearUserSession() async {
    await deleteData(CacheKeys.authBox, CacheKeys.authTokenKey);
    await deleteData(CacheKeys.userProfileBox, CacheKeys.userProfileKey);
  }

  // Example for dashboard cache
  Future<void> cacheDashboardData(dynamic dashboardJson) async {
    await saveData(CacheKeys.dashboardCacheBox, CacheKeys.dashboardDataKey, dashboardJson);
  }

  Future<dynamic> getDashboardData() async {
    return await getData<dynamic>(CacheKeys.dashboardCacheBox, CacheKeys.dashboardDataKey);
  }

  // Example for patient registration queue
  Future<void> addToRegistrationQueue(dynamic registrationPayload) async {
    if (!_isInitialized) await init();
    final box = await Hive.openBox<dynamic>(CacheKeys.patientRegistrationQueueBox);
    // Using auto-incrementing key for queue items
    await box.add(registrationPayload);
  }

  Future<List<dynamic>> getRegistrationQueue() async {
    if (!_isInitialized) await init();
    final box = await Hive.openBox<dynamic>(CacheKeys.patientRegistrationQueueBox);
    return box.values.toList();
  }

  Future<void> clearRegistrationQueueItem(int key) async {
     // In Hive, when you use `add`, the key is an auto-incrementing integer.
     // To remove an item, you need its specific key.
     // If you are processing items one by one, you might get them with their keys.
    if (!_isInitialized) await init();
    final box = await Hive.openBox<dynamic>(CacheKeys.patientRegistrationQueueBox);
    await box.deleteAt(key); // Deletes item at a specific index if you treat it like a list
                               // or use box.delete(actualHiveKey) if you have it.
                               // For simplicity, if processing sequentially, deleteAt(0) might be used.
  }
   Future<void> clearEntireRegistrationQueue() async {
    await clearBox(CacheKeys.patientRegistrationQueueBox);
  }
}

// Define cache keys in a separate file for better organization
// File: lib/core/cache/cache_keys.dart (created below)
