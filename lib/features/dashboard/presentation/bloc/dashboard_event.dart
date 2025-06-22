// File: lib/features/dashboard/presentation/bloc/dashboard_event.dart
part of 'dashboard_bloc.dart';

@freezed
sealed class DashboardEvent with _$DashboardEvent {
  /// Event to trigger fetching of dashboard data.
  const factory DashboardEvent.fetchDashboardDataRequested() = FetchDashboardDataRequested;

  /// Event to indicate that dashboard data should be refreshed (e.g., pull-to-refresh).
  const factory DashboardEvent.refreshDashboardDataRequested() = RefreshDashboardDataRequested;
}
