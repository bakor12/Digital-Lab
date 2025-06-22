// File: lib/features/patient_registration/presentation/screens/patient_registration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:rural_health_app/core/di/injector.dart';
import 'package:rural_health_app/features/patient_registration/data/models/patient_registration_model.dart';
import 'package:rural_health_app/features/patient_registration/presentation/bloc/patient_registration_bloc.dart';
// Assuming KineticTextFormField is moved to a shared location or defined here
// For this example, let's assume it's available.
// import 'package:rural_health_app/features/auth/presentation/screens/login_screen.dart'; // if KineticTextFormField is there
// Or define a similar one here:

class KineticFormField extends HookWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final FocusNode focusNode;
  final TextInputAction textInputAction;
  final Function(String)? onFieldSubmitted;
  final TextInputType? keyboardType;
  final bool isEnabled;

  const KineticFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.validator,
    required this.focusNode,
    required this.textInputAction,
    this.onFieldSubmitted,
    this.keyboardType,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = useState(focusNode.hasFocus);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 200),
    );
    final colorAnimation = ColorTween(
      begin: Theme.of(context).colorScheme.outline,
      end: Theme.of(context).colorScheme.primary,
    ).animate(animationController);

    useEffect(() {
      void listener() {
        isFocused.value = focusNode.hasFocus;
        if (focusNode.hasFocus) {
          animationController.forward();
        } else {
          animationController.reverse();
        }
      }
      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    return AnimatedBuilder(
      animation: colorAnimation,
      builder: (context, child) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          validator: validator,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          keyboardType: keyboardType,
          enabled: isEnabled,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            labelStyle: TextStyle(
                color: isFocused.value
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorAnimation.value!, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5),
            ),
             disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5), width: 1.5),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        );
      },
    );
  }
}


class PatientRegistrationScreen extends HookWidget {
  const PatientRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = useMemoized(() => getIt<PatientRegistrationBloc>()..add(const InitializeForm()));
    // Form Keys for each step
    final step1FormKey = useMemoized(() => GlobalKey<FormState>());
    final step2FormKey = useMemoized(() => GlobalKey<FormState>());
    final step3FormKey = useMemoized(() => GlobalKey<FormState>());
    final step4FormKey = useMemoized(() => GlobalKey<FormState>());

    // Controllers - consider grouping them in a custom Hook or StateNotifier if many
    // Step 1
    final firstNameController = useTextEditingController();
    final lastNameController = useTextEditingController();
    final dobController = useTextEditingController(); // Will show formatted date
    final selectedDob = useState<DateTime?>(null);
    final selectedGender = useState<String?>(null);
    final nationalIdController = useTextEditingController();

    // Step 2
    final phoneController = useTextEditingController();
    final addressController = useTextEditingController();
    final villageController = useTextEditingController();
    final districtController = useTextEditingController();

    // Step 3
    final heightController = useTextEditingController();
    final weightController = useTextEditingController();
    // For allergies/conditions, a more complex input might be needed (e.g., chips)
    final allergiesController = useTextEditingController(); // Simple text for now
    final conditionsController = useTextEditingController(); // Simple text for now

    // Step 4
    final consentServices = useState<bool?>(null);
    final consentDataSharing = useState<bool?>(null);

    // Focus Nodes
    final fnFirstName = useFocusNode();
    final fnLastName = useFocusNode();
    final fnNationalId = useFocusNode();
    final fnPhone = useFocusNode();
    final fnAddress = useFocusNode();
    final fnVillage = useFocusNode();
    final fnDistrict = useFocusNode();
    final fnHeight = useFocusNode();
    final fnWeight = useFocusNode();
    final fnAllergies = useFocusNode();
    final fnConditions = useFocusNode();


    useEffect(() {
      return () {
        bloc.close(); // Dispose BLoC when widget is disposed
      };
    }, [bloc]);

    // Function to show date picker
    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDob.value ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (picked != null && picked != selectedDob.value) {
        selectedDob.value = picked;
        dobController.text = DateFormat.yMMMd().format(picked); // e.g. Jan 1, 2000
        HapticFeedback.lightImpact();
      }
    }

    // Function to update BLoC with current form data from controllers
    void _updateBlocWithFormData(PatientRegistrationState state) {
       if (state is PatientRegistrationFormInProgress) {
        final currentPayload = state.currentPayload;
        bloc.add(UpdateFormData(currentPayload.copyWith(
          firstName: firstNameController.text,
          lastName: lastNameController.text,
          dateOfBirth: selectedDob.value,
          gender: selectedGender.value,
          nationalId: nationalIdController.text,
          phoneNumber: phoneController.text,
          addressLine1: addressController.text,
          village: villageController.text,
          district: districtController.text,
          heightCm: double.tryParse(heightController.text),
          weightKg: double.tryParse(weightController.text),
          knownAllergies: allergiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          preExistingConditions: conditionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          hasConsentedToServices: consentServices.value,
          hasConsentedToDataSharing: consentDataSharing.value,
        )));
      }
    }


    return BlocProvider.value(
      value: bloc,
      child: BlocConsumer<PatientRegistrationBloc, PatientRegistrationState>(
        listener: (context, state) {
          state.mapOrNull(
            submissionSuccess: (successState) {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(successState.message),
                  backgroundColor: Colors.green,
                ));
              // Potentially navigate away or reset form further
              context.pop(); // Go back after successful registration
            },
            submissionFailure: (failureState) {
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(failureState.errorMessage),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ));
            },
          );

          // Populate fields if state changes (e.g. on initialize or error recovery)
          if (state is PatientRegistrationFormInProgress) {
             final data = state.currentPayload;
             // This can cause issues if not handled carefully with controller listeners
             // Only update if text is different to avoid cursor jumps
             if (firstNameController.text != (data.firstName ?? "")) firstNameController.text = data.firstName ?? "";
             if (lastNameController.text != (data.lastName ?? "")) lastNameController.text = data.lastName ?? "";
             if (data.dateOfBirth != null && data.dateOfBirth != selectedDob.value) {
                selectedDob.value = data.dateOfBirth;
                dobController.text = DateFormat.yMMMd().format(data.dateOfBirth!);
             } else if (data.dateOfBirth == null) {
                dobController.clear();
                selectedDob.value = null;
             }
             if (selectedGender.value != data.gender) selectedGender.value = data.gender;
             // ... and so on for all fields
          }
        },
        builder: (context, state) {
          final currentStep = state.map(
            initial: (_) => 0,
            formInProgress: (s) => s.currentStep,
            submissionSuccess: (_) => 0, // Or last step
            submissionFailure: (s) => s.currentStepOnError,
            syncingQueuedData: (_) => (bloc.state as? PatientRegistrationFormInProgress)?.currentStep ?? 0, // Keep current step during sync
            syncCompleted: (_) => (bloc.state as? PatientRegistrationFormInProgress)?.currentStep ?? 0,
          );

          final isLoading = state.map(
            initial: (_) => true, // Initializing
            formInProgress: (s) => s.isSubmitting,
            submissionSuccess: (_) => false,
            submissionFailure: (_) => false,
             syncingQueuedData: (_) => true,
            syncCompleted: (_) => false,
          );

          List<Step> steps = [
            _buildStep1(context, step1FormKey, firstNameController, lastNameController, dobController, selectedDob, selectedGender, nationalIdController, _selectDate, fnFirstName, fnLastName, fnNationalId, isLoading),
            _buildStep2(context, step2FormKey, phoneController, addressController, villageController, districtController, fnPhone, fnAddress, fnVillage, fnDistrict, isLoading),
            _buildStep3(context, step3FormKey, heightController, weightController, allergiesController, conditionsController, fnHeight, fnWeight, fnAllergies, fnConditions, isLoading),
            _buildStep4(context, step4FormKey, consentServices, consentDataSharing, isLoading),
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Register New Patient'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: isLoading ? null : () => context.pop(),
              ),
            ),
            body: isLoading && !(state is PatientRegistrationFormInProgress && (state as PatientRegistrationFormInProgress).isSubmitting) && !(state is SyncingQueuedData)
                ? Center(child: Lottie.asset('assets/animations/loader_initial.json', width: 100, height: 100, errorBuilder: (c,e,s) => CircularProgressIndicator()))
                : Stepper(
              type: StepperType.horizontal,
              currentStep: currentStep,
              physics: const ClampingScrollPhysics(),
              onStepTapped: (step) {
                if (!isLoading) {
                  _updateBlocWithFormData(state);
                  bloc.add(GoToStep(step));
                  HapticFeedback.lightImpact();
                }
              },
              onStepContinue: () {
                if (isLoading) return;
                _updateBlocWithFormData(state);
                bool isValid = false;
                if (currentStep == 0) isValid = step1FormKey.currentState?.validate() ?? false;
                if (currentStep == 1) isValid = step2FormKey.currentState?.validate() ?? false;
                if (currentStep == 2) isValid = step3FormKey.currentState?.validate() ?? false;
                if (currentStep == 3) isValid = step4FormKey.currentState?.validate() ?? false; // Consent step validation

                if (isValid) {
                  if (currentStep < steps.length - 1) {
                    bloc.add(const NextStep());
                    HapticFeedback.lightImpact();
                  } else {
                    // Last step, submit form
                    bloc.add(const SubmitRegistration());
                  }
                } else {
                  HapticFeedback.heavyImpact(); // Validation error
                }
              },
              onStepCancel: () {
                if (isLoading) return;
                 _updateBlocWithFormData(state);
                if (currentStep > 0) {
                  bloc.add(const PreviousStep());
                  HapticFeedback.lightImpact();
                } else {
                  context.pop(); // Cancel from first step
                }
              },
              controlsBuilder: (BuildContext context, ControlsDetails details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      if (currentStep > 0)
                        TextButton(
                          onPressed: isLoading ? null : details.onStepCancel,
                          child: const Text('BACK'),
                        ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isLoading ? null : details.onStepContinue,
                        child: (state is PatientRegistrationFormInProgress && (state as PatientRegistrationFormInProgress).isSubmitting)
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(currentStep == steps.length - 1 ? 'SUBMIT' : 'NEXT'),
                      ),
                    ],
                  ),
                );
              },
              steps: steps,
            ),
          );
        },
      ),
    );
  }

  // Step 1: Demographics
  Step _buildStep1(BuildContext context, GlobalKey<FormState> key, TextEditingController fnCtrl, TextEditingController lnCtrl, TextEditingController dobCtrl, ValueNotifier<DateTime?> selDob, ValueNotifier<String?> selGender, TextEditingController natIdCtrl, Function(BuildContext) pickDate, FocusNode fnFN, FocusNode fnLN, FocusNode fnNatId, bool isLoading) {
    final List<String> genderOptions = ['Male', 'Female', 'Other'];
    return Step(
      title: const Text('Demographics'),
      isActive: true, // Manage isActive based on currentStep
      state: StepState.indexed, // Manage state (error, complete)
      content: Form(
        key: key,
        child: Column(children: <Widget>[
          KineticFormField(controller: fnCtrl, labelText: 'First Name', focusNode: fnFN, textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(fnLN), validator: (v) => v!.isEmpty ? 'Required' : null, isEnabled: !isLoading),
          const SizedBox(height: 16),
          KineticFormField(controller: lnCtrl, labelText: 'Last Name', focusNode: fnLN, textInputAction: TextInputAction.next, onFieldSubmitted: (_) => pickDate(context), validator: (v) => v!.isEmpty ? 'Required' : null, isEnabled: !isLoading),
          const SizedBox(height: 16),
          TextFormField(
            controller: dobCtrl,
            decoration: const InputDecoration(labelText: 'Date of Birth', hintText: 'Select date', border: OutlineInputBorder()),
            readOnly: true,
            onTap: () => isLoading ? null : pickDate(context),
            validator: (v) => selDob.value == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
            value: selGender.value,
            items: genderOptions.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
            onChanged: isLoading ? null : (String? newValue) => selGender.value = newValue,
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          KineticFormField(controller: natIdCtrl, labelText: 'National ID (Optional)', focusNode: fnNatId, textInputAction: TextInputAction.done, isEnabled: !isLoading),
        ]),
      ),
    );
  }

  // Step 2: Contact Info
  Step _buildStep2(BuildContext context, GlobalKey<FormState> key, TextEditingController phCtrl, TextEditingController adCtrl, TextEditingController vlCtrl, TextEditingController diCtrl, FocusNode fnPh, FocusNode fnAd, FocusNode fnVl, FocusNode fnDi, bool isLoading) {
     return Step(
      title: const Text('Contact'),
      isActive: true,
      content: Form(
        key: key,
        child: Column(children: <Widget>[
          KineticFormField(controller: phCtrl, labelText: 'Phone Number', keyboardType: TextInputType.phone, focusNode: fnPh, textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(fnAd), validator: (v) => v!.isEmpty ? 'Required' : null, isEnabled: !isLoading),
          const SizedBox(height: 16),
          KineticFormField(controller: adCtrl, labelText: 'Address Line 1', focusNode: fnAd, textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(fnVl), validator: (v) => v!.isEmpty ? 'Required' : null, isEnabled: !isLoading),
          const SizedBox(height: 16),
          KineticFormField(controller: vlCtrl, labelText: 'Village/Area', focusNode: fnVl, textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(fnDi), validator: (v) => v!.isEmpty ? 'Required' : null, isEnabled: !isLoading),
          const SizedBox(height: 16),
          KineticFormField(controller: diCtrl, labelText: 'District/Upazila', focusNode: fnDi, textInputAction: TextInputAction.done, validator: (v) => v!.isEmpty ? 'Required' : null, isEnabled: !isLoading),
        ]),
      ),
    );
  }

  // Step 3: Health Info
  Step _buildStep3(BuildContext context, GlobalKey<FormState> key, TextEditingController hCtrl, TextEditingController wCtrl, TextEditingController algCtrl, TextEditingController conCtrl, FocusNode fnH, FocusNode fnW, FocusNode fnAlg, FocusNode fnCon, bool isLoading) {
    return Step(
      title: const Text('Health'),
      isActive: true,
      content: Form(
        key: key,
        child: Column(children: <Widget>[
          KineticFormField(controller: hCtrl, labelText: 'Height (cm)', keyboardType: TextInputType.number, focusNode: fnH, textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(fnW), validator: (v) { if(v!.isEmpty) return 'Required'; if(double.tryParse(v) == null) return 'Invalid number'; return null;}, isEnabled: !isLoading),
          const SizedBox(height: 16),
          KineticFormField(controller: wCtrl, labelText: 'Weight (kg)', keyboardType: TextInputType.number, focusNode: fnW, textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(fnAlg), validator: (v) { if(v!.isEmpty) return 'Required'; if(double.tryParse(v) == null) return 'Invalid number'; return null;}, isEnabled: !isLoading),
          const SizedBox(height: 16),
          KineticFormField(controller: algCtrl, labelText: 'Known Allergies (comma-separated, optional)', focusNode: fnAlg, textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(fnCon), isEnabled: !isLoading),
          const SizedBox(height: 16),
          KineticFormField(controller: conCtrl, labelText: 'Pre-existing Conditions (comma-separated, optional)', focusNode: fnCon, textInputAction: TextInputAction.done, isEnabled: !isLoading),
        ]),
      ),
    );
  }

  // Step 4: Consent
  Step _buildStep4(BuildContext context, GlobalKey<FormState> key, ValueNotifier<bool?> conSvc, ValueNotifier<bool?> conData, bool isLoading) {
    return Step(
      title: const Text('Consent'),
      isActive: true,
      content: Form(
        key: key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          CheckboxListTile(
            title: const Text('I consent to receive healthcare services and follow-ups.'),
            value: conSvc.value ?? false,
            onChanged: isLoading ? null : (bool? value) => conSvc.value = value,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          if (conSvc.value == false) // Only show error if explicitly set to false, null means not yet interacted
             Padding(
               padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
               child: Text('Consent for services is required.', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
             ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('I consent to my anonymized data being used for research and public health purposes (optional).'),
            value: conData.value ?? false,
            onChanged: isLoading ? null : (bool? value) => conData.value = value,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          // Custom validator for the form, not individual fields here
           FormField<bool>(
              builder: (state) {
                if (conSvc.value != true) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Please provide consent for services to proceed.',
                       style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }
                return Container();
              },
              validator: (_) {
                if (conSvc.value != true) {
                  return 'Consent for services is mandatory.';
                }
                return null;
              },
            ),
        ]),
      ),
    );
  }
}
