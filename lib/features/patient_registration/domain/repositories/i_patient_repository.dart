// File: lib/features/patient_registration/domain/repositories/i_patient_repository.dart
import 'package:dartz/dartz.dart';
import 'package:rural_health_app/core/errors/failures.dart';
import 'package:rural_health_app/features/patient_registration/data/models/patient_registration_model.dart';

/// Interface for patient repository.
/// Defines the contract for patient registration and related operations.
/// Must handle offline submissions by queueing data in Hive.
abstract class IPatientRepository {
  /// Registers a new patient.
  ///
  /// If the device is online, it submits the data to the API (POST /patients).
  /// If offline, it saves the entire registration payload to a "submission queue" in Hive.
  ///
  /// Returns [Unit] on successful immediate submission or successful queueing.
  /// Returns [Failure] if queueing fails or an immediate API error occurs (that isn't an offline scenario).
  Future<Either<Failure, Unit>> registerPatient(
      PatientRegistrationPayload payload);

  /// Retrieves all patient registration payloads currently in the offline queue.
  Future<Either<Failure, List<PatientRegistrationPayload>>> getQueuedRegistrations();

  /// Attempts to sync queued patient registrations with the backend.
  /// This method would typically be called by a background service or on app startup.
  ///
  /// Returns a summary of sync attempts (e.g., number successful, number failed).
  Future<Either<Failure, SyncSummary>> syncQueuedRegistrations();

  /// Deletes a specific queued registration item.
  /// Useful if a specific queued item is problematic or needs to be removed manually (admin feature).
  Future<Either<Failure, Unit>> deleteQueuedRegistration(String localId);

  /// Clears the entire patient registration queue.
  Future<Either<Failure, Unit>> clearRegistrationQueue();
}

/// Summary of the synchronization process.
class SyncSummary {
  final int totalItems;
  final int successfulSyncs;
  final int failedSyncs;

  SyncSummary({
    required this.totalItems,
    required this.successfulSyncs,
    required this.failedSyncs,
  });

  bool get allSynced => totalItems > 0 && successfulSyncs == totalItems;
  bool get hasFailures => failedSyncs > 0;

  @override
  String toString() {
    return 'SyncSummary(total: $totalItems, successful: $successfulSyncs, failed: $failedSyncs)';
  }
}
