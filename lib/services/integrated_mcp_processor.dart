import 'dart:async';
import '../utils/logger.dart';
import '../services/system_mcp_service.dart';
import '../services/activity_memory_service.dart';
import '../models/activity_model.dart';
import 'semantic_activity_detector.dart';
import 'oracle_context_manager.dart';

/// FT-064: Integrated MCP processor coordinates FT-060 + FT-061
///
/// Combines time awareness (FT-060) with semantic activity detection:
/// - Single coordinated workflow for time + activity detection
/// - Precise activity timestamps using FT-060 infrastructure
/// - Enhanced activity storage with time context
/// - Graceful degradation when components fail
/// - FT-119: Queue processing for rate limit recovery
class IntegratedMCPProcessor {
  static Timer? _queueProcessingTimer;

  /// FT-119: Start background queue processing
  static void startQueueProcessing() {
    // Process queue every 3 minutes
    _queueProcessingTimer?.cancel();
    _queueProcessingTimer = Timer.periodic(Duration(minutes: 3), (_) async {
      try {
        await ActivityQueue.processQueue();
      } catch (e) {
        Logger().warning('FT-119: Queue processing error: $e');
      }
    });
    Logger()
        .info('FT-119: Started background queue processing (3min intervals)');
  }

  /// FT-119: Stop background queue processing
  static void stopQueueProcessing() {
    _queueProcessingTimer?.cancel();
    _queueProcessingTimer = null;
    Logger().info('FT-119: Stopped background queue processing');
  }

  /// Process time and activity detection in coordinated workflow
  ///
  /// This is the main entry point for FT-064's two-pass processing:
  /// 1. Get Oracle context (FT-061/062)
  /// 2. Get precise time context (FT-060)
  /// 3. Semantic activity detection with time context
  /// 4. Store with integrated time + activity data
  static Future<void> processTimeAndActivity({
    required String userMessage,
    required String claudeResponse,
  }) async {
    try {
      Logger().debug('FT-064: Starting integrated time + activity processing');

      // Step 1: Check Oracle context (graceful early exit for non-Oracle personas)
      final oracleContext = await OracleContextManager.getForCurrentPersona();
      if (oracleContext == null) {
        Logger().debug(
            'FT-064: No Oracle context - skipping activity detection for non-Oracle persona');
        return;
      }

      Logger().debug(
          'FT-064: Oracle context loaded: ${oracleContext.totalActivities} activities available');

      // Step 2: Get precise time context using FT-060 infrastructure
      final timeData = await _getCurrentTimeData();
      Logger()
          .debug('FT-064: Time context retrieved: ${timeData['readableTime']}');

      // Step 3: Semantic activity detection with time context
      // FT-086: Only analyze user message to prevent false positives from assistant responses
      final detectedActivities =
          await SemanticActivityDetector.analyzeWithTimeContext(
        userMessage: userMessage,
        oracleContext: oracleContext,
        timeContext: timeData,
      );

      if (detectedActivities.isEmpty) {
        Logger().debug('FT-064: No activities detected');
        return;
      }

      // Step 4: Store activities with precise time integration
      await _logActivitiesWithPreciseTime(
        activities: detectedActivities,
        timeContext: timeData,
        userMessage:
            userMessage, // FT-149: Pass user message for metadata extraction
      );

      Logger().info(
          'FT-064: ✅ Successfully processed ${detectedActivities.length} activities');
    } catch (e) {
      Logger().debug('FT-064: Integrated processing failed silently: $e');

      // FT-119: Queue activity if failure is due to rate limiting
      if (e.toString().contains('429') ||
          e.toString().contains('rate_limit') ||
          e.toString().contains('Rate limit')) {
        ActivityQueue.queueActivity(userMessage, DateTime.now());
        Logger().debug('FT-119: Activity queued due to rate limit');
      }

      // Graceful degradation - conversation continues uninterrupted
    }
  }

  /// Get current time data using FT-060 infrastructure
  static Future<Map<String, dynamic>> _getCurrentTimeData() async {
    try {
      // Use existing FT-060 SystemMCPService for time data
      const timeCommand = '{"action":"get_current_time"}';
      Logger().debug('FT-064: Getting time data via SystemMCP');

      final systemMCPService = SystemMCPService();
      final timeResponse = await systemMCPService.processCommand(timeCommand);

      if (timeResponse.startsWith('{"status":"success"')) {
        // Parse and return time data
        final timeData = <String, dynamic>{
          'timestamp': DateTime.now().toIso8601String(),
          'readableTime': 'Current time context',
          'timezone': DateTime.now().timeZoneOffset.inHours.toString(),
        };

        Logger().debug('FT-064: Time data retrieved successfully');
        return timeData;
      }

      throw Exception('Invalid time response format');
    } catch (e) {
      Logger().debug('FT-064: Failed to get time data, using fallback: $e');

      // Fallback time data
      final now = DateTime.now();
      return {
        'timestamp': now.toIso8601String(),
        'readableTime': 'Current time (fallback)',
        'timezone': now.timeZoneOffset.inHours.toString(),
        'hour': now.hour,
        'minute': now.minute,
        'dayOfWeek': _getDayOfWeek(now.weekday),
        'timeOfDay': _getTimeOfDay(now.hour),
      };
    }
  }

  /// Store activities with precise time context using FT-061 infrastructure
  static Future<void> _logActivitiesWithPreciseTime({
    required List<ActivityDetection> activities,
    required Map<String, dynamic> timeContext,
    String? userMessage, // FT-149: For metadata extraction context
  }) async {
    try {
      Logger().debug(
          'FT-064: Storing ${activities.length} activities with time context');

      for (final detection in activities) {
        // Skip low confidence detections to avoid false positives
        if (detection.confidence == ConfidenceLevel.low) {
          Logger().debug(
              'FT-064: Skipping low confidence detection: ${detection.oracleCode}');
          continue;
        }

        // Get Oracle activity details
        final oracleActivity =
            await OracleContextManager.getActivityByCode(detection.oracleCode);
        if (oracleActivity == null) {
          Logger().debug(
              'FT-064: Oracle activity not found for code: ${detection.oracleCode}');
          continue;
        }

        // Create ActivityModel using proper constructor
        final activity = ActivityModel.fromDetection(
          activityCode: detection.oracleCode,
          activityName: oracleActivity.description,
          dimension: oracleActivity.dimension,
          source: 'Oracle FT-064 Semantic',
          completedAt: detection.timestamp,
          dayOfWeek: _getDayOfWeek(detection.timestamp.weekday),
          timeOfDay: _getTimeOfDay(detection.timestamp.hour),
          durationMinutes: detection.durationMinutes,
          notes: detection.reasoning,
          confidenceScore: _convertConfidenceToDouble(detection.confidence),
        );

        // Set FT-064 specific fields
        activity.userDescription = detection.userDescription;
        activity.confidence = detection.confidence.name;
        activity.reasoning = detection.reasoning;
        activity.detectionMethod = 'semantic_ft064';
        activity.timeContext = timeContext['readableTime'] as String? ?? '';

        // FT-149.6: Set metadata directly if available from integrated detection
        if (detection.metadata != null) {
          activity.metadataMap = detection.metadata;
          Logger().debug(
              'FT-149.6: ✅ Set integrated metadata for ${activity.activityName}: ${detection.metadata!.keys}');
        }

        // Store using existing FT-061 ActivityMemoryService
        await ActivityMemoryService.logActivity(
          activityCode: activity.activityCode,
          activityName: activity.activityName,
          dimension: activity.dimension,
          source: activity.source,
          durationMinutes: activity.durationMinutes,
          notes: activity.notes,
          confidence: activity.confidenceScore,
          // FT-149.6: Pass context for fallback metadata extraction (only if no integrated metadata)
          userMessage: detection.metadata == null ? userMessage : null,
          oracleActivityName:
              detection.metadata == null ? oracleActivity.description : null,
        );

        Logger().info(
            'FT-064: ✅ Stored activity: ${detection.oracleCode} (${detection.confidence.name} confidence)');
      }
    } catch (e) {
      Logger().debug('FT-064: Failed to store activities: $e');
      // Continue gracefully - detection succeeded even if storage failed
    }
  }

  /// Get current activity detection status for debugging
  static Future<Map<String, dynamic>> getDetectionStatus() async {
    try {
      final oracleInfo = await OracleContextManager.getDebugInfo();
      final isOracleCompatible =
          await OracleContextManager.isCurrentPersonaOracleCompatible();

      return {
        'ft064_enabled': true,
        'oracle_compatible': isOracleCompatible,
        'oracle_info': oracleInfo,
        'detection_method': 'semantic_claude',
        'fallback_available': true,
      };
    } catch (e) {
      return {
        'ft064_enabled': false,
        'error': e.toString(),
      };
    }
  }

  // Helper methods for time formatting and confidence conversion
  static String _getDayOfWeek(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  static String _getTimeOfDay(int hour) {
    if (hour < 6) return 'early morning';
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }

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
