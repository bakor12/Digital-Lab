// File: lib/features/dashboard/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:rural_health_app/core/di/injector.dart';
import 'package:rural_health_app/core/router/app_router.dart';
import 'package:rural_health_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rural_health_app/features/dashboard/data/models/dashboard_models.dart';
import 'package:rural_health_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:rural_health_app/features/dashboard/presentation/widgets/patient_card.dart';
import 'package:intl/intl.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider(
      create: (context) =>
          getIt<DashboardBloc>()..add(const FetchDashboardDataRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CHW Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthBloc>().add(const LogoutRequested());
                // AuthBloc listener in main_app or router will handle navigation
              },
            ),
          ],
        ),
        body: BlocConsumer<DashboardBloc, DashboardState>(
          listener: (context, state) {
            // Handle any side effects, like showing snackbars for errors if not handled globally
          },
          builder: (context, state) {
            return state.when(
              initial: () => Center(
                child: Lottie.asset(
                    'assets/animations/loader_initial.json', // Replace with your Lottie file
                    width: 150,
                    height: 150,
                    errorBuilder: (ctx, err, st) => const CircularProgressIndicator()),
              ),
              loading: () => Center(
                child: Lottie.asset(
                    'assets/animations/loader_loading.json', // Replace with your Lottie file
                    width: 150,
                    height: 150,
                    errorBuilder: (ctx, err, st) => const CircularProgressIndicator()),
              ),
              loaded: (dashboardData, isStale) =>
                  _buildDashboardContent(context, theme, dashboardData, isStale),
              error: (message) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/error_general.json', // Replace with your Lottie file
                      width: 180,
                      height: 180,
                      errorBuilder: (ctx, err, st) => const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    Text(message, style: theme.textTheme.titleMedium?.copyWith(color: Colors.red)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: () {
                        context.read<DashboardBloc>().add(const RefreshDashboardDataRequested());
                      },
                    )
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.pushNamed(AppRoutes.patientRegistration);
          },
          label: const Text('Register Patient'),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, ThemeData theme, ChwDashboardData data, bool isStale) {
    String formattedLastUpdated = data.lastUpdatedAt != null
        ? 'Last updated: ${DateFormat.yMMMd().add_jm().format(data.lastUpdatedAt!)}'
        : 'Last update time unknown';

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DashboardBloc>().add(const RefreshDashboardDataRequested());
        // Completer can be used here if needed, but BLoC handles state.
      },
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (isStale)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    color: Colors.amber.shade700,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Displaying offline data. $formattedLastUpdated',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                if (!isStale && data.lastUpdatedAt != null)
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 8.0),
                     child: Text(
                        formattedLastUpdated,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                   ),
                _buildSummarySection(context, theme, data.summary),
                Padding(
                  padding: const EdgeInsets.all(16.0).copyWith(bottom:8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assigned Patients (${data.assignedPatients.length})',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      // Potentially add a search/filter icon here
                    ],
                  ),
                ),
              ],
            ),
          ),
          data.assignedPatients.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/animations/empty_patients.json', // Replace
                          width: 200,
                          height: 200,
                           errorBuilder: (ctx, err, st) => const Icon(Icons.people_outline, size: 60, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Text('No patients assigned or found.', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Register a new patient to get started.', style: theme.textTheme.bodyMedium),

                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0).copyWith(bottom: 80), // FAB space
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final patient = data.assignedPatients[index];
                        return PatientCard(
                          patient: patient,
                          onTap: () {
                            // TODO: Navigate to patient detail screen
                            // context.pushNamed(AppRoutes.patientDetail, pathParameters: {'patientId': patient.patientId});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Tapped on ${patient.name}')),
                            );
                          },
                        );
                      },
                      childCount: data.assignedPatients.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, ThemeData theme, DashboardSummary summary) {
    final cardColor = theme.scaffoldBackgroundColor;
    final lightShadow = theme.brightness == Brightness.light
        ? Colors.white.withOpacity(0.7)
        : Colors.grey.shade800;
    final darkShadow = theme.brightness == Brightness.light
        ? Colors.black.withOpacity(0.15)
        : Colors.black.withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8, // Adjust for desired card shape
        children: [
          _buildSummaryCard(theme, cardColor, lightShadow, darkShadow, 'Total Patients', summary.totalPatients.toString(), Icons.groups_2_outlined, Colors.blue.shade300),
          _buildSummaryCard(theme, cardColor, lightShadow, darkShadow, 'High Risk', summary.highRiskPatients.toString(), Icons.dangerous_outlined, Colors.red.shade300),
          _buildSummaryCard(theme, cardColor, lightShadow, darkShadow, 'Medium Risk', summary.mediumRiskPatients.toString(), Icons.warning_amber_rounded, Colors.orange.shade300),
          _buildSummaryCard(theme, cardColor, lightShadow, darkShadow, 'Pending Syncs', summary.pendingSyncs.toString(), Icons.sync_problem_outlined, Colors.purple.shade300),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, Color cardColor, Color lightShadow, Color darkShadow, String title, String count, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(color: darkShadow, offset: const Offset(3, 3), blurRadius: 6),
          BoxShadow(color: lightShadow, offset: const Offset(-3, -3), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              Icon(icon, color: iconColor, size: 28),
            ],
          ),
          Text(count, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        ],
      ),
    );
  }
}
