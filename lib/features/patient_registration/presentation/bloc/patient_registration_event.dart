// File: lib/features/patient_registration/presentation/bloc/patient_registration_event.dart
part of 'patient_registration_bloc.dart';

@freezed
sealed class PatientRegistrationEvent with _$PatientRegistrationEvent {
  /// Initializes or resets the registration form with an empty payload.
  const factory PatientRegistrationEvent.initializeForm() = InitializeForm;

  /// Updates the form data as the user progresses through steps.
  const factory PatientRegistrationEvent.updateFormData(
      PatientRegistrationPayload updatedPayload) = UpdateFormData;

  /// Moves to the next step in the registration form.
  const factory PatientRegistrationEvent.nextStep() = NextStep;

  /// Moves to a specific step in the registration form.
  const factory PatientRegistrationEvent.goToStep(int step) = GoToStep;

  /// Moves to the previous step in the registration form.
  const factory PatientRegistrationEvent.previousStep() = PreviousStep;

  /// Submits the completed registration form.
  const factory PatientRegistrationEvent.submitRegistration() = SubmitRegistration;

  /// Event to trigger syncing of any queued registrations.
  const factory PatientRegistrationEvent.syncQueuedRegistrations() = SyncQueuedRegistrations;
}
