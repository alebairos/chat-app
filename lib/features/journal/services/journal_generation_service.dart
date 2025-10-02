import 'dart:convert';
import '../models/journal_entry_model.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/activity_model.dart';
import '../../../services/chat_storage_service.dart';
import '../../../services/activity_memory_service.dart';
import '../../../services/claude_service.dart';
import '../../../services/oracle_static_cache.dart';
import '../../../services/profile_service.dart';
import '../../../utils/logger.dart';
import 'journal_storage_service.dart';

/// Service for generating daily journal entries with I-There persona and context consistency
class JournalGenerationService {
  static final Logger _logger = Logger();

  /// Generate daily journal entries for both languages in a single LLM call
  static Future<List<JournalEntryModel>> generateDailyJournalBothLanguages(
      DateTime date) async {
    final startTime = DateTime.now();

    try {
      _logger.info(
          'JournalGeneration: Starting dual-language journal generation for ${date.toIso8601String()}');

      // 1. Aggregate day data
      final dayData = await _aggregateDayData(date);
      _logger.info(
          'JournalGeneration: Found ${dayData.messages.length} messages, ${dayData.activities.length} activities');

      // 2. Get user name and build simple prompt with actual data
      final userName = await ProfileService.getProfileName();
      if (userName.isEmpty) {
        throw Exception('User name is required for journal generation');
      }
      final prompt = _buildSimplePrompt(
          date, dayData.messages, dayData.activities, userName);

      // 3. Generate with Claude - returns JSON with both languages
      final response = await _generateWithClaude(prompt);
      final parsedResponse = _parseJournalResponse(response);

      // 4. Create entries for both languages
      final entries = <JournalEntryModel>[];
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final generationTime =
          DateTime.now().difference(startTime).inMilliseconds / 1000;

      for (final lang in ['pt_BR', 'en_US']) {
        final content = parsedResponse[lang] ?? _getFallbackContent(lang);
        final entry = JournalEntryModel.create(
          date: normalizedDate,
          language: lang,
          content: content,
          messageCount: dayData.messages.length,
          activityCount: dayData.activities.length,
          oracleVersion: "4.2",
          personaKey: "iThereWithOracle42",
          generationTimeSeconds: generationTime,
          promptVersion: "1.0",
        );

        await JournalStorageService.saveJournalEntry(entry);
        entries.add(entry);
        _logger.info('JournalGeneration: Saved $lang journal entry');
      }

      _logger.info(
          'JournalGeneration: Successfully generated both language entries (${generationTime.toStringAsFixed(2)}s)');
      return entries;
    } catch (e) {
      _logger.error('JournalGeneration: Failed to generate journal: $e');
      rethrow;
    }
  }

  /// Get day data for UI summary generation (avoid duplication)
  static Future<DayData> getDayDataForSummary(DateTime date) async {
    return await _aggregateDayData(date);
  }

  /// Aggregate all data for the day
  static Future<DayData> _aggregateDayData(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      // Get messages and activities for the day
      final chatStorage = ChatStorageService();
      final messages =
          await chatStorage.getMessagesForDate(startOfDay, endOfDay);
      final activities = await ActivityMemoryService.getActivitiesForDate(
          startOfDay, endOfDay);

      _logger.debug(
          'JournalGeneration: Aggregated ${messages.length} messages, ${activities.length} activities');

      return DayData(
        date: date,
        messages: messages,
        activities: activities,
        oracleContext: OracleStaticCache.getCompactOracleForLLM(),
        personaConfig: null, // TODO: Add persona config if needed
      );
    } catch (e) {
      _logger.error('JournalGeneration: Failed to aggregate day data: $e');
      rethrow;
    }
  }

  /// Build simple prompt with actual data
  static String _buildSimplePrompt(
      DateTime date,
      List<ChatMessageModel> messages,
      List<ActivityModel> activities,
      String userName) {
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final name = userName; // No fallback - userName must be provided

    // Build actual message content
    final messageContent = messages.isEmpty
        ? 'No messages today'
        : messages.map((m) => '- ${m.type.name}: ${m.text}').join('\n');

    // Build actual activity content
    final activityContent = activities.isEmpty
        ? 'No activities today'
        : activities
            .map((a) => '- ${a.activityName} (${a.dimension})')
            .join('\n');

    return '''You are I-There speaking directly to $name about their day. Generate TWO versions of the same journal entry - one in Portuguese (pt_BR) and one in English (en_US). Use the actual data provided below. Maximum 3 paragraphs each. Be conversational and direct. Use normal capitalization (not all lowercase).

DATE: $dateStr

ACTUAL MESSAGES (${messages.length} total):
$messageContent

ACTUAL ACTIVITIES (${activities.length} total):
$activityContent

CRITICAL: Return your response in this EXACT JSON format with proper escaping:
{
  "pt_BR": "$name, você teve um ótimo dia hoje. [Paragraph 1]\\n\\n[Paragraph 2]\\n\\n[Paragraph 3]",
  "en_US": "$name, you had a great day today. [Paragraph 1]\\n\\n[Paragraph 2]\\n\\n[Paragraph 3]"
}

IMPORTANT JSON RULES:
- Use \\n\\n for paragraph breaks (double backslash)
- NO literal newlines inside the JSON strings
- Keep each language entry as ONE continuous string
- Escape any quotes with \\"''';
  }

  /// Parse the JSON response from Claude
  static Map<String, String> _parseJournalResponse(String response) {
    try {
      _logger.debug(
          'JournalGeneration: Raw Claude response: ${response.substring(0, response.length > 500 ? 500 : response.length)}...');

      // Try to extract JSON from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd == 0) {
        _logger.error('JournalGeneration: No JSON braces found in response');
        throw Exception('No JSON found in response');
      }

      final jsonStr = response.substring(jsonStart, jsonEnd);
      _logger.debug('JournalGeneration: Extracted JSON: $jsonStr');

      final parsed = json.decode(jsonStr) as Map<String, dynamic>;

      // Convert escaped newlines to actual newlines for display
      final ptContent =
          parsed['pt_BR']?.toString().replaceAll('\\n', '\n') ?? '';
      final enContent =
          parsed['en_US']?.toString().replaceAll('\\n', '\n') ?? '';

      final result = {
        'pt_BR': ptContent,
        'en_US': enContent,
      };

      _logger.info(
          'JournalGeneration: Successfully parsed JSON with ${result['pt_BR']?.length ?? 0} PT chars, ${result['en_US']?.length ?? 0} EN chars');
      return result;
    } catch (e) {
      _logger.error('JournalGeneration: Failed to parse JSON response: $e');
      _logger.error('JournalGeneration: Full response was: $response');
      return {
        'pt_BR': _getFallbackContent('pt_BR'),
        'en_US': _getFallbackContent('en_US'),
      };
    }
  }

  /// Get fallback content when parsing fails
  static String _getFallbackContent(String language) {
    return language == 'pt_BR'
        ? 'Alexandre, hoje tive algumas dificuldades técnicas para processar completamente suas atividades, mas ainda assim queria deixar uma nota. Mesmo quando não consigo analisar tudo perfeitamente, sei que você continua crescendo e evoluindo.'
        : 'Alexandre, I had some technical difficulties processing your activities completely today, but I still wanted to leave a note. Even when I can\'t analyze everything perfectly, I know you continue to grow and evolve.';
  }

  /// Generate journal content using Claude with I-There persona
  static Future<String> _generateWithClaude(String prompt) async {
    try {
      final claudeService = ClaudeService();
      final response = await claudeService.sendMessage(prompt);

      if (response.isEmpty) {
        throw Exception('Claude returned empty response');
      }

      // Check if Claude is rate limiting
      if (response.contains('processing a lot of requests') ||
          response.contains('get back to you') ||
          response.contains('moment')) {
        _logger.warning(
            'JournalGeneration: Claude is rate limiting, retrying in 5 seconds...');
        await Future.delayed(Duration(seconds: 5));

        // Retry once
        final retryResponse = await claudeService.sendMessage(prompt);
        if (retryResponse.isEmpty) {
          throw Exception('Claude returned empty response on retry');
        }

        _logger.debug(
            'JournalGeneration: Claude retry generated ${retryResponse.length} characters');
        return retryResponse;
      }

      _logger.debug(
          'JournalGeneration: Claude generated ${response.length} characters');
      return response;
    } catch (e) {
      _logger.error('JournalGeneration: Claude generation failed: $e');
      rethrow;
    }
  }

  /// Generate a detailed summary for the summary tab
  static Map<String, dynamic> generateDailySummary(DateTime date,
      List<ChatMessageModel> messages, List<ActivityModel> activities) {
    try {
      // Group activities by dimension
      final dimensionGroups = <String, List<ActivityModel>>{};
      for (final activity in activities) {
        final dimension = activity.dimension;
        dimensionGroups[dimension] = (dimensionGroups[dimension] ?? [])
          ..add(activity);
      }

      // Find most active time of day
      String mostActiveTimeOfDay = 'morning';
      if (activities.isNotEmpty) {
        final hourCounts = <int, int>{};
        for (final activity in activities) {
          final hour = activity.completedAt.hour;
          hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
        }

        final mostActiveHour =
            hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        if (mostActiveHour >= 6 && mostActiveHour < 12) {
          mostActiveTimeOfDay = 'morning';
        } else if (mostActiveHour >= 12 && mostActiveHour < 18) {
          mostActiveTimeOfDay = 'afternoon';
        } else {
          mostActiveTimeOfDay = 'evening';
        }
      }

      return {
        'date': date.toIso8601String(),
        'totalMessages': messages.length,
        'totalActivities': activities.length,
        'mostActiveTimeOfDay': mostActiveTimeOfDay,
        'topActivityDimensions': dimensionGroups.keys.take(3).toList(),
        'primaryPersonaUsed': 'I-There 4.2',
        'activityBreakdown':
            dimensionGroups.map((key, value) => MapEntry(key, value.length)),
      };
    } catch (e) {
      _logger.error('JournalGeneration: Failed to generate daily summary: $e');
      return {
        'date': date.toIso8601String(),
        'totalMessages': 0,
        'totalActivities': 0,
        'mostActiveTimeOfDay': 'morning',
        'topActivityDimensions': <String>[],
        'primaryPersonaUsed': 'I-There 4.2',
        'activityBreakdown': <String, int>{},
      };
    }
  }
}

/// Data structure for aggregated day information
class DayData {
  final DateTime date;
  final List<ChatMessageModel> messages;
  final List<ActivityModel> activities;
  final String oracleContext;
  final Map<String, dynamic>? personaConfig;

  DayData({
    required this.date,
    required this.messages,
    required this.activities,
    required this.oracleContext,
    this.personaConfig,
  });
}
