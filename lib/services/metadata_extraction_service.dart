import 'dart:convert';
import '../config/metadata_config.dart';
import '../models/activity_model.dart';
import '../services/claude_service.dart';
import '../utils/logger.dart';

/// FT-149: Focused Metadata Extraction Service
/// 
/// Provides intelligent metadata extraction using existing ClaudeService
/// infrastructure for optimal accuracy and minimal cost.
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

      _logger.debug('FT-149: Starting focused metadata extraction for: $oracleActivityName');

      // Build focused metadata extraction prompt
      final prompt = _buildFocusedMetadataPrompt(
        userMessage: userMessage,
        activityCode: detectedActivity.activityCode ?? 'UNKNOWN',
        activityName: oracleActivityName,
      );

      // Use existing ClaudeService infrastructure (optimal accuracy)
      final claudeService = ClaudeService();
      await claudeService.initialize();
      final response = await claudeService.callClaudeWithPrompt(prompt);
      
      // Parse metadata from focused response
      final metadata = _parseMetadataResponse(response);
      
      if (metadata != null && metadata.isNotEmpty) {
        _logger.info('FT-149: ✅ Extracted ${metadata.keys.length} metadata fields');
        return metadata;
      } else {
        _logger.debug('FT-149: No metadata extracted from response');
        return null;
      }
    } catch (e) {
      _logger.warning('FT-149: Metadata extraction failed gracefully: $e');
      return null; // Graceful degradation
    }
  }

  /// Build focused metadata extraction prompt (50-100 tokens)
  static String _buildFocusedMetadataPrompt({
    required String userMessage,
    required String activityCode,
    required String activityName,
  }) {
    return '''
# METADATA EXTRACTION (FT-149)

## Context
**User Message**: "$userMessage"
**Detected Activity**: $activityName ($activityCode)

## Task
Extract relevant metadata from the user's message for this specific activity.

### Focus Areas by Activity Type:
- **SF1 (Water)**: Volume (ml, L, cups, glasses), temperature, container type
- **SF12 (Exercise)**: Duration, intensity, type, location, equipment
- **TG8 (Work)**: Duration, task type, productivity level, tools used
- **SM1 (Meditation)**: Duration, technique, location, guidance type

### Portuguese Colloquialisms:
- "copinho" → ~150ml, "copão" → ~300ml
- "garrafinha" → ~500ml, "garrafa" → ~1L
- "corridinha" → light jog, "voltinha" → short walk

## Output (JSON only):
Return ONLY a JSON object. If no metadata found, return {}.

Examples:
- "bebi 300ml de água" → {"quantity": "300", "unit": "ml", "substance": "water"}
- "fiz 20 flexões" → {"count": "20", "exercise_type": "push-ups"}
- "corri 2km no parque" → {"distance": "2", "unit": "km", "location": "park"}

JSON:''';
  }

  /// Parse metadata from Claude response
  static Map<String, dynamic>? _parseMetadataResponse(String response) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');
      
      if (jsonStart == -1 || jsonEnd == -1) return null;
      
      final jsonStr = response.substring(jsonStart, jsonEnd + 1);
      final parsed = json.decode(jsonStr);
      
      return parsed is Map<String, dynamic> && parsed.isNotEmpty ? parsed : null;
    } catch (e) {
      _logger.debug('FT-149: Failed to parse metadata response: $e');
      return null;
    }
  }
}
