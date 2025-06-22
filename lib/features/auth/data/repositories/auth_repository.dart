// File: lib/features/auth/data/repositories/auth_repository.dart
import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:rural_health_app/core/api/dio_client.dart';
import 'package:rural_health_app/core/cache/cache_keys.dart';
import 'package:rural_health_app/core/cache/hive_service.dart';
import 'package:rural_health_app/core/errors/exceptions.dart';
import 'package:rural_health_app/core/errors/failures.dart';
import 'package:rural_health_app/features/auth/data/models/user_model.dart';
import 'package:rural_health_app/features/auth/domain/repositories/i_auth_repository.dart';

@LazySingleton(as: IAuthRepository)
class AuthRepository implements IAuthRepository {
  final DioClient _dioClient;
  final HiveService _hiveService;
  final FlutterSecureStorage _secureStorage;
  final StreamController<UserModel?> _authStatusController = StreamController<UserModel?>.broadcast();

  AuthRepository(this._dioClient, this._hiveService, this._secureStorage) {
    // Initialize auth status on creation
    _checkInitialAuthStatus();
  }

  Future<void> _checkInitialAuthStatus() async {
    final userOrFailure = await getCurrentUser();
    userOrFailure.fold(
      (failure) => _authStatusController.add(null),
      (user) => _authStatusController.add(user),
    );
  }

  @override
  Stream<UserModel?> get authStatusChanges => _authStatusController.stream;

  @override
  Future<Either<Failure, UserModel>> login(
      {required String username, required String password}) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/login', // Your API endpoint for login
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final loginResponse = LoginResponse.fromJson(response.data as Map<String, dynamic>);
        await saveUserSession(loginResponse);
        _authStatusController.add(loginResponse.user);
        return Right(loginResponse.user);
      } else {
        return Left(ServerFailure(
            message: response.data?['message'] as String? ?? 'Login failed: Invalid response'));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        return Left(ServerFailure(
            message: e.response?.data?['message'] as String? ?? 'Invalid credentials'));
      }
      return Left(ServerFailure(
          message: 'Network error occurred: ${e.message}'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      // Optionally, call a backend logout endpoint
      // await _dioClient.dio.post('/auth/logout');

      await _secureStorage.delete(key: CacheKeys.authTokenKey);
      await _hiveService.deleteData<UserModel>(CacheKeys.userProfileBox, CacheKeys.userProfileKey);
      // Clear token from DioClient instance as well
      _dioClient.clearAuthToken();
      _authStatusController.add(null);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear session: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserModel?>> getCurrentUser() async {
    try {
      final token = await _secureStorage.read(key: CacheKeys.authTokenKey);
      if (token == null || token.isEmpty) {
        return const Right(null);
      }

      // Try to get user from Hive first
      final userJson = await _hiveService.getData<String>(CacheKeys.userProfileBox, CacheKeys.userProfileKey);
      if (userJson != null && userJson.isNotEmpty) {
         final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return Right(UserModel.fromJson(userMap));
      }
      // Optionally, fetch from API if not in Hive (though typically user data is fetched at login)
      // For now, if not in Hive, assume not fully logged in or data is missing.
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get current user: ${e.toString()}'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: CacheKeys.authTokenKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<Either<Failure, Unit>> saveUserSession(LoginResponse loginResponse) async {
    try {
      await _secureStorage.write(key: CacheKeys.authTokenKey, value: loginResponse.accessToken);
      // Store the UserModel as a JSON string in Hive
      await _hiveService.saveData<String>(
          CacheKeys.userProfileBox, CacheKeys.userProfileKey, jsonEncode(loginResponse.user.toJson()));
      // Update DioClient with new token
      _dioClient.setAuthToken(loginResponse.accessToken);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save user session: ${e.toString()}'));
    }
  }

  // Call this method to dispose the stream controller when the repository is no longer needed.
  // Typically managed by GetIt's dispose mechanism if configured.
  @disposeMethod
  void dispose() {
    _authStatusController.close();
  }
}

// This is needed for injectable if AuthRepository has a dispose method.
// Add this to your injector.dart or a relevant module.
// @module
// abstract class AuthRepositoryModule {
//   @lazySingleton
//   IAuthRepository authRepository(DioClient dioClient, HiveService hiveService, FlutterSecureStorage secureStorage) {
//     return AuthRepository(dioClient, hiveService, secureStorage);
//   }
// }
