// File: lib/features/auth/presentation/bloc/auth_state.dart
part of 'auth_bloc.dart';

@freezed
sealed class AuthState with _$AuthState {
  /// Initial state, user's authentication status is unknown.
  const factory AuthState.initial() = AuthInitial;

  /// User is currently unauthenticated.
  const factory AuthState.unauthenticated() = AuthUnauthenticated;

  /// Authentication process is in progress (e.g., login attempt).
  const factory AuthState.loading() = AuthLoading;

  /// User is successfully authenticated.
  const factory AuthState.authenticated({required UserModel user}) = Authenticated;

  /// An error occurred during authentication.
  const factory AuthState.failure({required String message}) = AuthFailure;
}

extension AuthStateX on AuthState {
  bool get isAuthenticated => this is Authenticated;
  bool get isLoading => this is AuthLoading;
  UserModel? get currentUser => mapOrNull(authenticated: (state) => state.user);
}
