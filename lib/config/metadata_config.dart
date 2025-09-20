import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// FT-149: Metadata Intelligence Configuration Manager
/// 
/// Manages feature flags for activity metadata intelligence with three states:
/// - Disabled: No metadata functionality
/// - Manual Only: User can add/edit metadata manually
/// - Full Intelligence: AI extracts metadata + user can edit
class MetadataConfig {
  static bool _enabled = false;
  static bool _aiExtraction = false;
  static bool _initialized = false;
  static final Logger _logger = Logger();

  /// Initialize metadata configuration from JSON file
  static Future<void> initialize() async {
    try {
      final String configString = await rootBundle.loadString(
        'assets/config/metadata_intelligence_config.json',
      );
      final Map<String, dynamic> config = json.decode(configString);

      _enabled = config['enabled'] as bool? ?? false;
      _aiExtraction = config['ai_extraction'] as bool? ?? false;
      _initialized = true;

      _logger.info('✅ FT-149: Metadata config loaded - enabled=$_enabled, ai=$_aiExtraction');
      _logger.info('FT-149: Metadata config state: ${_getStateName()}');
    } catch (e) {
      _logger.warning('FT-149: Failed to load metadata config, using defaults: $e');
      _enabled = false;
      _aiExtraction = false;
      _initialized = true;
    }
  }

  /// Get current state name for debugging
  static String _getStateName() {
    if (!_enabled) return 'disabled';
    if (!_aiExtraction) return 'manual_only';
    return 'full_intelligence';
  }

  /// Check if metadata functionality is completely disabled
  static bool get isDisabled => !_enabled;

  /// Check if only manual metadata editing is enabled (no AI extraction)
  static bool get isManualOnly => _enabled && !_aiExtraction;

  /// Check if full intelligence mode is enabled (AI extraction + manual editing)
  static bool get isFullIntelligence => _enabled && _aiExtraction;

  /// Check if AI extraction is enabled
  static bool get hasAiExtraction => _aiExtraction;

  /// Check if configuration is initialized
  static bool get isInitialized => _initialized;
}
