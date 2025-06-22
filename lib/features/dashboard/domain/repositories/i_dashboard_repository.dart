// File: lib/features/dashboard/domain/repositories/i_dashboard_repository.dart
import 'package:dartz/dartz.dart';
import 'package:rural_health_app/core/errors/failures.dart';
import 'package:rural_health_app/features/dashboard/data/models/dashboard_models.dart';

/// Interface for dashboard repository.
/// Defines the contract for fetching CHW dashboard data.
/// It must implement an offline-first strategy.
abstract class IDashboardRepository {
  /// Fetches the CHW dashboard data.
  ///
  /// Attempts to get fresh data from the API.
  /// If successful, updates the local Hive cache and returns the data.
  /// If API call fails (e.g., no internet), fetches the last known data
  /// from Hive cache and returns it, along with a flag indicating staleness.
  ///
  /// Returns a tuple of [ChwDashboardData] and a boolean `isStale`.
  Future<Either<Failure, (ChwDashboardData, bool isStale)>> getDashboardData();
}
