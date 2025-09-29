import '../models/pending_activity.dart';
import '../utils/logger.dart';
import 'semantic_activity_detector.dart';
import 'oracle_context_manager.dart';
import 'activity_memory_service.dart';

/// FT-154: Activity Queue System for Rate Limit Recovery
///
/// Preserves user activities during rate limits instead of silent failure.
/// Automatically processes queued activities when system recovers.
class ActivityQueue {
  static final List<PendingActivity> _queue = [];
  static final Logger _logger = Logger();
  static const int _maxQueueSize =
      100; // Prevent memory issues during extended outages

  /// Queue an activity for later processing during rate limit recovery
  static Future<void> queueActivity(String message, DateTime timestamp) async {
    // Prevent queue overflow during extended outages
    if (_queue.length >= _maxQueueSize) {
      _logger.warning(
          'FT-154: Activity queue full (${_queue.length}), removing oldest activity');
      _queue.removeAt(0); // Remove oldest activity
    }

    final activity = PendingActivity(
      message: message,
      timestamp: timestamp,
    );

    _queue.add(activity);
    _logger.info(
        'FT-154: Activity queued for later processing (queue size: ${_queue.length})');
    _logger.debug('FT-154: Queued activity: $activity');
  }

  /// Process all queued activities when system recovers from rate limits
  static Future<void> processQueue() async {
    if (_queue.isEmpty) return;

    _logger.info('FT-154: Processing ${_queue.length} queued activities');

    // Process activities in order (FIFO)
    final activitiesToProcess = List<PendingActivity>.from(_queue);

    for (final activity in activitiesToProcess) {
      try {
        _logger.debug('FT-154: Processing queued activity: $activity');

        // Process the activity detection for this message
        await _processActivityDetection(activity.message, activity.timestamp);

        // Remove successfully processed activity
        _queue.remove(activity);
        _logger.debug(
            'FT-154: Successfully processed and removed activity from queue');
      } catch (e) {
        _logger.warning('FT-154: Failed to process queued activity: $e');

        // If we hit rate limits again, stop processing and keep remaining items in queue
        if (_isRateLimitError(e)) {
          _logger.info(
              'FT-154: Hit rate limit while processing queue, stopping. ${_queue.length} activities remain queued');
          break;
        }

        // For non-rate-limit errors, remove the problematic activity to prevent infinite loops
        _queue.remove(activity);
        _logger.warning(
            'FT-154: Removed problematic activity from queue due to non-rate-limit error');
      }
    }

    if (_queue.isEmpty) {
      _logger.info('FT-154: All queued activities processed successfully');
    } else {
      _logger.info(
          'FT-154: Queue processing completed, ${_queue.length} activities remain for later');
    }
  }

  /// Process activity detection for a specific message and timestamp
  static Future<void> _processActivityDetection(
      String message, DateTime timestamp) async {
    try {
      // Get Oracle context for current persona
      final oracleContext = await OracleContextManager.getForCurrentPersona();
      if (oracleContext == null) {
        _logger.debug('FT-154: No Oracle context available for queued activity processing');
        return;
      }

      // Create a simple time context map for the timestamp
      final timeContext = {
        'timestamp': timestamp.toIso8601String(),
        'readableTime': _formatReadableTime(timestamp),
        'dayOfWeek': _getDayOfWeek(timestamp.weekday),
        'timeOfDay': _getTimeOfDay(timestamp.hour),
      };

      // Use semantic activity detector with time context
      final detectedActivities = await SemanticActivityDetector.analyzeWithTimeContext(
        userMessage: message,
        oracleContext: oracleContext,
        timeContext: timeContext,
      );

      // FT-163: Save detected activities to database
      if (detectedActivities.isNotEmpty) {
        _logger.info('FT-154: Processed queued activity - ${detectedActivities.length} activities detected');
        
        for (final detection in detectedActivities) {
          try {
            _logger.debug('FT-154: Saving detected activity: ${detection.oracleCode} - ${detection.activityName}');
            
            // Get Oracle activity details for proper dimension
            final oracleActivity = await OracleContextManager.getActivityByCode(detection.oracleCode);
            if (oracleActivity == null) {
              _logger.warning('FT-154: Oracle activity not found for code: ${detection.oracleCode}');
              continue;
            }
            
            // Save activity using ActivityMemoryService.logActivity
            await ActivityMemoryService.logActivity(
              activityCode: detection.oracleCode,
              activityName: oracleActivity.description,
              dimension: oracleActivity.dimension,
              source: 'Oracle FT-154 Queue',
              confidence: _convertConfidenceToDouble(detection.confidence),
              durationMinutes: detection.durationMinutes,
              notes: detection.reasoning,
              metadata: detection.metadata,
            );
            
            _logger.info('FT-154: ✅ Successfully saved queued activity: ${detection.oracleCode}');
          } catch (e) {
            _logger.error('FT-154: Failed to save detected activity ${detection.oracleCode}: $e');
          }
        }
      } else {
        _logger.debug('FT-154: No activities detected in queued message');
      }
    } catch (e) {
      _logger.warning('FT-154: Error processing queued activity: $e');
      rethrow;
    }
  }

  /// Format timestamp into readable time string
  static String _formatReadableTime(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Get day of week name
  static String _getDayOfWeek(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  /// Get time of day description
  static String _getTimeOfDay(int hour) {
    if (hour < 6) return 'early morning';
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }

  /// Check if an error is a rate limit error
  static bool _isRateLimitError(dynamic error) {
    final errorStr = error.toString();
    return errorStr.contains('429') ||
        errorStr.contains('rate_limit_error') ||
        errorStr.contains('Rate limit exceeded');
  }

  /// Get current queue status for debugging
  static Map<String, dynamic> getQueueStatus() {
    return {
      'queueSize': _queue.length,
      'maxQueueSize': _maxQueueSize,
      'oldestActivity':
          _queue.isNotEmpty ? _queue.first.timestamp.toIso8601String() : null,
      'newestActivity':
          _queue.isNotEmpty ? _queue.last.timestamp.toIso8601String() : null,
    };
  }

  /// Clear the queue (for testing or emergency situations)
  static void clearQueue() {
    final clearedCount = _queue.length;
    _queue.clear();
    _logger.warning(
        'FT-154: Activity queue cleared, removed $clearedCount activities');
  }

  /// Get queue size for monitoring
  static int get queueSize => _queue.length;

  /// Check if queue is empty
  static bool get isEmpty => _queue.isEmpty;

  /// FT-163: Convert confidence level to numeric score
  static double _convertConfidenceToDouble(ConfidenceLevel confidence) {
    switch (confidence) {
      case ConfidenceLevel.high:
        return 0.9;
      case ConfidenceLevel.medium:
        return 0.7;
      case ConfidenceLevel.low:
        return 0.5;
    }
  }
}
