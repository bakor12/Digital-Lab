// File: lib/features/dashboard/data/repositories/dashboard_repository.dart
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:rural_health_app/core/api/dio_client.dart';
import 'package:rural_health_app/core/cache/cache_keys.dart';
import 'package:rural_health_app/core/cache/hive_service.dart';
import 'package:rural_health_app/core/errors/exceptions.dart';
import 'package:rural_health_app/core/errors/failures.dart';
import 'package:rural_health_app/features/dashboard/data/models/dashboard_models.dart';
import 'package:rural_health_app/features/dashboard/domain/repositories/i_dashboard_repository.dart';

@LazySingleton(as: IDashboardRepository)
class DashboardRepository implements IDashboardRepository {
  final DioClient _dioClient;
  final HiveService _hiveService;

  DashboardRepository(this._dioClient, this._hiveService);

  @override
  Future<Either<Failure, (ChwDashboardData, bool isStale)>>
      getDashboardData() async {
    try {
      // 1. Try to fetch fresh data from the API
      final response = await _dioClient.dio.get('/chw/dashboard');

      if (response.statusCode == 200 && response.data != null) {
        final dashboardData =
            ChwDashboardData.fromJson(response.data as Map<String, dynamic>);
        final updatedData = dashboardData.copyWith(lastUpdatedAt: DateTime.now());

        // 2. If successful, update the local Hive cache
        await _hiveService.saveData<String>(
          CacheKeys.dashboardCacheBox,
          CacheKeys.dashboardDataKey,
          jsonEncode(updatedData.toJson()), // Store as JSON string
        );
        await _hiveService.saveData<String>( // Save last fetched timestamp
          CacheKeys.dashboardCacheBox,
          CacheKeys.dashboardLastFetchedKey,
          updatedData.lastUpdatedAt!.toIso8601String(),
        );
        return Right((updatedData, false)); // Data is fresh
      } else {
        // API call was made but resulted in a non-200 status
        // Fallback to cache
        return _getCachedDashboardData(
            ServerFailure(message: 'API Error: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      // DioException typically means network error or non-200 response not caught above
      print('DioException fetching dashboard: ${e.message}');
      return _getCachedDashboardData(
          ServerFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      // Other unexpected errors
      print('Unexpected error fetching dashboard: ${e.toString()}');
      return _getCachedDashboardData(
          UnexpectedFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  /// Attempts to load dashboard data from Hive cache.
  /// If [originalFailure] is provided, it means an API call already failed.
  Future<Either<Failure, (ChwDashboardData, bool isStale)>>
      _getCachedDashboardData([Failure? originalFailure]) async {
    try {
      final cachedDataJson = await _hiveService.getData<String>(
          CacheKeys.dashboardCacheBox, CacheKeys.dashboardDataKey);

      if (cachedDataJson != null && cachedDataJson.isNotEmpty) {
        final dashboardData =
            ChwDashboardData.fromJson(jsonDecode(cachedDataJson) as Map<String, dynamic>);

        // Check last fetched time to determine if it's "very" stale (e.g. > 1 day)
        // This is for display purposes, the `isStale` flag primarily indicates it's not from a fresh API call.
        final lastFetchedStr = await _hiveService.getData<String>(
          CacheKeys.dashboardCacheBox,
          CacheKeys.dashboardLastFetchedKey,
        );
        DateTime? lastFetchedDate;
        if(lastFetchedStr != null) {
          lastFetchedDate = DateTime.tryParse(lastFetchedStr);
        }

        print('Returning cached dashboard data. Last fetched: ${lastFetchedDate ?? 'N/A'}');
        return Right((dashboardData.copyWith(lastUpdatedAt: lastFetchedDate), true)); // Data is from cache, hence stale
      } else {
        // No cache available, return the original failure or a new CacheFailure
        return Left(originalFailure ??
            CacheFailure(message: 'No cached dashboard data available.'));
      }
    } catch (e) {
      // Error reading from cache
      return Left(CacheFailure(
          message: 'Failed to load dashboard data from cache: ${e.toString()}'));
    }
  }
}
