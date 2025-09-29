import 'dart:math';
import '../utils/logger.dart';

/// FT-151: Centralized Claude API rate limiting using proven ClaudeService logic
/// FT-155: Added Claude overload protection for 529 errors
///
/// Extracts existing _RateLimitTracker functionality into a shared component
/// to coordinate API calls across all services and prevent HTTP 429 errors.
/// Adds circuit breaker pattern for Claude server overload (529) protection.
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

  // FT-155: Claude overload protection (529 errors)
  static bool _claudeOverloaded = false;
  static DateTime? _lastOverloadTime;
  static int _overloadCount = 0;

  /// Apply rate limiting before API call - core coordination method
  /// Uses existing adaptive delay logic from ClaudeService
  /// FT-152: Added isUserFacing parameter for differentiated delays
  /// FT-155: Added overload protection check
  Future<void> waitAndRecord({bool isUserFacing = false}) async {
    _logger.debug(
        'SharedClaudeRateLimiter: Checking rate limits before API call (${isUserFacing ? "user-facing" : "background"})');

    // FT-155: Check for Claude overload first
    if (isClaudeOverloaded()) {
      if (!isUserFacing) {
        throw Exception('Claude overloaded - skipping background call');
      }
      // For user-facing calls, continue with warning but apply overload delays
      _logger.warning(
          'SharedClaudeRateLimiter: Claude overloaded, but allowing user-facing call');
    }

    Duration delay;

    if (_hasRecentRateLimit()) {
      // FT-154: Graduated recovery - faster for users, maintain protection for background
      if (_testingMode) {
        delay = isUserFacing
            ? const Duration(milliseconds: 1) // Testing: 1ms instead of 3s
            : const Duration(milliseconds: 2); // Testing: 2ms instead of 15s
      } else {
        delay = isUserFacing
            ? const Duration(seconds: 3) // Faster user recovery
            : const Duration(seconds: 15); // Maintain background protection
      }
      _logger.debug(
          'SharedClaudeRateLimiter: Recent rate limit detected, applying ${_testingMode ? "${delay.inMilliseconds}ms" : "${delay.inSeconds}s"} delay for ${isUserFacing ? "user-facing" : "background"} request');
    } else if (_hasHighApiUsage()) {
      // Differentiate based on user impact
      if (_testingMode) {
        delay = isUserFacing
            ? const Duration(microseconds: 500) // Testing: 0.5ms instead of 2s
            : const Duration(milliseconds: 1); // Testing: 1ms instead of 8s
      } else {
        delay = isUserFacing
            ? const Duration(seconds: 2) // Faster for users
            : const Duration(seconds: 8); // Slower for background
      }
      _logger.debug(
          'SharedClaudeRateLimiter: High API usage detected, applying ${_testingMode ? "${delay.inMilliseconds}ms" : "${delay.inSeconds}s"} delay for ${isUserFacing ? "user-facing" : "background"} request');
    } else {
      // Normal usage - minimal delays for user-facing
      if (_testingMode) {
        delay = isUserFacing
            ? const Duration(
                microseconds: 100) // Testing: 0.1ms instead of 500ms
            : const Duration(microseconds: 200); // Testing: 0.2ms instead of 3s
      } else {
        delay = isUserFacing
            ? const Duration(milliseconds: 500) // Much faster for users
            : const Duration(seconds: 3); // Standard for background
      }
      _logger.debug(
          'SharedClaudeRateLimiter: Normal usage, applying ${delay.inMilliseconds}ms delay for ${isUserFacing ? "user-facing" : "background"} request');
    }

    // Skip delays entirely in testing mode for instant execution
    if (!_testingMode) {
      await Future.delayed(delay);
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
    final cutoff = DateTime.now().subtract(const Duration(minutes: 1));
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

  /// Testing mode flag - when true, uses minimal delays for fast testing
  static bool _testingMode = false;

  /// Enable testing mode with minimal delays (10ms instead of seconds)
  static void enableTestingMode() {
    _testingMode = true;
  }

  /// Disable testing mode (back to normal delays)
  static void disableTestingMode() {
    _testingMode = false;
  }

  /// Reset state for testing purposes
  static void resetForTesting() {
    _apiCallHistory.clear();
    _lastRateLimit = null;
    _testingMode = false; // Reset testing mode too
    // FT-155: Reset overload state too
    _claudeOverloaded = false;
    _lastOverloadTime = null;
    _overloadCount = 0;
  }

  // FT-155: Claude overload protection methods

  /// Check if Claude is currently overloaded (529 errors)
  static bool isClaudeOverloaded() {
    if (!_claudeOverloaded) return false;

    // Auto-recover after exponential backoff
    Duration backoff =
        Duration(seconds: min(300, pow(2, _overloadCount).toInt() * 30));
    if (DateTime.now().difference(_lastOverloadTime!) > backoff) {
      _claudeOverloaded = false;
      _overloadCount = 0;
      _logger.info(
          'SharedClaudeRateLimiter: Claude overload state cleared after backoff');
      return false;
    }
    return true;
  }

  /// Record Claude overload event (529 error)
  static void recordOverload() {
    _claudeOverloaded = true;
    _lastOverloadTime = DateTime.now();
    _overloadCount++;

    Duration nextBackoff =
        Duration(seconds: min(300, pow(2, _overloadCount).toInt() * 30));
    _logger.warning(
        'SharedClaudeRateLimiter: Claude overload recorded (count: $_overloadCount, next check in ${nextBackoff.inSeconds}s)');
  }

  /// Get overload status for debugging
  static Map<String, dynamic> getOverloadStatus() {
    return {
      'isOverloaded': _claudeOverloaded,
      'lastOverloadTime': _lastOverloadTime?.toIso8601String(),
      'overloadCount': _overloadCount,
      'nextRecoveryCheck': _lastOverloadTime
          ?.add(
              Duration(seconds: min(300, pow(2, _overloadCount).toInt() * 30)))
          .toIso8601String(),
    };
  }
}
