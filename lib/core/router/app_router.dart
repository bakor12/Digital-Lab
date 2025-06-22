// File: lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:rural_health_app/features/auth/presentation/screens/login_screen.dart';
import 'package:rural_health_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:rural_health_app/features/patient_registration/presentation/screens/patient_registration_screen.dart';
// Import other screens as they are created e.g. SplashScreen

// Placeholder for a splash screen if you add one
// import 'package:rural_health_app/features/splash/presentation/screens/splash_screen.dart';

@injectable
class AppRouter {
  // For simplicity, making router public. In a larger app, you might wrap it or use a service.
  late final GoRouter router;

  // TODO: Add AuthBloc or similar to listen to auth state changes for redirection
  // final AuthBloc authBloc; // Example: Inject AuthBloc

  // Navigator key
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell'); // If using ShellRoute

  AppRouter(/*this.authBloc*/) {
    router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.loginPath, // Or splashPath if you have one
      debugLogDiagnostics: true, // Enable for debugging
      routes: [
        // GoRoute(
        //   path: AppRoutes.splashPath,
        //   name: AppRoutes.splash,
        //   builder: (context, state) => SplashScreen(), // Replace with your SplashScreen
        // ),
        GoRoute(
          path: AppRoutes.loginPath,
          name: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.dashboardPath,
          name: AppRoutes.dashboard,
          builder: (context, state) => const DashboardScreen(),
          // redirect: (context, state) {
          //   // Example: Redirect to login if not authenticated
          //   final isAuthenticated = authBloc.state.isAuthenticated; // Adapt to your AuthBloc state
          //   if (!isAuthenticated) {
          //     return AppRoutes.loginPath;
          //   }
          //   return null; // No redirect
          // },
        ),
        GoRoute(
          path: AppRoutes.patientRegistrationPath,
          name: AppRoutes.patientRegistration,
          builder: (context, state) => const PatientRegistrationScreen(),
          // redirect: (context, state) { // Protect this route too
          //   final isAuthenticated = authBloc.state.isAuthenticated;
          //   if (!isAuthenticated) {
          //     return AppRoutes.loginPath;
          //   }
          //   return null;
          // },
        ),
        // Add other routes here
      ],
      // errorBuilder: (context, state) => ErrorScreen(error: state.error), // Optional error screen
      // redirect: (BuildContext context, GoRouterState state) {
      //   // This is a global redirect. You might want to check auth state here
      //   // and redirect to login if not authenticated and not already on login page.
      //   final loggedIn = authBloc.state.isAuthenticated; // Your auth state
      //   final loggingIn = state.matchedLocation == AppRoutes.loginPath;

      //   if (!loggedIn && !loggingIn && state.matchedLocation != AppRoutes.splashPath) {
      //     return AppRoutes.loginPath;
      //   }
      //   if (loggedIn && (loggingIn || state.matchedLocation == AppRoutes.splashPath)) {
      //     return AppRoutes.dashboardPath;
      //   }
      //   return null; // No redirect
      // },
    );
  }
}

/// Contains all route names and paths for the application.
class AppRoutes {
  // static const String splash = 'splash';
  // static const String splashPath = '/';

  static const String login = 'login';
  static const String loginPath = '/login'; // Changed initial to /login for now

  static const String dashboard = 'dashboard';
  static const String dashboardPath = '/dashboard';

  static const String patientRegistration = 'patientRegistration';
  static const String patientRegistrationPath = '/patient-registration';

  // Example for a patient detail screen
  // static const String patientDetail = 'patientDetail';
  // static const String patientDetailPath = '/patient/:patientId';
}

// Example of how to use typed routes for parameters if needed:
// class PatientDetailsRoute extends GoRouteData {
//   final String patientId;
//   const PatientDetailsRoute({required this.patientId});

//   @override
//   Widget build(BuildContext context, GoRouterState state) => PatientDetailScreen(patientId: patientId);
// }

// You would then define it in GoRouter routes:
// TypedGoRoute<PatientDetailsRoute>(
//   path: AppRoutes.patientDetailPath,
//   routes: [
//     // any sub-routes
//   ]
// ),
// And navigate using:
// context.goNamed(AppRoutes.patientDetail, pathParameters: {'patientId': '123'});
// or context.push(PatientDetailsRoute(patientId: '123').location); (if using typed routes)
