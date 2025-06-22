// File: lib/features/patient_registration/data/models/patient_registration_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'patient_registration_model.freezed.dart';
part 'patient_registration_model.g.dart';

/// Represents the data payload for registering a new patient.
/// This model will be used for the multi-step form and for queuing offline submissions.
@freezed
@HiveType(typeId: 5) // Ensure typeId is unique across all HiveObject classes
class PatientRegistrationPayload with _$PatientRegistrationPayload {
  const factory PatientRegistrationPayload({
    // Hive fields for local storage
    @HiveField(0) required String localId, // Unique ID for local queue management
    @HiveField(1) DateTime? queuedAt, // Timestamp when it was queued

    // Patient Demographics (Step 1)
    @HiveField(2) String? firstName,
    @HiveField(3) String? lastName,
    @HiveField(4) DateTime? dateOfBirth,
    @HiveField(5) String? gender, // e.g., "Male", "Female", "Other"
    @HiveField(6) String? nationalId, // Optional

    // Contact Information (Step 2)
    @HiveField(7) String? phoneNumber,
    @HiveField(8) String? addressLine1,
    @HiveField(9) String? village,
    @HiveField(10) String? district, // Or similar administrative unit

    // Health Information (Step 3 - Basic)
    // This would be more extensive in a real app, including NCD risk factors
    @HiveField(11) double? heightCm,
    @HiveField(12) double? weightKg,
    @HiveField(13) List<String>? knownAllergies,
    @HiveField(14) List<String>? preExistingConditions,

    // Consent (Step 4)
    @HiveField(15) bool? hasConsentedToServices,
    @HiveField(16) bool? hasConsentedToDataSharing, // For research/analytics if applicable

    // Submission status (not part of API payload, but useful for local queue)
    @HiveField(17) @Default(false) bool isSubmitted, // True if successfully synced with backend
    @HiveField(18) int? submissionAttemptCount,

  }) = _PatientRegistrationPayload;

  /// Private constructor for Freezed.
  const PatientRegistrationPayload._();

  factory PatientRegistrationPayload.fromJson(Map<String, dynamic> json) =>
      _$PatientRegistrationPayloadFromJson(json);

  /// Helper to create an initial empty payload with a localId.
  factory PatientRegistrationPayload.initial() {
    return PatientRegistrationPayload(
      localId: DateTime.now().millisecondsSinceEpoch.toString(), // Simple unique ID
      queuedAt: DateTime.now(),
      submissionAttemptCount: 0,
      isSubmitted: false,
    );
  }

  /// Converts the payload to a Map suitable for API submission (POST /patients).
  /// This should only include fields expected by the backend.
  Map<String, dynamic> toApiJson() {
    return {
      // Map fields from this payload to the API contract for POST /patients
      // Example:
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth?.toIso8601String().split('T').first, // YYYY-MM-DD
      'gender': gender,
      'nationalId': nationalId,
      'contactDetails': {
        'phoneNumber': phoneNumber,
        'address': {
          'line1': addressLine1,
          'village': village,
          'district': district,
        }
      },
      'medicalHistory': {
        'heightCm': heightCm,
        'weightKg': weightKg,
        'allergies': knownAllergies,
        'conditions': preExistingConditions,
      },
      'consent': {
        'services': hasConsentedToServices,
        'dataSharing': hasConsentedToDataSharing,
      }
      // Add other fields as per your API contract for POST /patients
    };
  }
}
