import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

/// Core FT-064 implementation: Two-pass Claude semantic activity detection
///
/// Replaces fragile regex with Claude's semantic understanding for:
/// - 40% → 90%+ detection rate improvement
/// - Oracle-only → All personas support
/// - Portuguese-only → Multilingual support
/// - Brittle failure → Graceful degradation
class SemanticActivityDetector {
  static const String _claudeApiUrl = 'https://api.anthropic.com/v1/messages';
  static const double _detectionTemperature =
      0.1; // Low temperature for consistent detection

  /// Main entry point: Semantic activity detection with time context
  ///
  /// FT-086: Only analyzes user messages to prevent false positives from assistant responses
  /// Returns detected activities or empty list on failure (graceful degradation)
  static Future<List<ActivityDetection>> analyzeWithTimeContext({
    required String userMessage,
    required OracleContext oracleContext,
    required Map<String, dynamic> timeContext,
  }) async {
    try {
      Logger().debug('FT-064: Starting semantic activity detection');
      Logger().debug(
          'FT-086: Analyzing USER message only (assistant responses ignored)');

      final prompt = _buildDetectionPrompt(
        userMessage: userMessage,
        oracleContext: oracleContext,
        timeContext: timeContext,
      );

      final claudeAnalysis = await _callClaude(prompt);
      final activities = _parseDetectionResults(claudeAnalysis);

      Logger().info('FT-064: Detected ${activities.length} activities');
      return activities;
    } catch (e) {
      Logger().debug('FT-064: Semantic detection failed silently: $e');
      return []; // Graceful degradation - never break conversation flow
    }
  }

  /// Build intent-first detection prompt with enhanced semantic understanding
  /// FT-091: Intent classification before activity detection to eliminate false positives
  static String _buildDetectionPrompt({
    required String userMessage,
    required OracleContext oracleContext,
    required Map<String, dynamic> timeContext,
  }) {
    return '''
# SEMANTIC ACTIVITY DETECTION

## Oracle Activities Available
${_formatOracleActivities(oracleContext)}

## User Message Analysis
**Time Context**: ${timeContext['readableTime'] ?? 'Unknown'}
**User Message**: "$userMessage"

## Step 1: Intent Classification (CRITICAL FIRST STEP)
FT-091: Determine the user's primary intent before any activity detection.

**REPORTING**: User is telling you about activities they completed
- Examples: "acabei de beber água", "fiz exercício", "terminei o pomodoro"
- Indicators: Past tense completion statements, direct activity claims
- Action: Proceed to Step 2 for activity detection

**ASKING**: User is requesting information about past activities
- Examples: "o que fiz hoje?", "além de beber água?", "what did I do?"
- Indicators: Questions, requests for data, information seeking
- Action: Return {"detected_activities": []} - NO DETECTION

**DISCUSSING**: User is talking about activities in general context
- Examples: "gosto de beber água", "quero fazer exercício", "planning to work out"
- Indicators: Preferences, future plans, general discussion
- Action: Return {"detected_activities": []} - NO DETECTION

## Step 2: Activity Detection (ONLY for REPORTING intent)
If intent is REPORTING, detect completed activities using semantic understanding:
- MATCH semantically: "malhar" = "exercitar" = "treinar" = "workout"
- EXTRACT duration when mentioned
- BE CONFIDENT: only return activities you're certain about
- Focus on past completions with high confidence

## Output Format (JSON only)
{
  "detected_activities": [
    {
      "oracle_code": "T8",
      "activity_name": "Realizar sessão de trabalho focado (pomodoro)",
      "user_description": "2 pomodoros feitos",
      "duration_minutes": null,
      "confidence": "high",
      "reasoning": "User explicitly mentioned completing pomodoros"
    },
    {
      "oracle_code": "SF10",
      "activity_name": "Comer proteína nas refeições",
      "user_description": "almocei com proteína",
      "duration_minutes": null,
      "confidence": "high", 
      "reasoning": "User mentioned eating protein at lunch"
    }
  ]
}

## CRITICAL: Use EXACT Oracle codes from the activities list above!
- For pomodoro/focus work: Use "T8" (NOT "TG8" or "TG")
- For eating protein: Use "SF10" (NOT "SF1" or "SF") 
- For meditation: Use "SM1" (NOT "SM" or "SM01")
- For water: Use "SF1" (NOT "SF")
- NEVER add dimension prefix to activity codes!
- NEVER use dimension codes alone (TG, SF, SM, R, E)!

Return empty array if no completed activities detected.
''';
  }

  /// Format Oracle activities for prompt (simplified)
  static String _formatOracleActivities(OracleContext oracleContext) {
    final buffer = StringBuffer();

    for (final dimension in oracleContext.dimensions.values) {
      buffer.writeln('**${dimension.name} (${dimension.code})**:');

      for (final activity in dimension.activities) {
        buffer.writeln('- ${activity.code}: ${activity.description}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Make Claude API call with minimal configuration
  static Future<String> _callClaude(String prompt) async {
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
        'max_tokens': 1000,
        'temperature': _detectionTemperature,
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

  /// Parse Claude's JSON response with graceful error handling
  static List<ActivityDetection> _parseDetectionResults(String claudeResponse) {
    try {
      // Extract JSON from Claude's response (may have extra text)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(claudeResponse);
      if (jsonMatch == null) {
        Logger().debug('FT-064: No JSON found in Claude response');
        return [];
      }

      final jsonStr = jsonMatch.group(0)!;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final activitiesJson =
          data['detected_activities'] as List<dynamic>? ?? [];

      return activitiesJson.map((activityJson) {
        final activity = activityJson as Map<String, dynamic>;
        return ActivityDetection(
          oracleCode: activity['oracle_code'] as String,
          activityName: activity['activity_name'] as String,
          userDescription: activity['user_description'] as String,
          durationMinutes: activity['duration_minutes'] as int?,
          confidence: _parseConfidence(activity['confidence'] as String?),
          reasoning: activity['reasoning'] as String? ?? '',
          timestamp: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      Logger().debug('FT-064: Failed to parse detection results: $e');
      return []; // Graceful degradation
    }
  }

  static ConfidenceLevel _parseConfidence(String? confidence) {
    switch (confidence?.toLowerCase()) {
      case 'high':
        return ConfidenceLevel.high;
      case 'medium':
        return ConfidenceLevel.medium;
      case 'low':
        return ConfidenceLevel.low;
      default:
        return ConfidenceLevel.medium;
    }
  }
}

/// Activity detection result with confidence scoring
class ActivityDetection {
  final String oracleCode;
  final String activityName;
  final String userDescription;
  final int? durationMinutes;
  final ConfidenceLevel confidence;
  final String reasoning;
  final DateTime timestamp;

  ActivityDetection({
    required this.oracleCode,
    required this.activityName,
    required this.userDescription,
    this.durationMinutes,
    required this.confidence,
    required this.reasoning,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'ActivityDetection(code: $oracleCode, confidence: $confidence, description: $userDescription)';
  }
}

enum ConfidenceLevel { high, medium, low }

/// Oracle context for semantic detection
class OracleContext {
  final Map<String, OracleDimension> dimensions;
  final int totalActivities;

  OracleContext({
    required this.dimensions,
    required this.totalActivities,
  });
}

class OracleDimension {
  final String code;
  final String name;
  final List<OracleActivity> activities;

  OracleDimension({
    required this.code,
    required this.name,
    required this.activities,
  });
}

class OracleActivity {
  final String code;
  final String description;
  final String dimension;

  OracleActivity({
    required this.code,
    required this.description,
    required this.dimension,
  });
}
