// File: lib/features/auth/presentation/bloc/auth_event.dart
part of 'auth_bloc.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  /// Event to signify that a login attempt is requested.
  const factory AuthEvent.loginRequested({
    required String username,
    required String password,
  }) = LoginRequested;

  /// Event to signify that a logout is requested.
  const factory AuthEvent.logoutRequested() = LogoutRequested;

  /// Event triggered internally when authentication status changes (e.g. on app start).
  const factory AuthEvent.authStatusChanged(UserModel? user) = _AuthStatusChanged;
}
