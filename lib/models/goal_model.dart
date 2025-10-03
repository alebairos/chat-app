import 'package:isar/isar.dart';

part 'goal_model.g.dart';

/// Model for storing user goals based on Oracle framework objectives
///
/// FT-174: Minimal first cut - stores basic goal information
/// linked to Oracle objectives for LLM-driven goal management
@collection
class GoalModel {
  Id id = Isar.autoIncrement;

  // Oracle objective identification
  late String objectiveCode; // "OPP1", "OGM1", "ODM1", etc.
  late String objectiveName; // "Perder peso", "Ganhar massa", etc.

  // Goal metadata
  late DateTime createdAt; // When goal was created
  bool isActive = true; // Whether goal is currently active

  /// Constructor
  GoalModel();

  /// Create goal from Oracle objective
  GoalModel.fromObjective({
    required this.objectiveCode,
    required this.objectiveName,
  })  : createdAt = DateTime.now(),
        isActive = true;

  /// Get formatted creation date
  String get formattedCreatedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Get goal display name (same as objective name for now)
  String get displayName => objectiveName;

  @override
  String toString() {
    return 'GoalModel(id: $id, code: $objectiveCode, name: $objectiveName, created: $createdAt, active: $isActive)';
  }
}
