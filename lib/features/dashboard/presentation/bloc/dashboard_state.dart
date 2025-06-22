// File: lib/features/dashboard/presentation/bloc/dashboard_state.dart
part of 'dashboard_bloc.dart';

@freezed
sealed class DashboardState with _$DashboardState {
  /// Initial state before any data is loaded.
  const factory DashboardState.initial() = DashboardInitial;

  /// State indicating that dashboard data is being loaded.
  const factory DashboardState.loading() = DashboardLoading;

  /// State indicating successful loading of dashboard data.
  const factory DashboardState.loaded({
    required ChwDashboardData dashboardData,
    required bool isStale, // True if data is from cache due to API failure
  }) = DashboardLoaded;

  /// State indicating an error occurred while fetching dashboard data.
  const factory DashboardState.error({required String message}) = DashboardError;
}
