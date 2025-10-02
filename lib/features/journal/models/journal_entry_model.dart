import 'package:isar/isar.dart';

part 'journal_entry_model.g.dart';

/// Model for storing daily journal entries with rich metadata for future memory fine-tuning
@collection
class JournalEntryModel {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date; // Date the journal represents (not creation time)

  @Index()
  late DateTime createdAt; // When journal was generated

  @Index()
  late String language; // 'pt_BR' or 'en_US'

  late String content; // Full I-There journal text

  // Metadata for future memory fine-tuning
  late int messageCount; // Number of messages analyzed
  late int activityCount; // Number of activities analyzed
  String? oracleVersion; // e.g., "4.2"
  String? personaKey; // e.g., "iThereWithOracle42"

  // Generation metadata
  late double generationTimeSeconds;
  String? promptVersion; // For tracking prompt evolution

  // Future memory fine-tuning fields
  String? extractedInsights; // JSON string of personality insights
  double? memoryRelevanceScore; // 0.0-1.0 for future memory selection

  JournalEntryModel();

  JournalEntryModel.create({
    required this.date,
    required this.language,
    required this.content,
    required this.messageCount,
    required this.activityCount,
    this.oracleVersion,
    this.personaKey,
    required this.generationTimeSeconds,
    this.promptVersion,
  }) : createdAt = DateTime.now();

  /// Get a summary of the journal content (first 200 characters)
  String get summary {
    return content.length > 200 ? '${content.substring(0, 200)}...' : content;
  }

  /// Get time ago string for UI display
  String getTimeAgo(String language) {
    final daysAgo = DateTime.now().difference(date).inDays;

    if (language == 'pt_BR') {
      if (daysAgo == 0) return 'hoje';
      if (daysAgo == 1) return 'ontem';
      return '$daysAgo dias atrás';
    } else {
      if (daysAgo == 0) return 'today';
      if (daysAgo == 1) return 'yesterday';
      return '$daysAgo days ago';
    }
  }
}
