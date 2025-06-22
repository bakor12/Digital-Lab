// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rural_health_app/core/cache/hive_service.dart';
import 'package:rural_health_app/core/di/injector.dart';
import 'package:rural_health_app/core/router/app_router.dart';
import 'package:rural_health_app/features/auth/presentation/bloc/auth_bloc.dart';
// Import your app theme if you have one
// import 'package:rural_health_app/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Configure Dependency Injection
  await configureDependencies();

  // 2. Initialize Hive
  // It's important to register adapters BEFORE opening any boxes that use them.
  // Since models are spread across features, their adapters also need to be generated
  // and HiveService's init() method should be updated to register them.
  // For now, we call init which includes adapter registration (assuming they are added there).
  await getIt<HiveService>().init();


  // 3. Optional: Initialize other services like Firebase, notifications, etc.

  runApp(const RuralHealthApp());
}

class RuralHealthApp extends StatelessWidget {
  const RuralHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()
          // Initial event to check auth status can be dispatched here or in AuthBloc constructor
          // For example, if AuthBloc's constructor calls _checkInitialAuthStatus
          // or listens to a stream from AuthRepository that emits initial status.
          // The current AuthBloc setup listens to `authStatusChanges` stream from repo.
        ),
        // Add other global BLoCs here if needed
      ],
      child: MaterialApp.router(
        title: 'Rural Health Platform',
        debugShowCheckedModeBanner: false, // Set to true for debugging visuals

        // Theme (customize as needed)
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal, // Primary app color
            brightness: Brightness.light,
          ),
          // Define other theme properties like text themes, button themes, etc.
          // Example:
          // textTheme: AppTextTheme.light,
          // elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtonStyles.elevatedDefault),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          ),
          cardTheme: CardTheme(
            elevation: 0, // Using Neumorphic, so default card elevation might not be desired
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          ),
          // Define dark theme specifics
        ),
        themeMode: ThemeMode.system, // Or ThemeMode.light / ThemeMode.dark

        routerConfig: appRouter.router,
        // localizationsDelegates and supportedLocales if you add localization
      ),
    );
  }
}

// Example of how AuthBloc listener in router or here could handle navigation:
// This is more suitable if you need context for navigation.
// If AppRouter handles redirects based on AuthBloc state, this might not be needed here.
//
// class AppRoot extends HookWidget {
//   const AppRoot({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final appRouter = getIt<AppRouter>();
//     return BlocListener<AuthBloc, AuthState>(
//       listener: (context, state) {
//         state.mapOrNull(
//           authenticated: (_) {
//             // If router doesn't auto-redirect, do it here
//             // Check current route to avoid pushing dashboard if already there or in a sub-route
//             // final currentRoute = GoRouter.of(context).location;
//             // if (currentRoute == AppRoutes.loginPath || currentRoute == AppRoutes.splashPath) {
//             //   context.goNamed(AppRoutes.dashboard);
//             // }
//           },
//           unauthenticated: (_) {
//             // context.goNamed(AppRoutes.login);
//           }
//         );
//       },
//       child: MaterialApp.router(
//         title: 'Rural Health Platform',
//         // ... other MaterialApp properties
//         routerConfig: appRouter.router,
//       ),
//     );
// }
