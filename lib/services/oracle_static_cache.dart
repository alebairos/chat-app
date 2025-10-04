import 'dart:convert';
import 'package:flutter/services.dart';
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

  // FT-179: Goals mapping cache
  static Map<String, dynamic>? _goalsMappingCache;
  static bool _goalsMappingInitialized = false;

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
      Logger().info(
          '🧠 FT-140: Initializing Oracle static cache at app startup...');

      // Load Oracle 4.2 data (one-time file I/O)
      final oracleContext = await _loadOracleContext();
      if (oracleContext == null) {
        Logger().warning(
            'FT-140: No Oracle context available - cache not initialized');
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
      Logger().info(
          '   📏 Compact format size: ${_compactOracleContext!.length} chars');
      Logger().info('   🔍 Fast lookup entries: ${_activityLookup!.length}');

      // FT-141: Validate Oracle methodology compliance with 4.2 specifics
      await _validateOracleCompliance(oracleContext);
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
      throw StateError(
          'FT-140: Oracle cache not initialized. Call initializeAtStartup() first.');
    }
    return _compactOracleContext!;
  }

  /// Get activity by Oracle code
  ///
  /// Fast O(1) lookup for activity details by code (e.g., "SF1", "R2")
  static OracleActivity? getActivityByCode(String code) {
    if (!_isInitialized || _activityLookup == null) {
      Logger()
          .warning('FT-140: Oracle cache not initialized for activity lookup');
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

    Logger().debug(
        'FT-140: Retrieved ${activities.length} activities from ${codes.length} codes');
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

  /// Get cache statistics for debugging (FT-141 enhanced)
  static Map<String, dynamic> getDebugInfo() {
    final debugInfo = {
      'initialized': _isInitialized,
      'totalActivities': _totalActivities,
      'compactFormatSize': _compactOracleContext?.length ?? 0,
      'activityLookupSize': _activityLookup?.length ?? 0,
      'dimensionLookupSize': _dimensionLookup?.length ?? 0,
      'estimatedTokens':
          (_compactOracleContext?.length ?? 0) ~/ 4, // Rough estimate
    };

    // FT-141: Add Oracle 4.2 validation info if cache is initialized
    if (_isInitialized && _dimensionLookup != null) {
      final dimensions = _dimensionLookup!.keys.toSet();
      final hasOracle42Dimensions = dimensions.contains('TT') &&
          dimensions.contains('PR') &&
          dimensions.contains('F');

      debugInfo['oracle42Validation'] = {
        'isOracle42': hasOracle42Dimensions,
        'dimensionCount': dimensions.length,
        'expectedDimensions': hasOracle42Dimensions ? 8 : 5,
        'expectedActivities': hasOracle42Dimensions ? 265 : 150,
        'actualActivities': _totalActivities,
        'dimensionsPresent': dimensions.toList()..sort(),
        'newDimensionsPresent': hasOracle42Dimensions ? ['TT', 'PR', 'F'] : [],
        'validationStatus': hasOracle42Dimensions
            ? (_totalActivities >= 265 && dimensions.length == 8
                ? 'PASSED'
                : 'FAILED')
            : (_totalActivities >= 150 ? 'PASSED' : 'FAILED'),
      };

      // Add dimension-specific activity counts if available
      if (_dimensionLookup != null) {
        debugInfo['dimensionActivityCounts'] = {
          for (final entry in _dimensionLookup!.entries)
            entry.key: entry.value.activities.length
        };
      }
    }

    return debugInfo;
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
        // Escape commas in descriptions to prevent parsing issues
        final escapedDescription = activity.description.replaceAll(',', ';');
        // Compact format: CODE:NAME
        activities.add('${activity.code}:$escapedDescription');
      }
    }

    // Sort by code for consistency
    activities.sort();

    Logger().debug(
        'FT-140: Built compact format with ${activities.length} activities');
    return activities.join(',');
  }

  /// Build fast activity lookup map
  static Map<String, OracleActivity> _buildActivityLookup(
      OracleContext oracleContext) {
    final lookup = <String, OracleActivity>{};

    for (final dimension in oracleContext.dimensions.values) {
      for (final activity in dimension.activities) {
        lookup[activity.code.toUpperCase()] = activity;
      }
    }

    Logger()
        .debug('FT-140: Built activity lookup with ${lookup.length} entries');
    return lookup;
  }

  /// Build fast dimension lookup map
  static Map<String, OracleDimension> _buildDimensionLookup(
      OracleContext oracleContext) {
    final lookup = <String, OracleDimension>{};

    for (final dimension in oracleContext.dimensions.values) {
      lookup[dimension.code.toUpperCase()] = dimension;
    }

    Logger()
        .debug('FT-140: Built dimension lookup with ${lookup.length} entries');
    return lookup;
  }

  /// Validate Oracle methodology compliance (FT-141 enhanced)
  ///
  /// Ensures all 265 activities are accessible and Oracle 4.2 compliance
  static Future<void> _validateOracleCompliance(
      OracleContext oracleContext) async {
    try {
      // FT-141: Check if this is Oracle 4.2 based on dimensions
      final dimensions = oracleContext.dimensions;
      final hasOracle42Dimensions = dimensions.containsKey('TT') &&
          dimensions.containsKey('PR') &&
          dimensions.containsKey('F');

      if (hasOracle42Dimensions) {
        Logger().info('🔍 FT-141: Validating Oracle 4.2 compliance...');

        // Validate 8 dimensions for Oracle 4.2
        final expectedDimensions = {
          'E',
          'F',
          'PR',
          'R',
          'SF',
          'SM',
          'TG',
          'TT'
        };
        final actualDimensions = dimensions.keys.toSet();

        if (actualDimensions.length != 8) {
          throw Exception(
              'FT-141: Oracle 4.2 cache validation failed - Expected 8 dimensions, got ${actualDimensions.length}');
        }

        final missingDimensions =
            expectedDimensions.difference(actualDimensions);
        if (missingDimensions.isNotEmpty) {
          throw Exception(
              'FT-141: Oracle 4.2 cache validation failed - Missing dimensions: ${missingDimensions.join(', ')}');
        }

        // Validate 265+ activities for Oracle 4.2
        if (_totalActivities < 265) {
          throw Exception(
              'FT-141: Oracle 4.2 cache validation failed - Expected 265+ activities, got $_totalActivities');
        }

        // Validate new dimensions have activities
        final ttActivities = dimensions['TT']?.activities.length ?? 0;
        final prActivities = dimensions['PR']?.activities.length ?? 0;
        final fActivities = dimensions['F']?.activities.length ?? 0;

        if (ttActivities == 0) {
          throw Exception(
              'FT-141: Oracle 4.2 cache validation failed - TT dimension has no activities');
        }
        if (prActivities == 0) {
          throw Exception(
              'FT-141: Oracle 4.2 cache validation failed - PR dimension has no activities');
        }
        if (fActivities == 0) {
          throw Exception(
              'FT-141: Oracle 4.2 cache validation failed - F dimension has no activities');
        }

        Logger().info('✅ FT-141: Oracle 4.2 compliance VERIFIED');
        Logger().info('   📊 8 dimensions: ${actualDimensions.join(', ')}');
        Logger().info('   📋 $_totalActivities activities total');
        Logger().info(
            '   🆕 New dimensions: TT($ttActivities), PR($prActivities), F($fActivities)');
      } else {
        Logger().info('🔍 FT-141: Validating legacy Oracle compliance...');

        // Legacy Oracle validation (non-4.2)
        if (_totalActivities < 150) {
          Logger().warning(
              'FT-141: Legacy Oracle has fewer than expected activities: $_totalActivities');
        }
      }

      // Common validation for all Oracle versions
      // Check compact format contains all activities
      final compactActivityCount = _compactOracleContext!.split(',').length;
      if (compactActivityCount != _totalActivities) {
        throw Exception(
            'FT-141: Compact format validation failed - Expected $_totalActivities activities, got $compactActivityCount');
      }

      // Check lookup table completeness
      if (_activityLookup!.length != _totalActivities) {
        throw Exception(
            'FT-141: Lookup table validation failed - Expected $_totalActivities activities, got ${_activityLookup!.length}');
      }

      // Validate sample activities exist (Oracle 4.2 specific)
      if (hasOracle42Dimensions) {
        final oracle42SampleCodes = [
          'SF1',
          'R1',
          'E1',
          'SM1',
          'TG1',
          'TT1',
          'PR1',
          'F1'
        ];
        for (final code in oracle42SampleCodes) {
          if (_activityLookup![code] == null) {
            Logger().warning(
                'FT-141: Oracle 4.2 sample activity $code not found in cache');
          }
        }
      }

      Logger().info('✅ FT-141: Oracle methodology compliance VERIFIED');
      Logger().info('   📋 All $_totalActivities activities accessible');
      Logger().info('   🔍 Compact format complete');
      Logger().info('   ⚡ Fast lookup operational');
    } catch (e) {
      Logger().error('FT-141: Oracle compliance validation failed: $e');
      rethrow; // Re-throw to prevent initialization with invalid data
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

  /// FT-179: Initialize goals mapping cache
  ///
  /// Loads Oracle goals mapping data for objectives statistics
  static Future<void> initializeGoalsMapping() async {
    if (_goalsMappingInitialized) {
      Logger().debug('FT-179: Goals mapping cache already initialized');
      return;
    }

    try {
      Logger().info('FT-179: Initializing goals mapping cache...');
      
      final jsonString = await rootBundle.loadString(
        'assets/config/oracle/oracle_prompt_4.2_goals_mapping.json'
      );
      _goalsMappingCache = json.decode(jsonString);
      _goalsMappingInitialized = true;
      
      final totalObjectives = _goalsMappingCache?['metadata']?['total_goals'] ?? 0;
      Logger().info('✅ FT-179: Goals mapping cache initialized with $totalObjectives objectives');
    } catch (e) {
      Logger().warning('FT-179: Failed to load goals mapping: $e');
      _goalsMappingCache = null;
      _goalsMappingInitialized = false;
    }
  }

  /// FT-179: Get objectives statistics from cached goals mapping
  ///
  /// Returns objectives count and breakdown by dimension
  static Map<String, dynamic> getObjectivesStatistics() {
    if (!_goalsMappingInitialized || _goalsMappingCache == null) {
      Logger().debug('FT-179: Goals mapping not available, returning empty statistics');
      return {
        'total_objectives': 0,
        'objectives_by_dimension': <String, List<String>>{},
        'all_objectives': <String>[],
      };
    }

    return _extractObjectivesFromCache();
  }

  /// FT-179: Extract objectives data from cached goals mapping
  static Map<String, dynamic> _extractObjectivesFromCache() {
    final goalTrilhaMapping = _goalsMappingCache!['goal_trilha_mapping'] as Map<String, dynamic>? ?? {};
    final objectivesByDimension = <String, List<String>>{};
    final allObjectives = <String>[];

    // Extract objectives dynamically from cached data
    for (final entry in goalTrilhaMapping.entries) {
      final objectiveCode = entry.key;
      final objectiveData = entry.value as Map<String, dynamic>;
      final dimension = objectiveData['dimension'] as String? ?? 'Unknown';

      allObjectives.add(objectiveCode);
      objectivesByDimension.putIfAbsent(dimension, () => []).add(objectiveCode);
    }

    // Sort for consistent output
    allObjectives.sort();
    for (final dimensionList in objectivesByDimension.values) {
      dimensionList.sort();
    }

    Logger().debug('FT-179: Extracted ${allObjectives.length} objectives from cache');
    
    return {
      'total_objectives': allObjectives.length,
      'objectives_by_dimension': objectivesByDimension,
      'all_objectives': allObjectives,
    };
  }

  /// Force reinitialization (for testing or Oracle data updates)
  static Future<void> reinitialize() async {
    Logger().info('FT-140: Force reinitializing Oracle static cache');
    clearCache();
    await initializeAtStartup();
    await initializeGoalsMapping(); // FT-179: Also reinitialize goals mapping
  }
}
