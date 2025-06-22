// File: lib/features/patient_registration/presentation/bloc/patient_registration_state.dart
part of 'patient_registration_bloc.dart';

@freezed
sealed class PatientRegistrationState with _$PatientRegistrationState {
  /// The form is ready for input or currently being filled.
  const factory PatientRegistrationState.formInProgress({
    required PatientRegistrationPayload currentPayload,
    required int currentStep,
    @Default(false) bool isSubmitting,
    String? submissionMessage, // For "Queued successfully" or similar
  }) = PatientRegistrationFormInProgress;

  /// The registration is currently being submitted to the backend or queue.
  // const factory PatientRegistrationState.submitting({
  //   required PatientRegistrationPayload payload,
  // }) = PatientRegistrationSubmitting;
  // Note: isSubmitting flag in FormInProgress can cover this.

  /// The registration was successfully submitted (either directly or queued).
  const factory PatientRegistrationState.submissionSuccess({
    required String message, // e.g., "Patient registered successfully" or "Registration queued"
    required PatientRegistrationPayload submittedPayload,
  }) = PatientRegistrationSubmissionSuccess;

  /// An error occurred during the registration process or submission.
  const factory PatientRegistrationState.submissionFailure({
    required String errorMessage,
    required PatientRegistrationPayload payloadOnError,
    required int currentStepOnError,
  }) = PatientRegistrationSubmissionFailure;

  /// State for when sync operation is running.
  const factory PatientRegistrationState.syncingQueuedData() = SyncingQueuedData;

  /// State for when sync operation completes.
  const factory PatientRegistrationState.syncCompleted({
    required SyncSummary summary,
    required List<PatientRegistrationPayload> remainingInQueue, // To update UI if needed
  }) = SyncCompleted;


  /// Initial state, form not yet initialized.
  const factory PatientRegistrationState.initial() = PatientRegistrationInitial;
}
