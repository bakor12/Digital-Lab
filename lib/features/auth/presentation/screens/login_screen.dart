// File: lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For haptic feedback
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:rural_health_app/core/router/app_router.dart';
import 'package:rural_health_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rural_health_app/core/di/injector.dart'; // For GetIt

// Placeholder for a custom text field with kinetic animations
class KineticTextFormField extends HookWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final FocusNode focusNode;
  final TextInputAction textInputAction;
  final Function(String)? onFieldSubmitted;

  const KineticTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.obscureText = false,
    this.validator,
    required this.focusNode,
    required this.textInputAction,
    this.onFieldSubmitted,
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
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            labelStyle: TextStyle(
                color: isFocused.value
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorAnimation.value!, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline, width: 1.5),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        );
      },
    );
  }
}

class LoginScreen extends HookWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final usernameFocusNode = useFocusNode();
    final passwordFocusNode = useFocusNode();

    // Function to handle login submission
    void submitLogin(BuildContext context) {
      if (formKey.currentState?.validate() ?? false) {
        HapticFeedback.mediumImpact(); // Data-driven haptic feedback
        context.read<AuthBloc>().add(AuthEvent.loginRequested(
              username: usernameController.text.trim(),
              password: passwordController.text.trim(),
            ));
      } else {
        HapticFeedback.heavyImpact(); // Critical validation error haptic
      }
    }

    return BlocProvider(
      create: (context) => getIt<AuthBloc>(),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          state.mapOrNull(
            authenticated: (authState) {
              HapticFeedback.lightImpact(); // Success haptic
              context.goNamed(AppRoutes.dashboard);
            },
            failure: (authState) {
              HapticFeedback.heavyImpact(); // Error haptic
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(authState.message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
            },
          );
        },
        builder: (context, state) {
          final isLoading = state.isLoading;

          return Scaffold(
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Lottie Animation for Login Icon/Header
                      SizedBox(
                        height: 180,
                        child: Lottie.asset(
                          'assets/animations/login_animation.json', // Replace with your Lottie file
                          width: 150,
                          height: 150,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.lock_outline, size: 80),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome Back!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Login to access your CHW dashboard.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 32),
                      KineticTextFormField(
                        controller: usernameController,
                        focusNode: usernameFocusNode,
                        labelText: 'Username',
                        hintText: 'Enter your username',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(passwordFocusNode);
                        },
                      ),
                      const SizedBox(height: 20),
                      KineticTextFormField(
                        controller: passwordController,
                        focusNode: passwordFocusNode,
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => submitLogin(context),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password functionality
                          },
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: isLoading ? null : () => submitLogin(context),
                        child: isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text('Login', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 20),
                      // Add any other elements like "Or sign in with" or "Don't have an account?"
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
