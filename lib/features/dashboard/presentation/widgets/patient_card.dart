// File: lib/features/dashboard/presentation/widgets/patient_card.dart
import 'package:flutter/material.dart';
import 'package:rural_health_app/features/dashboard/data/models/dashboard_models.dart';
import 'package:intl/intl.dart'; // For date formatting

class PatientCard extends StatelessWidget {
  final PatientSummaryModel patient;
  final VoidCallback? onTap;

  const PatientCard({
    super.key,
    required this.patient,
    this.onTap,
  });

  Color _getRiskColor(PatientRiskLevel riskLevel, BuildContext context) {
    switch (riskLevel) {
      case PatientRiskLevel.low:
        return Colors.green.shade400;
      case PatientRiskLevel.medium:
        return Colors.orange.shade400;
      case PatientRiskLevel.high:
        return Colors.red.shade400;
      case PatientRiskLevel.unknown:
      default:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat.yMMMd().format(dateTime); // e.g., Sep 10, 2023
    } catch (e) {
      return dateStr; // Return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = _getRiskColor(patient.riskLevel, context);
    final cardColor = theme.scaffoldBackgroundColor; // Base color for Neumorphism

    // Neumorphic shadow values
    final lightShadow = theme.brightness == Brightness.light
        ? Colors.white.withOpacity(0.7)
        : Colors.grey.shade800;
    final darkShadow = theme.brightness == Brightness.light
        ? Colors.black.withOpacity(0.15)
        : Colors.black.withOpacity(0.5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: darkShadow,
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
            BoxShadow(
              color: lightShadow,
              offset: const Offset(-4, -4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    patient.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: riskColor, width: 1.5)
                  ),
                  child: Text(
                    patientRiskLevelToString(patient.riskLevel),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.cake_outlined,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Age: ${patient.age}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Icon(
                    patient.gender.toLowerCase() == 'male'
                        ? Icons.male_outlined
                        : patient.gender.toLowerCase() == 'female'
                            ? Icons.female_outlined
                            : Icons.transgender_outlined, // Or a generic person icon
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  patient.gender,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (patient.village != null && patient.village!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.home_work_outlined,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Village: ${patient.village}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Row(
              children: [
                Icon(Icons.event_note_outlined,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Last Visit: ${_formatDate(patient.lastVisitDate)}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            if (patient.contactNumber != null && patient.contactNumber!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.phone_outlined,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    patient.contactNumber!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
             const SizedBox(height: 4), // Minor padding at the bottom
          ],
        ),
      ),
    );
  }
}
