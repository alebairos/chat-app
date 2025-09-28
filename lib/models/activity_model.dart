import 'dart:convert';
import 'package:isar/isar.dart';
import '../utils/utf8_fix.dart';

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

  // FT-156: Message linking fields
  String? sourceMessageId;     // Links to triggering message
  String? sourceMessageText;   // What user actually said

  // Metadata
  late DateTime createdAt;
  double confidenceScore = 1.0; // AI detection confidence 0.0-1.0
  String? metadata; // JSON string of flat key-value metadata

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
    Map<String, dynamic> metadata = const {},
    // FT-156: Message linking parameters
    this.sourceMessageId,
    this.sourceMessageText,
  })  : completedAt = completedAt,
        hour = completedAt.hour,
        minute = completedAt.minute,
        dayOfWeek = dayOfWeek,
        timeOfDay = timeOfDay,
        timestamp = completedAt,
        createdAt = DateTime.now(),
        metadata = metadata.isNotEmpty ? _encodeMetadataWithUTF8Fix(metadata) : null;

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
    // FT-156: Message linking parameters
    this.sourceMessageId,
    this.sourceMessageText,
  })  : activityCode = null,
        source = 'Custom',
        completedAt = completedAt,
        hour = completedAt.hour,
        minute = completedAt.minute,
        dayOfWeek = dayOfWeek,
        timeOfDay = timeOfDay,
        timestamp = completedAt,
        createdAt = DateTime.now(),
        metadata = null;

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

  @override
  String toString() =>
      'ActivityModel(${isOracleActivity ? activityCode : 'custom'}: $activityName at $formattedTime on $dayOfWeek)';

  /// Encode metadata with UTF-8 fix applied to string values
  static String _encodeMetadataWithUTF8Fix(Map<String, dynamic> metadata) {
    final fixedMetadata = <String, dynamic>{};
    
    for (final entry in metadata.entries) {
      dynamic value = entry.value;
      if (value is String) {
        // Fix UTF-8 encoding issues before storing
        value = UTF8Fix.fix(value);
      }
      fixedMetadata[entry.key] = value;
    }
    
    return jsonEncode(fixedMetadata);
  }
}
