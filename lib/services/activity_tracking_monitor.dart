import '../utils/logger.dart';
import 'activity_memory_service.dart';
import 'claude_service.dart';

/// Activity tracking monitoring utility for degradation policy effectiveness
class ActivityTrackingMonitor {
  static final Logger _logger = Logger();

  /// Generate a comprehensive status report for FT-119
  static Future<String> generateStatusReport() async {
    final buffer = StringBuffer();

    buffer.writeln('=== FT-119 ACTIVITY TRACKING DEGRADATION STATUS ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('');

    // Rate limit tracking status
    try {
      final rateLimitStatus = RateLimitTracker.getStatus();
      buffer.writeln('📊 RATE LIMIT TRACKING:');
      buffer.writeln(
          '  Recent Rate Limit: ${rateLimitStatus['hasRecentRateLimit']}');
      buffer.writeln('  High API Usage: ${rateLimitStatus['hasHighApiUsage']}');
      buffer.writeln(
          '  Last Rate Limit: ${rateLimitStatus['lastRateLimit'] ?? 'Never'}');
      buffer.writeln(
          '  API Calls (Last Min): ${rateLimitStatus['apiCallsLastMinute']}/${rateLimitStatus['maxCallsPerMinute']}');
      buffer.writeln('');
    } catch (e) {
      buffer.writeln('❌ Rate limit status unavailable: $e');
      buffer.writeln('');
    }

    // Activity queue status
    try {
      final queueStatus = ActivityQueue.getQueueStatus();
      buffer.writeln('📋 ACTIVITY QUEUE STATUS:');
      buffer.writeln(
          '  Pending Activities: ${queueStatus['pendingCount']}/${queueStatus['maxQueueSize']}');
      buffer.writeln(
          '  Oldest Request: ${queueStatus['oldestRequest'] ?? 'None'}');

      if (queueStatus['pendingCount'] > 0) {
        buffer.writeln('  Queued Requests:');
        for (final request in queueStatus['requests']) {
          buffer.writeln(
              '    - "${request['message']}" (${request['retryCount']} retries)');
        }
      }
      buffer.writeln('');
    } catch (e) {
      buffer.writeln('❌ Queue status unavailable: $e');
      buffer.writeln('');
    }

    // Recent activity stats
    try {
      final todayStats = await ActivityMemoryService.getActivityStats(days: 0);
      final weekStats = await ActivityMemoryService.getActivityStats(days: 7);

      buffer.writeln('📈 ACTIVITY TRACKING PERFORMANCE:');
      buffer
          .writeln('  Today\'s Activities: ${todayStats['total_activities']}');
      buffer.writeln('  Week\'s Activities: ${weekStats['total_activities']}');

      if (todayStats.containsKey('database_error')) {
        buffer.writeln('  ⚠️  Database Issue: ${todayStats['database_error']}');
      }
      buffer.writeln('');
    } catch (e) {
      buffer.writeln('❌ Activity stats unavailable: $e');
      buffer.writeln('');
    }

    // Effectiveness assessment
    buffer.writeln('🎯 EFFECTIVENESS ASSESSMENT:');
    final hasQueuedActivities = ActivityQueue.hasPendingActivities();
    final hasRecentRateLimit = RateLimitTracker.hasRecentRateLimit();

    if (!hasRecentRateLimit && !hasQueuedActivities) {
      buffer.writeln(
          '  ✅ System operating normally - no rate limits or queued activities');
    } else if (hasRecentRateLimit && hasQueuedActivities) {
      buffer.writeln(
          '  🔄 Rate limit recovery in progress - activities queued for processing');
    } else if (hasQueuedActivities) {
      buffer.writeln(
          '  ⏳ Processing queued activities from previous rate limits');
    } else {
      buffer.writeln(
          '  ⚠️  Recent rate limits detected - monitoring for queue activity');
    }

    buffer.writeln('');
    buffer.writeln('=== END REPORT ===');

    return buffer.toString();
  }

  /// Log a status report to console (for debugging)
  static Future<void> logStatusReport() async {
    final report = await generateStatusReport();
    _logger.info('FT-119 Status Report:\n$report');
  }

  /// Quick health check - returns true if system is working properly
  static Future<bool> isSystemHealthy() async {
    try {
      // Check if database is available
      final dbAvailable = await ActivityMemoryService.isDatabaseAvailable();
      if (!dbAvailable) return false;

      // Check if queue is not overflowing
      final queueCount = ActivityQueue.getPendingCount();
      if (queueCount >= 15) return false; // 75% of max queue size

      // System is healthy
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get key metrics for dashboard/monitoring
  static Future<Map<String, dynamic>> getKeyMetrics() async {
    try {
      final rateLimitStatus = RateLimitTracker.getStatus();
      final queueStatus = ActivityQueue.getQueueStatus();
      final todayStats = await ActivityMemoryService.getActivityStats(days: 0);

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'rate_limit_active': rateLimitStatus['hasRecentRateLimit'],
        'api_calls_per_minute': rateLimitStatus['apiCallsLastMinute'],
        'queued_activities': queueStatus['pendingCount'],
        'today_activities': todayStats['total_activities'],
        'system_healthy': await isSystemHealthy(),
        'last_rate_limit': rateLimitStatus['lastRateLimit'],
      };
    } catch (e) {
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
        'system_healthy': false,
      };
    }
  }
}
