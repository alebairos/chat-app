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
      _logger.debug('FT-146: Initializing DimensionDisplayService...');
      _cachedContext = await OracleContextManager.getForCurrentPersona();
      _isInitialized = true;
      
      if (_cachedContext != null) {
        _logger.info('FT-146: Initialized with ${_cachedContext!.dimensions.length} Oracle dimensions');
        
        // Log available dimensions for debugging
        for (final dimension in _cachedContext!.dimensions.values) {
          _logger.debug('FT-146: Dimension ${dimension.code}: "${dimension.displayName}"');
        }
      } else {
        _logger.warning('FT-146: No Oracle context available, using fallback behavior');
      }
    } catch (e) {
      _logger.error('FT-146: Failed to initialize DimensionDisplayService: $e');
      _isInitialized = false;
    }
  }
  
  /// Get display name from Oracle data
  static String getDisplayName(String dimensionCode) {
    if (!_isInitialized) {
      _logger.warning('FT-146: Service not initialized, using fallback for $dimensionCode');
      return _getFallbackDisplayName(dimensionCode);
    }
    
    final dimension = _cachedContext?.dimensions[dimensionCode.toUpperCase()];
    if (dimension != null) {
      _logger.debug('FT-146: Using Oracle display name for $dimensionCode: "${dimension.displayName}"');
      return dimension.displayName;
    }
    
    _logger.warning('FT-146: No Oracle data for dimension $dimensionCode, using fallback');
    // Fallback for unknown dimensions
    return _getFallbackDisplayName(dimensionCode);
  }
  
  /// Get dimension color with smart defaults
  static Color getColor(String dimensionCode) {
    switch (dimensionCode.toUpperCase()) {
      case 'SF':
        return Colors.green;      // Physical Health
      case 'SM':
        return Colors.blue;       // Mental Health  
      case 'TG':
      case 'T':
        return Colors.orange;     // Work & Management
      case 'R':
        return Colors.pink;       // Relationships
      case 'E':
        return Colors.purple;     // Spirituality
      case 'TT':
        return Colors.red;        // Screen Time
      case 'PR':
        return Colors.amber;      // Anti-Procrastination
      case 'F':
        return Colors.teal;       // Finance
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
}
