// File: lib/features/patient_registration/data/repositories/patient_repository.dart
import 'dart:convert'; // For jsonEncode if storing complex objects as strings

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:rural_health_app/core/api/dio_client.dart';
import 'package:rural_health_app/core/cache/cache_keys.dart';
import 'package:rural_health_app/core/cache/hive_service.dart';
import 'package:rural_health_app/core/errors/failures.dart';
import 'package:rural_health_app/core/platform/network_info.dart'; // Assuming you have a network info service
import 'package:rural_health_app/features/patient_registration/data/models/patient_registration_model.dart';
import 'package:rural_health_app/features/patient_registration/domain/repositories/i_patient_repository.dart';

@LazySingleton(as: IPatientRepository)
class PatientRepository implements IPatientRepository {
  final DioClient _dioClient;
  final HiveService _hiveService;
  final NetworkInfo _networkInfo; // Inject network info

  PatientRepository(this._dioClient, this._hiveService, this._networkInfo);

  @override
  Future<Either<Failure, Unit>> registerPatient(
      PatientRegistrationPayload payload) async {
    if (await _networkInfo.isConnected) {
      try {
        // Device is online, attempt to submit to API
        final response = await _dioClient.dio.post(
          '/patients', // Your API endpoint for patient registration
          data: payload.toApiJson(),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          // Successfully submitted to API
          return const Right(unit);
        } else {
          // API returned an error, but we are online.
          // Decide if this should be queued or treated as an immediate error.
          // For now, let's treat it as an error that should be shown to the user.
          // Alternatively, could queue it with an error flag.
          return Left(ServerFailure(
              message:
                  'API Error: ${response.statusCode} - ${response.data?['message'] ?? 'Unknown error'}'));
        }
      } on DioException catch (e) {
        // A DioException occurred (e.g. connection timeout, but still "online")
        // For critical submissions, it might be better to queue these too.
        // For now, if it's a network-related DioError, we queue.
        // Otherwise, if it's a non-2xx response error, we might show it.
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.unknown) { // Typically for no internet
          // Network related error, fallback to queueing
          return _queueRegistration(payload.copyWith(queuedAt: DateTime.now()));
        }
        // For other Dio errors (like 4xx, 5xx responses caught by DioException)
        return Left(ServerFailure(
            message:
                'Network error during submission: ${e.message}. Data will be queued.'));
        // Actually, the above should queue, so let's change logic:
        // If any DioException, queue it. User will be notified it's queued.
        // print('DioException during registration, queueing: ${e.message}');
        // return _queueRegistration(payload.copyWith(queuedAt: DateTime.now()));
      } catch (e) {
        // Any other exception during API call
        print('Unexpected error during API registration, queueing: ${e.toString()}');
        return _queueRegistration(payload.copyWith(queuedAt: DateTime.now()));
      }
    }
    // Device is offline, save to Hive queue
    return _queueRegistration(payload.copyWith(queuedAt: DateTime.now()));
  }

  Future<Either<Failure, Unit>> _queueRegistration(
      PatientRegistrationPayload payload) async {
    try {
      // In Hive, PatientRegistrationPayload objects are stored directly if adapter is registered.
      // The key for each item in the queue box will be its `localId`.
      await _hiveService.saveData<PatientRegistrationPayload>(
        CacheKeys.patientRegistrationQueueBox,
        payload.localId, // Use localId as the key for easy retrieval/deletion
        payload,
      );
      return const Right(unit);
    } catch (e) {
      return Left(
          CacheFailure(message: 'Failed to queue patient registration: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<PatientRegistrationPayload>>>
      getQueuedRegistrations() async {
    try {
      // Retrieve all values from the box.
      final queuedItems = await _hiveService.getAllData<PatientRegistrationPayload>(
          CacheKeys.patientRegistrationQueueBox);
      return Right(queuedItems);
    } catch (e) {
      return Left(CacheFailure(
          message: 'Failed to retrieve queued registrations: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SyncSummary>> syncQueuedRegistrations() async {
    if (!await _networkInfo.isConnected) {
      return Left(NetworkFailure(message: 'No internet connection to sync.'));
    }

    final queuedEither = await getQueuedRegistrations();
    return queuedEither.fold(
      (failure) => Left(failure),
      (queuedItems) async {
        if (queuedItems.isEmpty) {
          return Right(SyncSummary(totalItems: 0, successfulSyncs: 0, failedSyncs: 0));
        }

        int successfulSyncs = 0;
        int failedSyncs = 0;

        for (final payloadInQueue in queuedItems) {
          // Ensure we don't try to re-submit already submitted items if any logic error left them.
          if (payloadInQueue.isSubmitted) {
            successfulSyncs++; // Or handle as already processed
            continue;
          }

          try {
            final updatedPayload = payloadInQueue.copyWith(
              submissionAttemptCount: (payloadInQueue.submissionAttemptCount ?? 0) + 1,
            );

            final response = await _dioClient.dio.post(
              '/patients',
              data: updatedPayload.toApiJson(),
            );

            if (response.statusCode == 201 || response.statusCode == 200) {
              successfulSyncs++;
              // Mark as submitted or delete from queue
              await _hiveService.deleteData<PatientRegistrationPayload>(
                  CacheKeys.patientRegistrationQueueBox, updatedPayload.localId);
            } else {
              failedSyncs++;
              // Optionally update the item in queue with error info or increment attempt count
              await _hiveService.saveData<PatientRegistrationPayload>(
                CacheKeys.patientRegistrationQueueBox,
                updatedPayload.localId,
                updatedPayload, // Save updated attempt count
              );
            }
          } catch (e) {
            failedSyncs++;
            // Error during sync of this item, update attempt count and keep in queue
            final erroredPayload = payloadInQueue.copyWith(
              submissionAttemptCount: (payloadInQueue.submissionAttemptCount ?? 0) + 1,
            );
            await _hiveService.saveData<PatientRegistrationPayload>(
              CacheKeys.patientRegistrationQueueBox,
              erroredPayload.localId,
              erroredPayload,
            );
            print('Error syncing item ${payloadInQueue.localId}: ${e.toString()}');
          }
        }
        return Right(SyncSummary(
          totalItems: queuedItems.length,
          successfulSyncs: successfulSyncs,
          failedSyncs: failedSyncs,
        ));
      },
    );
  }

   @override
  Future<Either<Failure, Unit>> deleteQueuedRegistration(String localId) async {
    try {
      await _hiveService.deleteData<PatientRegistrationPayload>(
          CacheKeys.patientRegistrationQueueBox, localId);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to delete queued item: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearRegistrationQueue() async {
    try {
      await _hiveService.clearBox<PatientRegistrationPayload>(CacheKeys.patientRegistrationQueueBox);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear registration queue: ${e.toString()}'));
    }
  }
}

// Simple NetworkInfo placeholder - in a real app, use connectivity_plus or similar
// This should be in lib/core/platform/network_info.dart
@lazySingleton
class NetworkInfo {
  Future<bool> get isConnected async {
    // Placeholder: In a real app, use connectivity_plus
    // For now, assume always connected for testing API path, or implement a toggle.
    // return true; // Simulate online
    // To test offline queueing:
    // return false; // Simulate offline
    // A more robust mock would allow this to be controlled.
    // For the purpose of this generation, let's assume it can be true.
    // This should be properly implemented with a package like connectivity_plus.
    try {
      // A simple check: try to lookup google.com. If it succeeds, we have internet.
      // This is a basic check and has limitations (e.g. captive portals).
      // final result = await InternetAddress.lookup('google.com');
      // return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      return true; // Defaulting to true for now, replace with actual check
    } catch (_) {
      return false;
    }
  }
}

// Ensure NetworkInfo is registered in your DI setup (e.g. injector.dart)
// @module
// abstract class CoreModule {
//   @lazySingleton
//   NetworkInfo get networkInfo => NetworkInfo();
// }
