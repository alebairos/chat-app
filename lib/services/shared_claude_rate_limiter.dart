import '../utils/logger.dart';

/// FT-151: Centralized Claude API rate limiting using proven ClaudeService logic
///
/// Extracts existing _RateLimitTracker functionality into a shared component
/// to coordinate API calls across all services and prevent HTTP 429 errors.
class SharedClaudeRateLimiter {
  static final SharedClaudeRateLimiter _instance =
      SharedClaudeRateLimiter._internal();
  factory SharedClaudeRateLimiter() => _instance;
  SharedClaudeRateLimiter._internal();

  static final Logger _logger = Logger();

  // Extracted from existing _RateLimitTracker (proven to work)
  static final List<DateTime> _apiCallHistory = [];
  static const int _maxCallsPerMinute = 8;
  static const Duration _rateLimitMemory = Duration(minutes: 2);
  static DateTime? _lastRateLimit;

  /// Apply rate limiting before API call - core coordination method
  /// Uses existing adaptive delay logic from ClaudeService
  Future<void> waitAndRecord() async {
    _logger
        .debug('SharedClaudeRateLimiter: Checking rate limits before API call');

    // Use existing adaptive delay logic from ClaudeService
    if (_hasRecentRateLimit()) {
      _logger.debug(
          'SharedClaudeRateLimiter: Recent rate limit detected, applying 15s delay');
      await Future.delayed(Duration(seconds: 15));
    } else if (_hasHighApiUsage()) {
      _logger.debug(
          'SharedClaudeRateLimiter: High API usage detected, applying 8s delay');
      await Future.delayed(Duration(seconds: 8));
    } else {
      _logger.debug('SharedClaudeRateLimiter: Normal usage, applying 5s delay');
      await Future.delayed(Duration(seconds: 5));
    }

    // Record this API call
    _apiCallHistory.add(DateTime.now());
    _cleanOldCalls();

    _logger.debug(
        'SharedClaudeRateLimiter: API call recorded, ${_apiCallHistory.length} calls in last minute');
  }

  /// Record rate limit event (for error handling)
  void recordRateLimit() {
    _lastRateLimit = DateTime.now();
    _logger.warning('SharedClaudeRateLimiter: Rate limit event recorded');
  }

  /// Check if system recently encountered rate limiting
  bool _hasRecentRateLimit() {
    if (_lastRateLimit == null) return false;
    return DateTime.now().difference(_lastRateLimit!) < _rateLimitMemory;
  }

  /// Check if system is experiencing high API usage
  bool _hasHighApiUsage() {
    _cleanOldCalls();
    return _apiCallHistory.length > _maxCallsPerMinute;
  }

  /// Clean old API calls from tracking (older than 1 minute)
  void _cleanOldCalls() {
    final cutoff = DateTime.now().subtract(Duration(minutes: 1));
    _apiCallHistory.removeWhere((call) => call.isBefore(cutoff));
  }

  /// Get current rate limit status for debugging
  Map<String, dynamic> getStatus() {
    _cleanOldCalls();
    return {
      'hasRecentRateLimit': _hasRecentRateLimit(),
      'hasHighApiUsage': _hasHighApiUsage(),
      'lastRateLimit': _lastRateLimit?.toIso8601String(),
      'apiCallsLastMinute': _apiCallHistory.length,
      'maxCallsPerMinute': _maxCallsPerMinute,
    };
  }

  /// Public interface methods for compatibility with existing RateLimitTracker
  static bool hasRecentRateLimit() {
    return SharedClaudeRateLimiter()._hasRecentRateLimit();
  }

  static bool hasHighApiUsage() {
    return SharedClaudeRateLimiter()._hasHighApiUsage();
  }

  static Map<String, dynamic> getStatusStatic() {
    return SharedClaudeRateLimiter().getStatus();
  }
}
