import 'dart:convert';
import 'package:isar/isar.dart';

part 'activity_model.g.dart';

/// Model for storing completed activities with rich metadata
@collection
class ActivityModel {
  Id id = Isar.autoIncrement;

  // Activity identification
  String? activityCode; // "SF1", null for custom activities
  late String activityName; // "Beber água", "Academia treino"
  late String dimension; // "saude_fisica", "custom"
  late String source; // "Oracle oracle_prompt_2.1.md", "Custom"

  // FT-064 Semantic detection fields
  String? description; // Oracle activity description
  String? userDescription; // How user described the activity
  late DateTime timestamp; // When activity was completed
  String? confidence; // Detection confidence level
  String? reasoning; // Why this activity was detected
  String? detectionMethod; // "semantic_ft064", "keyword", etc.
  String? timeContext; // Readable time context

  // Completion details (FT-060 integration)
  late DateTime completedAt;
  late int hour; // 0-23
  late int minute; // 0-59
  late String dayOfWeek; // "Monday", "Tuesday", etc.
  late String timeOfDay; // "morning", "afternoon", "evening", "night"
  int? durationMinutes; // Optional duration
  String? notes; // Optional user notes

  // FT-149: Metadata Intelligence fields
  String? metadata; // JSON string of extracted metadata
  String? metadataTypes; // JSON string of metadata type information

  // Metadata
  late DateTime createdAt;
  double confidenceScore = 1.0; // AI detection confidence 0.0-1.0

  /// Constructor
  ActivityModel();

  /// Create from detected activity with precise time data
  ActivityModel.fromDetection({
    required this.activityCode,
    required this.activityName,
    required this.dimension,
    required this.source,
    required DateTime completedAt,
    required String dayOfWeek,
    required String timeOfDay,
    this.durationMinutes,
    this.notes,
    this.confidenceScore = 1.0,
  })  : completedAt = completedAt,
        hour = completedAt.hour,
        minute = completedAt.minute,
        dayOfWeek = dayOfWeek,
        timeOfDay = timeOfDay,
        timestamp = completedAt,
        createdAt = DateTime.now();

  /// Create custom activity
  ActivityModel.custom({
    required this.activityName,
    required this.dimension,
    required DateTime completedAt,
    required String dayOfWeek,
    required String timeOfDay,
    this.durationMinutes,
    this.notes,
    this.confidenceScore = 1.0,
  })  : activityCode = null,
        source = 'Custom',
        completedAt = completedAt,
        hour = completedAt.hour,
        minute = completedAt.minute,
        dayOfWeek = dayOfWeek,
        timeOfDay = timeOfDay,
        timestamp = completedAt,
        createdAt = DateTime.now();

  /// Check if this is an Oracle activity
  bool get isOracleActivity => activityCode != null;

  /// Check if this is a custom activity
  bool get isCustomActivity => activityCode == null;

  /// Get formatted completion time
  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Get formatted completion date
  String get formattedDate =>
      '${completedAt.day}/${completedAt.month}/${completedAt.year}';

  /// Get human-readable activity description
  String get activityDescription {
    final buffer = StringBuffer();

    if (isOracleActivity) {
      buffer.write('$activityCode: ');
    }

    buffer.write(activityName);

    if (durationMinutes != null && durationMinutes! > 0) {
      buffer.write(' (${durationMinutes}min)');
    }

    return buffer.toString();
  }

  // FT-149: Metadata helper methods
  /// Check if activity has metadata
  bool get hasMetadata => metadata != null && metadata!.isNotEmpty;

  /// Get metadata as Map (with safe parsing)
  Map<String, dynamic>? get metadataMap {
    if (metadata == null) return null;
    try {
      final decoded = json.decode(metadata!);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Set metadata from Map
  set metadataMap(Map<String, dynamic>? value) {
    if (value == null) {
      metadata = null;
    } else {
      try {
        final safeMap = Map<String, dynamic>.from(value);
        metadata = json.encode(safeMap);
      } catch (e) {
        metadata = null;
      }
    }
  }

  @override
  String toString() =>
      'ActivityModel(${isOracleActivity ? activityCode : 'custom'}: $activityName at $formattedTime on $dayOfWeek)';
}
