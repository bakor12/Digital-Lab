// File: lib/features/auth/domain/repositories/i_auth_repository.dart
import 'package:dartz/dartz.dart';
import 'package:rural_health_app/core/errors/failures.dart';
import 'package:rural_health_app/features/auth/data/models/user_model.dart';

/// Interface for authentication repository.
/// Defines the contract for authentication-related data operations.
abstract class IAuthRepository {
  /// Attempts to log in the user with the given credentials.
  ///
  /// Returns a [UserModel] on success, or a [Failure] on error.
  Future<Either<Failure, UserModel>> login(
      {required String username, required String password});

  /// Logs out the current user.
  ///
  /// Clears any persisted session data.
  Future<Either<Failure, Unit>> logout();

  /// Retrieves the currently authenticated user, if any.
  ///
  /// Returns a [UserModel] if a user is logged in, otherwise null or Failure.
  Future<Either<Failure, UserModel?>> getCurrentUser();

  /// Checks if a user is currently authenticated.
  Future<bool> isAuthenticated();

  /// Saves user session (token and user details).
  Future<Either<Failure, Unit>> saveUserSession(LoginResponse loginResponse);

  /// Stream to listen to authentication status changes.
  /// Emits UserModel when authenticated, null otherwise.
  Stream<UserModel?> get authStatusChanges;
}
