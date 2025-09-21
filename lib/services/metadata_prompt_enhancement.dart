import '../config/metadata_config.dart';
import '../utils/logger.dart';

/// FT-149.6: Metadata Prompt Enhancement Library
///
/// Provides metadata extraction instructions as a separate, toggleable library
/// that can be easily integrated into existing Oracle detection prompts.
///
/// Key Design Principles:
/// - Zero impact on core two-pass loop when disabled
/// - Modular and easily removable
/// - Feature flag controlled
/// - No hardcoded strings - all instructions in prompts
class MetadataPromptEnhancement {
  static final Logger _logger = Logger();

  /// Check if metadata enhancement should be applied
  static bool get isEnabled => MetadataConfig.isFullIntelligence;

  /// Get metadata extraction instructions for Oracle prompt integration
  ///
  /// Returns empty string if feature is disabled, ensuring zero impact
  static String getMetadataInstructions() {
    if (!isEnabled) {
      _logger.debug(
          'FT-149.6: Metadata enhancement disabled - returning empty instructions');
      return '';
    }

    _logger.debug(
        'FT-149.6: Adding metadata enhancement instructions to Oracle prompt');
    return _buildUniversalMetadataInstructions();
  }

  /// Build universal metadata extraction instructions
  ///
  /// These instructions are added to the existing Oracle detection prompt
  /// to enhance activity detection with rich contextual metadata.
  static String _buildUniversalMetadataInstructions() {
    return '''

## METADATA ENHANCEMENT (FT-149.6)
For each detected activity, extract rich contextual metadata using the Universal Framework.

### Universal Extraction Framework
Apply these high-level principles to extract meaningful metadata:

#### Quantitative Dimensions
Extract any measurable aspects mentioned or reasonably inferable:
- **Scale/Magnitude**: How much, how many, how big, how far, how heavy
- **Time**: Duration, frequency, timing, sequence, intervals
- **Performance**: Speed, intensity, efficiency, accuracy, completion rate

#### Qualitative Dimensions  
Capture descriptive and subjective information:
- **Experience Quality**: How it felt, perceived difficulty, satisfaction level
- **Method/Approach**: Technique, style, tools, process used
- **Conditions**: Environment, circumstances, context, constraints

#### Relational Dimensions
Identify connections and patterns:
- **Comparison**: Better/worse than usual, first time, milestone, trend
- **Causation**: What triggered it, what influenced it, what resulted
- **Social**: Alone, with others, influenced by, competing with

#### Behavioral Dimensions
Understand the human element:
- **Motivation**: Why this happened, internal/external drivers
- **State**: Physical/mental/emotional condition before/during/after  
- **Intention**: Planned vs spontaneous, goal-oriented vs reactive

### Extraction Guidelines
1. **Think Human Patterns**: What would help understand this person's relationship with this activity?
2. **Be Universally Relevant**: Focus on dimensions that apply to any human behavior
3. **Preserve User Voice**: Keep subjective language that shows personal perspective
4. **Infer Intelligently**: Use context and cultural understanding
5. **Structure Meaningfully**: Organize information to reveal insights

### Enhanced Output Format
For each detected activity, include metadata field with clear, descriptive keys:

```json
{
  "detected_activities": [
    {
      "oracle_code": "SF13",
      "activity_name": "Fazer exercício cardio/aeróbico",
      "user_description": "corri 1km, descansei, corri 500m",
      "duration_minutes": null,
      "confidence": "high",
      "reasoning": "User explicitly described interval running",
      "metadata": {
        "quantitative": {
          "distance": {
            "total": 1500,
            "running": 1500,
            "walking": 0,
            "unit": "meters"
          },
          "duration": {
            "total_estimated": 15,
            "active_running": 12,
            "rest_periods": 3,
            "unit": "minutes"
          },
          "performance": {
            "pace": "moderate",
            "intervals": 2,
            "completion_rate": "100%"
          }
        },
        "qualitative": {
          "experience": {
            "intensity": "moderate",
            "difficulty": "manageable",
            "satisfaction": "high"
          },
          "method": {
            "type": "interval_training",
            "breathing": "nasal_breathing",
            "structure": "planned_intervals"
          },
          "conditions": {
            "environment": "outdoor",
            "weather": "suitable",
            "equipment": "minimal"
          }
        },
        "relational": {
          "comparison": {
            "vs_usual": "similar_intensity",
            "progression": "maintaining_routine"
          },
          "causation": {
            "trigger": "scheduled_workout",
            "motivation": "health_maintenance"
          }
        },
        "behavioral": {
          "motivation": {
            "internal": "health_commitment",
            "external": "routine_adherence"
          },
          "state": {
            "physical": "energetic",
            "mental": "focused",
            "emotional": "positive"
          },
          "intention": {
            "planning": "structured",
            "goal_oriented": true,
            "mindful_approach": true
          }
        }
      }
    }
  ]
}
```

**Important**: Use confidence indicators ("explicit", "inferred", "estimated") for metadata values.
Group related information logically and use descriptive keys that reveal insights.
''';
  }

  /// Log metadata enhancement status for debugging
  static void logStatus() {
    if (isEnabled) {
      _logger.info(
          'FT-149.6: ✅ Metadata enhancement ENABLED - Oracle prompts will include metadata instructions');
    } else {
      _logger.debug(
          'FT-149.6: ⚪ Metadata enhancement DISABLED - Oracle prompts unchanged');
    }
  }

  /// Get metadata parsing instructions for response processing
  ///
  /// Returns instructions for parsing enhanced Oracle responses that include metadata
  static String getParsingInstructions() {
    if (!isEnabled) return '';

    return '''
// FT-149.6: Parse metadata from enhanced Oracle response
if (activity.containsKey('metadata') && activity['metadata'] != null) {
  detectedActivity.metadata = json.encode(activity['metadata']);
  _logger.debug('FT-149.6: Extracted metadata for \${activity['activity_name']}');
}
''';
  }

  /// Validate that metadata structure follows Universal Framework
  ///
  /// Used for quality assurance and debugging
  static bool validateMetadataStructure(Map<String, dynamic> metadata) {
    if (!isEnabled) return true; // Skip validation when disabled

    final expectedDimensions = [
      'quantitative',
      'qualitative',
      'relational',
      'behavioral'
    ];
    final presentDimensions =
        metadata.keys.where((key) => expectedDimensions.contains(key)).toList();

    final isValid = presentDimensions.isNotEmpty;

    if (isValid) {
      _logger.debug(
          'FT-149.6: ✅ Metadata structure valid - dimensions: $presentDimensions');
    } else {
      _logger.warning(
          'FT-149.6: ⚠️ Metadata structure invalid - missing Universal Framework dimensions');
    }

    return isValid;
  }
}
