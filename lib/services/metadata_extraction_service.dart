import 'dart:convert';
import '../config/metadata_config.dart';
import '../models/activity_model.dart';
import '../services/lean_claude_connector.dart';
import '../utils/logger.dart';

/// FT-149: Focused Metadata Extraction Service
///
/// Provides intelligent metadata extraction using lean Claude connector
/// for optimal speed, accuracy, and minimal cost overhead.
class MetadataExtractionService {
  static final Logger _logger = Logger();

  /// Extract metadata for detected activity using focused post-processing
  static Future<Map<String, dynamic>?> extractMetadata({
    required String userMessage,
    required ActivityModel detectedActivity,
    required String oracleActivityName,
  }) async {
    try {
      // Feature flag check
      if (MetadataConfig.isDisabled || !MetadataConfig.isFullIntelligence) {
        return null;
      }

      _logger.debug(
          'FT-149: Starting focused metadata extraction for: $oracleActivityName');

      // Build focused metadata extraction prompt
      final prompt = _buildFocusedMetadataPrompt(
        userMessage: userMessage,
        activityCode: detectedActivity.activityCode ?? 'UNKNOWN',
        activityName: oracleActivityName,
      );

      // Use lean Claude connector (optimal speed + cost efficiency)
      final response = await LeanClaudeConnector.extractMetadata(
        prompt: prompt,
        maxTokens: 1000, // FT-149.5: Increased for complete JSON responses
      );

      // Parse metadata from focused response
      if (response == null) {
        _logger.debug('FT-149: Lean extraction returned null response');
        return null;
      }

      final metadata = _parseMetadataResponse(response);

      if (metadata != null && metadata.isNotEmpty) {
        _logger.info(
            'FT-149: ✅ Lean extraction: ${metadata.keys.length} metadata fields');
        return metadata;
      } else {
        _logger.debug('FT-149: Lean extraction returned no metadata');
        return null;
      }
    } catch (e) {
      _logger.warning('FT-149: Metadata extraction failed gracefully: $e');
      return null; // Graceful degradation
    }
  }

  /// Build universal metadata extraction prompt (FT-149.1)
  static String _buildFocusedMetadataPrompt({
    required String userMessage,
    required String activityCode,
    required String activityName,
  }) {
    return '''
You are extracting metadata to enrich human activity tracking. Your goal is to capture information that reveals patterns, progress, and engagement across any type of human behavior.

**User said**: "$userMessage"
**Activity**: $activityName

## Universal Extraction Framework

Apply these high-level principles to extract meaningful metadata:

### Quantitative Dimensions
Extract any measurable aspects mentioned or reasonably inferable:
- **Scale/Magnitude**: How much, how many, how big, how far, how heavy
- **Time**: Duration, frequency, timing, sequence, intervals
- **Performance**: Speed, intensity, efficiency, accuracy, completion rate

### Qualitative Dimensions  
Capture descriptive and subjective information:
- **Experience Quality**: How it felt, perceived difficulty, satisfaction level
- **Method/Approach**: Technique, style, tools, process used
- **Conditions**: Environment, circumstances, context, constraints

### Relational Dimensions
Identify connections and patterns:
- **Comparison**: Better/worse than usual, first time, milestone, trend
- **Causation**: What triggered it, what influenced it, what resulted
- **Social**: Alone, with others, influenced by, competing with

### Behavioral Dimensions
Understand the human element:
- **Motivation**: Why this happened, internal/external drivers
- **State**: Physical/mental/emotional condition before/during/after  
- **Intention**: Planned vs spontaneous, goal-oriented vs reactive

## Extraction Guidelines

1. **Think Human Patterns**: What would help understand this person's relationship with this activity?
2. **Be Universally Relevant**: Focus on dimensions that apply to any human behavior
3. **Preserve User Voice**: Keep subjective language that shows personal perspective
4. **Infer Intelligently**: Use context and cultural understanding
5. **Structure Meaningfully**: Organize information to reveal insights

## Output Format
Return JSON with clear, descriptive keys. Group related information logically.
Use confidence indicators for inferences: "explicit", "inferred", "estimated"

JSON:''';
  }

  /// Parse metadata from Claude response
  static Map<String, dynamic>? _parseMetadataResponse(String response) {
    try {
      // First, try to find complete JSON blocks
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1) {
        _logger.debug('FT-149: No JSON braces found in response');
        return null;
      }

      final jsonStr = response.substring(jsonStart, jsonEnd + 1);

      // FT-149.4: Trust Dart's JSON parser - no custom validation needed
      final parsed = json.decode(jsonStr);

      return parsed is Map<String, dynamic> && parsed.isNotEmpty
          ? parsed
          : null;
    } catch (e) {
      _logger.debug('FT-149: Failed to parse metadata response: $e');
      _logger.debug(
          'FT-149: Response preview: ${response.length > 200 ? response.substring(0, 200) + "..." : response}');
      return null;
    }
  }
}
