import 'package:flutter/material.dart';
import '../services/oracle_context_manager.dart';
import '../services/semantic_activity_detector.dart';
import '../utils/logger.dart';

/// FT-146: Oracle-based dimension display service
///
/// Provides centralized dimension display logic using Oracle JSON as source of truth.
/// Eliminates hardcoded dimension mappings and supports all Oracle versions.
class DimensionDisplayService {
  static final Logger _logger = Logger();
  static OracleContext? _cachedContext;
  static bool _isInitialized = false;

  /// Initialize with current Oracle context
  static Future<void> initialize() async {
    try {
      _logger.info('FT-147: 🚀 Initializing DimensionDisplayService...');
      _cachedContext = await OracleContextManager.getForCurrentPersona();
      _isInitialized = true;

      if (_cachedContext != null) {
        _logger.info(
            'FT-147: ✅ Initialized with ${_cachedContext!.dimensions.length} Oracle dimensions');

        // Log available dimensions for debugging
        _logger.info(
            'FT-147: Available dimension codes: ${_cachedContext!.dimensions.keys.toList()}');
        for (final dimension in _cachedContext!.dimensions.values) {
          _logger.info(
              'FT-147: Dimension ${dimension.code}: "${dimension.displayName}"');
        }
      } else {
        _logger.warning(
            'FT-147: ❌ No Oracle context available, using fallback behavior');
      }
    } catch (e) {
      _logger
          .error('FT-147: ❌ Failed to initialize DimensionDisplayService: $e');
      _isInitialized = false;
    }
  }

  /// Get display name from Oracle data
  static String getDisplayName(String dimensionCode) {
    _logger.info('FT-147: 🔍 getDisplayName called with: "$dimensionCode"');
    _logger.info('FT-147: Service initialized: $_isInitialized');
    _logger.info('FT-147: Oracle context available: ${_cachedContext != null}');
    
    if (!_isInitialized) {
      _logger.warning(
          'FT-147: ❌ Service not initialized, using fallback for $dimensionCode');
      final fallback = _getFallbackDisplayName(dimensionCode);
      _logger.warning('FT-147: Returning fallback: "$fallback"');
      return fallback;
    }

    if (_cachedContext == null) {
      _logger.warning(
          'FT-147: ❌ No Oracle context available, using fallback for $dimensionCode');
      final fallback = _getFallbackDisplayName(dimensionCode);
      _logger.warning('FT-147: Returning fallback: "$fallback"');
      return fallback;
    }

    final upperCode = dimensionCode.toUpperCase();
    _logger.info('FT-147: Looking up dimension: "$upperCode"');
    _logger.info('FT-147: Available dimensions: ${_cachedContext!.dimensions.keys.toList()}');
    
    final dimension = _cachedContext!.dimensions[upperCode];
    if (dimension != null) {
      _logger.info('FT-147: ✅ Found Oracle dimension: "$upperCode" -> "${dimension.displayName}"');
      return dimension.displayName;
    }

    _logger.warning(
        'FT-147: ❌ No Oracle data for dimension $upperCode, using fallback');
    final fallback = _getFallbackDisplayName(dimensionCode);
    _logger.warning('FT-147: Returning fallback: "$fallback"');
    return fallback;
  }

  /// Get dimension color with smart defaults
  static Color getColor(String dimensionCode) {
    switch (dimensionCode.toUpperCase()) {
      case 'SF':
        return Colors.green; // Physical Health
      case 'SM':
        return Colors.blue; // Mental Health
      case 'TG':
      case 'T':
        return Colors.orange; // Work & Management
      case 'R':
        return Colors.pink; // Relationships
      case 'E':
        return Colors.purple; // Spirituality
      case 'TT':
        return Colors.red; // Screen Time
      case 'PR':
        return Colors.amber; // Anti-Procrastination
      case 'F':
        return Colors.teal; // Finance
      default:
        return Colors.grey;
    }
  }

  /// Get dimension icon with smart defaults
  static IconData getIcon(String dimensionCode) {
    switch (dimensionCode.toUpperCase()) {
      case 'SF':
        return Icons.fitness_center;
      case 'SM':
        return Icons.psychology;
      case 'TG':
      case 'T':
        return Icons.work;
      case 'R':
        return Icons.people;
      case 'E':
        return Icons.self_improvement;
      case 'TT':
        return Icons.access_time;
      case 'PR':
        return Icons.timer;
      case 'F':
        return Icons.account_balance_wallet;
      default:
        return Icons.category;
    }
  }

  /// Refresh context when persona changes
  static Future<void> refresh() async {
    _logger.debug('FT-146: Refreshing DimensionDisplayService...');
    _isInitialized = false;
    _cachedContext = null;
    await initialize();
  }

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;

  /// Get cached Oracle context (for debugging)
  static OracleContext? get cachedContext => _cachedContext;

  /// Fallback display names for when Oracle data is unavailable
  static String _getFallbackDisplayName(String dimensionCode) {
    switch (dimensionCode.toUpperCase()) {
      case 'SF':
        return 'Physical Health';
      case 'SM':
        return 'Mental Health';
      case 'TG':
      case 'T':
        return 'Work & Management';
      case 'R':
        return 'Relationships';
      case 'E':
        return 'Spirituality';
      case 'TT':
        return 'Screen Time';
      case 'PR':
        return 'Anti-Procrastination';
      case 'F':
        return 'Finance';
      default:
        return dimensionCode;
    }
  }

  /// Get debug information
  static Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': _isInitialized,
      'hasOracleContext': _cachedContext != null,
      'dimensionCount': _cachedContext?.dimensions.length ?? 0,
      'availableDimensions': _cachedContext?.dimensions.keys.toList() ?? [],
    };
  }

  /// FT-147: Debug method to log current service state
  static void logServiceState() {
    _logger.info('FT-147: === DimensionDisplayService State ===');
    _logger.info('FT-147: Initialized: $_isInitialized');
    _logger.info('FT-147: Has Oracle Context: ${_cachedContext != null}');
    if (_cachedContext != null) {
      _logger.info(
          'FT-147: Dimension Count: ${_cachedContext!.dimensions.length}');
      _logger.info(
          'FT-147: Available Codes: ${_cachedContext!.dimensions.keys.toList()}');
    }
    _logger.info('FT-147: =====================================');
  }
}
