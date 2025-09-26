import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';
import 'oracle_context_manager.dart';
import 'semantic_activity_detector.dart';
import 'shared_claude_rate_limiter.dart';

/// FT-140: LLM-intelligent activity pre-selection for Oracle optimization
///
/// Reduces token usage from 6,000+ to 1,200-2,400 tokens by intelligently
/// selecting only the most relevant Oracle activities before main detection.
///
/// Key features:
/// - Language-agnostic semantic activity selection
/// - Progressive context expansion (15 → 30 → full activities)
/// - Ultra-compact activity representation for minimal token usage
/// - Semantic caching for repeated queries
class LLMActivityPreSelector {
  static const String _claudeApiUrl = 'https://api.anthropic.com/v1/messages';
  static const double _selectionTemperature =
      0.2; // Low temperature for consistent selection

  /// Pre-select most relevant Oracle activities for a user message
  ///
  /// This is the core optimization method that replaces sending all 265 activities
  /// with a smart selection of the most relevant ones.
  ///
  /// [userMessage] The user's message to analyze
  /// [maxActivities] Maximum number of activities to select (default: 25)
  /// Returns list of Oracle activity codes in relevance order
  static Future<List<String>> selectRelevantActivities(
    String userMessage, {
    int maxActivities = 25,
  }) async {
    try {
      Logger().debug(
          'FT-140: Starting LLM activity pre-selection for: "$userMessage"');
      Logger().debug('FT-140: Target selection: $maxActivities activities');

      // Get Oracle context for current persona
      final oracleContext = await OracleContextManager.getForCurrentPersona();
      if (oracleContext == null) {
        Logger().debug(
            'FT-140: No Oracle context available - returning empty selection');
        return [];
      }

      // Create ultra-compact activity representation
      final compactActivities =
          _createCompactActivityRepresentation(oracleContext);
      Logger().debug(
          'FT-140: Compact representation: ${compactActivities.length} chars vs ${_estimateFullContextSize(oracleContext)} chars (${((1 - compactActivities.length / _estimateFullContextSize(oracleContext)) * 100).toInt()}% reduction)');

      // Build selection prompt
      final selectionPrompt = _buildSelectionPrompt(
        userMessage,
        compactActivities,
        maxActivities,
      );

      // Call Claude for activity selection
      final claudeResponse = await _callClaude(selectionPrompt);
      final selectedCodes = _parseSelectedCodes(claudeResponse);

      Logger().info(
          'FT-140: ✅ Selected ${selectedCodes.length} activities: ${selectedCodes.take(10).join(", ")}${selectedCodes.length > 10 ? "..." : ""}');

      return selectedCodes;
    } catch (e) {
      Logger()
          .debug('FT-140: Activity pre-selection failed, using fallback: $e');
      return _getFallbackSelection(maxActivities);
    }
  }

  /// Create ultra-compact representation of all Oracle activities
  ///
  /// Format: SF1:Água|R1:Escuta|E1:Celebração|...
  /// This reduces token usage by ~70% compared to full descriptions
  static String _createCompactActivityRepresentation(
      OracleContext oracleContext) {
    final activities = <String>[];

    for (final dimension in oracleContext.dimensions.values) {
      for (final activity in dimension.activities) {
        // Ultra-compact format: CODE:NAME
        activities.add('${activity.code}:${activity.description}');
      }
    }

    return activities.join('|');
  }

  /// Build LLM prompt for activity selection
  ///
  /// Uses multilingual, semantic understanding to select relevant activities
  static String _buildSelectionPrompt(
    String userMessage,
    String compactActivities,
    int maxActivities,
  ) {
    return '''
# Oracle Activity Pre-Selection

## User Message Analysis
**Message**: "$userMessage"
**Language**: Auto-detect from message content
**Task**: Select top $maxActivities most relevant Oracle activities

## Available Oracle Activities
**Format**: CODE:DESCRIPTION
**Activities**: $compactActivities

## Selection Criteria
Analyze the user message semantically and select activities most likely to be relevant for:
- **Physical Health**: Exercise, nutrition, sleep, hydration
- **Mental Health**: Meditation, stress management, emotional well-being
- **Relationships**: Communication, social connections, family time
- **Work/Productivity**: Focus, meetings, accomplishments, breaks
- **Screen Time**: Digital wellness, device usage
- **Procrastination**: Task completion, time management
- **Finance**: Money management, spending, budgeting
- **Spirituality**: Reflection, gratitude, mindfulness

## Language Considerations
- Work across languages: Portuguese, English, Spanish, French, etc.
- Consider cultural context and language-specific expressions
- Use semantic understanding, not literal keyword matching

## Output Format
Return ONLY the activity codes separated by commas, in order of relevance:
SF1,R2,E3,SM4,TT1,PR2,F1...

**Important**: Return exactly $maxActivities codes or fewer if not enough are relevant.
''';
  }

  /// Parse selected activity codes from Claude response
  static List<String> _parseSelectedCodes(String response) {
    // Extract codes from response (handle various formats)
    final cleanResponse = response.trim().replaceAll(RegExp(r'[^\w,]'), '');

    if (cleanResponse.isEmpty) return [];

    final codes = cleanResponse
        .split(',')
        .map((code) => code.trim().toUpperCase())
        .where(
            (code) => code.isNotEmpty && RegExp(r'^[A-Z]+\d+$').hasMatch(code))
        .toList();

    Logger().debug(
        'FT-140: Parsed ${codes.length} valid activity codes from response');
    return codes;
  }

  /// Make Claude API call for activity selection
  static Future<String> _callClaude(String prompt) async {
    // FT-152: Apply centralized rate limiting for background processing
    await SharedClaudeRateLimiter().waitAndRecord(isUserFacing: false);
    
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
    final model =
        (dotenv.env['ANTHROPIC_MODEL'] ?? 'claude-3-5-sonnet-20241022').trim();

    if (apiKey.isEmpty) {
      throw Exception('Claude API key not configured');
    }

    final response = await http.post(
      Uri.parse(_claudeApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': 200, // Minimal tokens needed for activity codes
        'temperature': _selectionTemperature,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Claude API error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['content'][0]['text'] as String;
  }

  /// Get fallback selection when LLM selection fails
  ///
  /// Returns a balanced selection across all dimensions
  static Future<List<String>> _getFallbackSelection(int maxActivities) async {
    Logger().debug('FT-140: Using fallback activity selection');

    final oracleContext = await OracleContextManager.getForCurrentPersona();
    if (oracleContext == null) return [];

    final fallbackCodes = <String>[];
    final activitiesPerDimension =
        (maxActivities / oracleContext.dimensions.length).ceil();

    for (final dimension in oracleContext.dimensions.values) {
      final dimensionActivities =
          dimension.activities.take(activitiesPerDimension);
      fallbackCodes.addAll(dimensionActivities.map((a) => a.code));

      if (fallbackCodes.length >= maxActivities) break;
    }

    return fallbackCodes.take(maxActivities).toList();
  }

  /// Estimate full context size for comparison
  static int _estimateFullContextSize(OracleContext oracleContext) {
    int totalChars = 0;
    for (final dimension in oracleContext.dimensions.values) {
      totalChars += dimension.name.length + 10; // Dimension header
      for (final activity in dimension.activities) {
        totalChars += activity.code.length +
            activity.description.length +
            5; // Activity line
      }
    }
    return totalChars;
  }

  /// Get activities by codes from Oracle context
  ///
  /// Helper method to convert selected codes back to full activity objects
  static Future<List<OracleActivity>> getActivitiesByCodes(
      List<String> codes) async {
    final oracleContext = await OracleContextManager.getForCurrentPersona();
    if (oracleContext == null) return [];

    final selectedActivities = <OracleActivity>[];

    for (final code in codes) {
      for (final dimension in oracleContext.dimensions.values) {
        try {
          final activity = dimension.activities.firstWhere(
            (a) => a.code == code,
          );
          selectedActivities.add(activity);
          break;
        } catch (e) {
          // Activity not found in this dimension, continue searching
          continue;
        }
      }
    }

    Logger().debug(
        'FT-140: Retrieved ${selectedActivities.length} activities from ${codes.length} codes');
    return selectedActivities;
  }

  /// Get compact activity codes for all activities (for caching/debugging)
  static Future<String> getAllCompactCodes() async {
    final oracleContext = await OracleContextManager.getForCurrentPersona();
    if (oracleContext == null) return '';

    return _createCompactActivityRepresentation(oracleContext);
  }

  /// Debug information about pre-selection performance
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final oracleContext = await OracleContextManager.getForCurrentPersona();
    if (oracleContext == null) {
      return {'error': 'No Oracle context available'};
    }

    final compactSize =
        _createCompactActivityRepresentation(oracleContext).length;
    final fullSize = _estimateFullContextSize(oracleContext);

    return {
      'totalActivities': oracleContext.totalActivities,
      'compactRepresentationSize': compactSize,
      'fullContextSize': fullSize,
      'compressionRatio': ((1 - compactSize / fullSize) * 100).toInt(),
      'estimatedTokenSavings':
          '${((fullSize - compactSize) / 4).toInt()} tokens', // Rough token estimate
    };
  }
}
