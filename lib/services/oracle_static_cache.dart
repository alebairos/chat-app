import '../utils/logger.dart';
import 'oracle_context_manager.dart';
import 'semantic_activity_detector.dart';

/// FT-140: Oracle Static Cache - Loaded once at app startup
///
/// Provides in-memory Oracle 4.2 context with ultra-compact LLM format
/// for MCP-integrated activity detection while preserving Oracle methodology.
///
/// Key features:
/// - All 265 activities accessible via compact format
/// - Static loading at app startup (one-time file I/O)
/// - Fast lookup structures for post-processing
/// - Oracle methodology compliance validation
/// - MCP-compatible compact representation
class OracleStaticCache {
  static String? _compactOracleContext;
  static Map<String, OracleActivity>? _activityLookup;
  static Map<String, OracleDimension>? _dimensionLookup;
  static bool _isInitialized = false;
  static int _totalActivities = 0;

  /// Initialize Oracle static cache at app startup
  ///
  /// This should be called once during app initialization to load
  /// Oracle 4.2 data into memory for fast access throughout the app lifecycle.
  static Future<void> initializeAtStartup() async {
    if (_isInitialized) {
      Logger().debug('FT-140: Oracle cache already initialized');
      return;
    }

    try {
      Logger().info('🧠 FT-140: Initializing Oracle static cache at app startup...');

      // Load Oracle 4.2 data (one-time file I/O)
      final oracleContext = await _loadOracleContext();
      if (oracleContext == null) {
        Logger().warning('FT-140: No Oracle context available - cache not initialized');
        return;
      }

      // Build compact LLM format with ALL 265 activities
      _compactOracleContext = _buildCompactLLMFormat(oracleContext);
      
      // Build fast lookup structures
      _activityLookup = _buildActivityLookup(oracleContext);
      _dimensionLookup = _buildDimensionLookup(oracleContext);
      _totalActivities = oracleContext.totalActivities;

      _isInitialized = true;

      Logger().info('✅ FT-140: Oracle cache initialized successfully');
      Logger().info('   📊 Total activities: $_totalActivities');
      Logger().info('   📏 Compact format size: ${_compactOracleContext!.length} chars');
      Logger().info('   🔍 Fast lookup entries: ${_activityLookup!.length}');

      // Validate Oracle methodology compliance
      await _validateOracleCompliance();

    } catch (e) {
      Logger().error('FT-140: Failed to initialize Oracle static cache: $e');
      _isInitialized = false;
    }
  }

  /// Get compact representation of ALL Oracle activities for LLM
  ///
  /// Returns ultra-compact format suitable for MCP commands:
  /// "SF1:Água,SF2:Exercício,R1:Escuta,E1:Gratidão,..."
  ///
  /// This format includes ALL 265 activities while minimizing token usage.
  static String getCompactOracleForLLM() {
    if (!_isInitialized || _compactOracleContext == null) {
      throw StateError('FT-140: Oracle cache not initialized. Call initializeAtStartup() first.');
    }
    return _compactOracleContext!;
  }

  /// Get activity by Oracle code
  ///
  /// Fast O(1) lookup for activity details by code (e.g., "SF1", "R2")
  static OracleActivity? getActivityByCode(String code) {
    if (!_isInitialized || _activityLookup == null) {
      Logger().warning('FT-140: Oracle cache not initialized for activity lookup');
      return null;
    }
    return _activityLookup![code.toUpperCase()];
  }

  /// Get activities by multiple codes
  ///
  /// Efficient batch lookup for multiple activity codes
  static List<OracleActivity> getActivitiesByCodes(List<String> codes) {
    if (!_isInitialized || _activityLookup == null) {
      Logger().warning('FT-140: Oracle cache not initialized for batch lookup');
      return [];
    }

    final activities = <OracleActivity>[];
    for (final code in codes) {
      final activity = _activityLookup![code.toUpperCase()];
      if (activity != null) {
        activities.add(activity);
      }
    }

    Logger().debug('FT-140: Retrieved ${activities.length} activities from ${codes.length} codes');
    return activities;
  }

  /// Get dimension information
  static OracleDimension? getDimensionByCode(String code) {
    if (!_isInitialized || _dimensionLookup == null) {
      return null;
    }
    return _dimensionLookup![code.toUpperCase()];
  }

  /// Check if cache is initialized and ready
  static bool get isInitialized => _isInitialized;

  /// Get total number of activities in cache
  static int get totalActivities => _totalActivities;

  /// Get cache statistics for debugging
  static Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': _isInitialized,
      'totalActivities': _totalActivities,
      'compactFormatSize': _compactOracleContext?.length ?? 0,
      'activityLookupSize': _activityLookup?.length ?? 0,
      'dimensionLookupSize': _dimensionLookup?.length ?? 0,
      'estimatedTokens': (_compactOracleContext?.length ?? 0) ~/ 4, // Rough estimate
    };
  }

  /// Load Oracle context using existing infrastructure
  static Future<OracleContext?> _loadOracleContext() async {
    try {
      // Use existing OracleContextManager to get current persona's Oracle context
      return await OracleContextManager.getForCurrentPersona();
    } catch (e) {
      Logger().debug('FT-140: Failed to load Oracle context: $e');
      return null;
    }
  }

  /// Build compact LLM format: SF1:Água,SF2:Exercício,R1:Escuta,...
  ///
  /// This format provides ALL 265 activities in minimal token usage
  /// while maintaining complete Oracle methodology accessibility.
  static String _buildCompactLLMFormat(OracleContext oracleContext) {
    final activities = <String>[];

    // Process all dimensions and activities
    for (final dimension in oracleContext.dimensions.values) {
      for (final activity in dimension.activities) {
        // Compact format: CODE:NAME
        activities.add('${activity.code}:${activity.description}');
      }
    }

    // Sort by code for consistency
    activities.sort();

    Logger().debug('FT-140: Built compact format with ${activities.length} activities');
    return activities.join(',');
  }

  /// Build fast activity lookup map
  static Map<String, OracleActivity> _buildActivityLookup(OracleContext oracleContext) {
    final lookup = <String, OracleActivity>{};

    for (final dimension in oracleContext.dimensions.values) {
      for (final activity in dimension.activities) {
        lookup[activity.code.toUpperCase()] = activity;
      }
    }

    Logger().debug('FT-140: Built activity lookup with ${lookup.length} entries');
    return lookup;
  }

  /// Build fast dimension lookup map
  static Map<String, OracleDimension> _buildDimensionLookup(OracleContext oracleContext) {
    final lookup = <String, OracleDimension>{};

    for (final dimension in oracleContext.dimensions.values) {
      lookup[dimension.code.toUpperCase()] = dimension;
    }

    Logger().debug('FT-140: Built dimension lookup with ${lookup.length} entries');
    return lookup;
  }

  /// Validate Oracle methodology compliance
  ///
  /// Ensures all 265 activities are accessible and cache integrity
  static Future<void> _validateOracleCompliance() async {
    try {
      // Check total activity count
      if (_totalActivities != 265) {
        Logger().error('FT-140: Oracle compliance VIOLATION - Expected 265 activities, got $_totalActivities');
        return;
      }

      // Check compact format contains all activities
      final compactActivityCount = _compactOracleContext!.split(',').length;
      if (compactActivityCount != 265) {
        Logger().error('FT-140: Compact format VIOLATION - Expected 265 activities, got $compactActivityCount');
        return;
      }

      // Check lookup table completeness
      if (_activityLookup!.length != 265) {
        Logger().error('FT-140: Lookup table VIOLATION - Expected 265 activities, got ${_activityLookup!.length}');
        return;
      }

      // Validate sample activities exist
      final sampleCodes = ['SF1', 'R1', 'E1', 'SM1', 'TG1', 'TT1', 'PR1', 'F1'];
      for (final code in sampleCodes) {
        if (_activityLookup![code] == null) {
          Logger().warning('FT-140: Sample activity $code not found in cache');
        }
      }

      Logger().info('✅ FT-140: Oracle methodology compliance VERIFIED');
      Logger().info('   📋 All 265 activities accessible');
      Logger().info('   🔍 Compact format complete');
      Logger().info('   ⚡ Fast lookup operational');

    } catch (e) {
      Logger().error('FT-140: Oracle compliance validation failed: $e');
    }
  }

  /// Clear cache (for testing or reinitialization)
  static void clearCache() {
    Logger().debug('FT-140: Clearing Oracle static cache');
    _compactOracleContext = null;
    _activityLookup = null;
    _dimensionLookup = null;
    _totalActivities = 0;
    _isInitialized = false;
  }

  /// Force reinitialization (for testing or Oracle data updates)
  static Future<void> reinitialize() async {
    Logger().info('FT-140: Force reinitializing Oracle static cache');
    clearCache();
    await initializeAtStartup();
  }
}
