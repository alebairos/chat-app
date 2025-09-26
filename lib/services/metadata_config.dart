import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// FT-149: Simple metadata configuration loader
class MetadataConfig {
  static bool? _enabled;
  static bool? _aiExtraction;

  /// Check if metadata functionality is enabled
  static Future<bool> isEnabled() async {
    if (_enabled == null) {
      await _loadConfig();
    }
    return _enabled ?? false;
  }

  /// Check if AI extraction is enabled
  static Future<bool> isAiExtractionEnabled() async {
    if (_aiExtraction == null) {
      await _loadConfig();
    }
    return _aiExtraction ?? false;
  }

  /// Load configuration from assets
  static Future<void> _loadConfig() async {
    try {
      final String configString = await rootBundle.loadString(
        'assets/config/metadata_config.json',
      );
      final Map<String, dynamic> config = json.decode(configString);

      _enabled = config['enabled'] as bool? ?? false;
      _aiExtraction = config['ai_extraction'] as bool? ?? false;
    } catch (e) {
      // Default to disabled if config fails to load
      _enabled = false;
      _aiExtraction = false;
    }
  }

  /// Reset cache (for testing)
  static void reset() {
    _enabled = null;
    _aiExtraction = null;
  }
}
