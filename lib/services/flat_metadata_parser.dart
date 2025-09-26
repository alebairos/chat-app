import 'package:ai_personas_app/utils/logger.dart';
import '../utils/utf8_fix.dart';

/// FT-149.12: Flat Key-Value Metadata Parser
///
/// Revolutionary approach: Parse flat key-value structure where hierarchy
/// is represented in key names (e.g., "quantitative_steps_value": 7000)
///
/// Benefits:
/// - Zero structure ambiguity
/// - Trivial parsing (just filter keys)
/// - LLM-proof (impossible to generate wrong structure)
/// - Lightning fast performance

class FlatMetadataParser {
  static final Logger _logger = Logger();

  /// Extract raw quantitative metadata fields for storage/processing
  static Map<String, dynamic> extractRawQuantitative(
      Map<String, dynamic> metadata) {
    _logger.debug(
        '🔍 [FT-149] extractRawQuantitative input keys: ${metadata.keys}');
    final flatMetadata = <String, dynamic>{};
    for (final entry in metadata.entries) {
      if (entry.key.startsWith('quantitative_')) {
        // Fix UTF-8 encoding issues in metadata values (especially units)
        dynamic value = entry.value;
        if (value is String) {
          value = UTF8Fix.fix(value);
          _logger.debug('🔍 [FT-149] UTF-8 fixed: ${entry.value} → $value');
        }
        flatMetadata[entry.key] = value;
        _logger.debug('🔍 [FT-149] Extracted: ${entry.key} = $value');
      }
    }
    _logger.debug('🔍 [FT-149] extractRawQuantitative result: $flatMetadata');
    return flatMetadata;
  }

  /// Extract quantitative measurements from flat key-value metadata
  static List<Map<String, String>> extractQuantitative(
      Map<String, dynamic> metadata) {
    _logger.debug('Flat parsing metadata keys: ${metadata.keys}');

    final measurements = <Map<String, String>>[];
    final processedTypes = <String>{};

    // Filter keys that start with "quantitative_" and end with "_value"
    final quantitativeValueKeys = metadata.keys
        .where(
            (key) => key.startsWith('quantitative_') && key.endsWith('_value'))
        .toList();

    _logger.debug(
        '🔍 [DEBUG] FT-149.12: Found quantitative value keys: $quantitativeValueKeys');

    for (final valueKey in quantitativeValueKeys) {
      final measurementType = _extractMeasurementType(valueKey);

      // Skip if already processed (avoid duplicates)
      if (processedTypes.contains(measurementType)) continue;
      processedTypes.add(measurementType);

      final value = metadata[valueKey];
      final unitKey = valueKey.replaceAll('_value', '_unit');
      final unit = metadata[unitKey] as String? ?? '';

      if (value != null) {
        final displayUnit =
            unit.isNotEmpty ? unit : _inferUnit(measurementType);
        measurements.add({
          'key': measurementType,
          'value': value.toString(),
          'unit': displayUnit,
          'display': '${_formatValue(value, measurementType)} $displayUnit',
          'icon': _getIcon(measurementType)
        });

        _logger.debug(
            '🔍 [DEBUG] FT-149.12: Extracted $measurementType: $value $displayUnit');
      }
    }

    return measurements;
  }

  /// Extract measurement type from flat key
  /// "quantitative_steps_value" -> "steps"
  /// "quantitative_distance_value" -> "distance"
  static String _extractMeasurementType(String key) {
    // Remove "quantitative_" prefix and "_value" suffix
    return key.replaceFirst('quantitative_', '').replaceFirst('_value', '');
  }

  /// Format value for display
  static String _formatValue(dynamic value, String type) {
    if (value is num) {
      switch (type) {
        case 'distance':
          return value >= 1000
              ? (value / 1000).toStringAsFixed(1)
              : value.toStringAsFixed(0);
        case 'duration':
          return value.toStringAsFixed(0);
        case 'weight':
        case 'volume':
        case 'steps':
        case 'reps':
        case 'sets':
        default:
          return value.toStringAsFixed(0);
      }
    }
    return value.toString();
  }

  /// Infer unit if not provided
  static String _inferUnit(String type) {
    switch (type) {
      case 'steps':
        return 'steps';
      case 'distance':
        return 'm';
      case 'volume':
        return 'ml';
      case 'weight':
        return 'kg';
      case 'duration':
        return 'min';
      case 'reps':
        return 'reps';
      case 'sets':
        return 'sets';
      case 'calories':
        return 'kcal';
      case 'heartrate':
        return 'bpm';
      default:
        return '';
    }
  }

  /// Get icon for measurement type
  static String _getIcon(String type) {
    switch (type) {
      case 'steps':
        return '👣';
      case 'distance':
        return '📏';
      case 'volume':
        return '💧';
      case 'weight':
        return '🏋️';
      case 'duration':
        return '⏱️';
      case 'reps':
        return '🔄';
      case 'sets':
        return '📊';
      case 'calories':
        return '🔥';
      case 'heartrate':
        return '❤️';
      default:
        return '📈';
    }
  }

  /// Check if metadata has any quantitative data (flat structure only)
  static bool hasQuantitativeData(Map<String, dynamic> metadata) {
    return metadata.keys.any(
        (key) => key.startsWith('quantitative_') && key.endsWith('_value'));
  }

  /// Get all quantitative measurement types present
  static List<String> getAvailableMeasurements(Map<String, dynamic> metadata) {
    return metadata.keys
        .where(
            (key) => key.startsWith('quantitative_') && key.endsWith('_value'))
        .map((key) => _extractMeasurementType(key))
        .toList();
  }
}
