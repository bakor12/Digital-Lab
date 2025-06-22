// File: lib/features/dashboard/data/models/dashboard_models.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'dashboard_models.freezed.dart';
part 'dashboard_models.g.dart';

/// Represents the overall data structure for the CHW dashboard.
/// This model is expected to be returned by the API endpoint GET /chw/dashboard.
/// It should also be cachable in Hive.
@freezed
@HiveType(typeId: 1) // Ensure typeId is unique
class ChwDashboardData with _$ChwDashboardData {
  const factory ChwDashboardData({
    @HiveField(0) required String chwId,
    @HiveField(1) required String chwName,
    @HiveField(2) required DashboardSummary summary,
    @HiveField(3) required List<PatientSummaryModel> assignedPatients,
    @HiveField(4) DateTime? lastUpdatedAt, // Timestamp of when data was fetched from API
  }) = _ChwDashboardData;

  factory ChwDashboardData.fromJson(Map<String, dynamic> json) =>
      _$ChwDashboardDataFromJson(json);
}

/// Summary statistics for the dashboard.
@freezed
@HiveType(typeId: 2) // Ensure typeId is unique
class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    @HiveField(0) required int totalPatients,
    @HiveField(1) required int highRiskPatients,
    @HiveField(2) required int mediumRiskPatients,
    @HiveField(3) required int lowRiskPatients,
    @HiveField(4) required int pendingSyncs, // For offline submitted registrations
  }) = _DashboardSummary;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
}

/// Represents a summary of a patient for display on the dashboard.
@freezed
@HiveType(typeId: 3) // Ensure typeId is unique
class PatientSummaryModel with _$PatientSummaryModel {
  const factory PatientSummaryModel({
    @HiveField(0) required String patientId,
    @HiveField(1) required String name,
    @HiveField(2) required int age,
    @HiveField(3) required String gender, // e.g., "Male", "Female", "Other"
    @HiveField(4) required PatientRiskLevel riskLevel,
    @HiveField(5) String? lastVisitDate, // ISO 8601 date string
    @HiveField(6) String? village,
    @HiveField(7) String? contactNumber,
  }) = _PatientSummaryModel;

  factory PatientSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$PatientSummaryModelFromJson(json);
}

/// Enum for patient risk levels.
@HiveType(typeId: 4) // Ensure typeId is unique
enum PatientRiskLevel {
  @HiveField(0)
  @JsonValue("Low")
  low,

  @HiveField(1)
  @JsonValue("Medium")
  medium,

  @HiveField(2)
  @JsonValue("High")
  high,

  @HiveField(3)
  @JsonValue("Unknown")
  unknown, // Default or if data is missing
}

// Helper to convert PatientRiskLevel to String for JSON and vice-versa
// Not strictly needed with @JsonValue but can be useful for other logic
String patientRiskLevelToString(PatientRiskLevel level) {
  switch (level) {
    case PatientRiskLevel.low:
      return "Low";
    case PatientRiskLevel.medium:
      return "Medium";
    case PatientRiskLevel.high:
      return "High";
    default:
      return "Unknown";
  }
}

PatientRiskLevel patientRiskLevelFromString(String? levelStr) {
  switch (levelStr?.toLowerCase()) {
    case "low":
      return PatientRiskLevel.low;
    case "medium":
      return PatientRiskLevel.medium;
    case "high":
      return PatientRiskLevel.high;
    default:
      return PatientRiskLevel.unknown;
  }
}
