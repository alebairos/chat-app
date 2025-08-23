import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/logger.dart';
import '../config/character_config_manager.dart';
import 'semantic_activity_detector.dart';

/// FT-064: Dynamic Oracle context loading for any persona
///
/// Provides zero-configuration Oracle activity context:
/// - Automatically detects Oracle-compatible personas
/// - Loads correct Oracle JSON for active persona
/// - Caches Oracle context for performance
/// - Gracefully handles non-Oracle personas
class OracleContextManager {
  static final Map<String, OracleContext?> _cache = {};
  static CharacterConfigManager? _configManager;

  /// Get Oracle context for current active persona
  /// Returns null for non-Oracle personas (graceful degradation)
  static Future<OracleContext?> getForCurrentPersona() async {
    _configManager ??= CharacterConfigManager();
    final activePersona = _configManager!.activePersonaKey;
    return getForPersona(activePersona);
  }

  /// Get Oracle context for specific persona with caching
  static Future<OracleContext?> getForPersona(String personaKey) async {
    if (_cache.containsKey(personaKey)) {
      Logger().debug('FT-064: Using cached Oracle context for $personaKey');
      return _cache[personaKey];
    }

    Logger().debug('FT-064: Loading Oracle context for persona: $personaKey');

    try {
      _configManager ??= CharacterConfigManager();
      final oracleConfigPath = await _getOracleConfigPath(personaKey);

      if (oracleConfigPath == null) {
        Logger().debug('FT-064: No Oracle config for persona $personaKey');
        _cache[personaKey] = null;
        return null;
      }

      final oracleContext = await _loadOracleFromPath(oracleConfigPath);
      _cache[personaKey] = oracleContext;

      if (oracleContext != null) {
        Logger().info(
            'FT-064: ✅ Loaded Oracle context: ${oracleContext.totalActivities} activities, ${oracleContext.dimensions.length} dimensions');
      }

      return oracleContext;
    } catch (e) {
      Logger()
          .debug('FT-064: Failed to load Oracle context for $personaKey: $e');
      _cache[personaKey] = null;
      return null;
    }
  }

  /// Determine Oracle config path for persona (leverages existing FT-061/062 infrastructure)
  static Future<String?> _getOracleConfigPath(String personaKey) async {
    _configManager ??= CharacterConfigManager();

    // Load personas config directly (using same pattern as CharacterConfigManager)
    final config = await _loadPersonasConfig();
    final personas = config['personas'] as Map<String, dynamic>? ?? {};
    final personaConfig = personas[personaKey] as Map<String, dynamic>?;

    if (personaConfig?['oracleConfigPath'] != null) {
      final oracleMarkdownPath = personaConfig!['oracleConfigPath'] as String;
      // Convert markdown path to JSON path (FT-062 preprocessing)
      return oracleMarkdownPath.replaceAll('.md', '.json');
    }

    return null;
  }

  /// Load personas configuration (helper method)
  static Future<Map<String, dynamic>> _loadPersonasConfig() async {
    final jsonString =
        await rootBundle.loadString('assets/config/personas_config.json');
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Load Oracle context from JSON file (FT-062 preprocessed format)
  static Future<OracleContext?> _loadOracleFromPath(String jsonPath) async {
    try {
      Logger().debug('FT-064: Loading Oracle JSON from: $jsonPath');

      final jsonString = await rootBundle.loadString(jsonPath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final dimensions = <String, OracleDimension>{};
      int totalActivities = 0;

      // Parse dimensions from FT-062 JSON format
      final dimensionsJson =
          jsonData['dimensions'] as Map<String, dynamic>? ?? {};

      for (final entry in dimensionsJson.entries) {
        final dimensionCode = entry.key;
        final dimensionData = entry.value as Map<String, dynamic>;

        final activities = <OracleActivity>[];

        // Activities are now parsed separately from top-level 'activities' section
        // This section will be replaced below

        dimensions[dimensionCode] = OracleDimension(
          code: dimensionCode,
          name: dimensionData['name'] as String? ?? dimensionCode,
          activities: activities,
        );
      }

      // Parse activities from top-level 'activities' section and assign to dimensions
      final activitiesJson =
          jsonData['activities'] as Map<String, dynamic>? ?? {};

      for (final entry in activitiesJson.entries) {
        final activityCode = entry.key;
        final activityData = entry.value as Map<String, dynamic>;
        final dimensionCode = activityData['dimension'] as String;

        final activity = OracleActivity(
          code: activityCode,
          description: activityData['name'] as String,
          dimension: dimensionCode,
        );

        if (dimensions.containsKey(dimensionCode)) {
          dimensions[dimensionCode]!.activities.add(activity);
          totalActivities++;
        }
      }

      return OracleContext(
        dimensions: dimensions,
        totalActivities: totalActivities,
      );
    } catch (e) {
      Logger().debug('FT-064: Failed to load Oracle JSON from $jsonPath: $e');
      return null;
    }
  }

  /// Clear cache (useful for testing or persona switching)
  static void clearCache() {
    Logger().debug('FT-064: Clearing Oracle context cache');
    _cache.clear();
  }

  /// Check if current persona supports Oracle activities
  static Future<bool> isCurrentPersonaOracleCompatible() async {
    final context = await getForCurrentPersona();
    return context != null && context.totalActivities > 0;
  }

  /// Get activity by Oracle code for current persona
  static Future<OracleActivity?> getActivityByCode(String code) async {
    final context = await getForCurrentPersona();
    if (context == null) return null;

    for (final dimension in context.dimensions.values) {
      for (final activity in dimension.activities) {
        if (activity.code == code) {
          return activity;
        }
      }
    }

    return null;
  }

  /// Get all activities for a specific dimension
  static Future<List<OracleActivity>> getActivitiesForDimension(
      String dimensionCode) async {
    final context = await getForCurrentPersona();
    if (context == null) return [];

    final dimension = context.dimensions[dimensionCode];
    return dimension?.activities ?? [];
  }

  /// Debug info about loaded Oracle context
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final context = await getForCurrentPersona();
    _configManager ??= CharacterConfigManager();

    return {
      'activePersona': _configManager!.activePersonaKey,
      'oracleLoaded': context != null,
      'totalActivities': context?.totalActivities ?? 0,
      'dimensions': context?.dimensions.keys.toList() ?? [],
      'cacheSize': _cache.length,
      'cachedPersonas': _cache.keys.toList(),
    };
  }
}
