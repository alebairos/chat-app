import 'dart:convert';
import '../utils/logger.dart';
import 'system_mcp_service.dart';

/// Enumeration of different time gaps between conversations
enum TimeGap {
  sameSession, // < 30 minutes
  recentBreak, // 30min - 4 hours
  today, // 4-24 hours
  yesterday, // 1-2 days
  thisWeek, // 2-7 days
  lastWeek, // 1-2 weeks
  longAgo, // > 2 weeks
}

/// Service for generating time-aware conversation context
///
/// This service analyzes time gaps between conversations and generates
/// appropriate contextual information to inject into AI system prompts,
/// creating the perception of temporal memory and continuity.
class TimeContextService {
  static final Logger _logger = Logger();

  /// Template strings for different time gap contexts
  static const Map<TimeGap, String> _contextTemplates = {
    TimeGap.sameSession: '',
    TimeGap.recentBreak: 'Note: Conversation resuming after a short break.',
    TimeGap.today: 'Note: Conversation resuming later today.',
    TimeGap.yesterday: 'Note: Conversation resuming from yesterday.',
    TimeGap.thisWeek: 'Note: Conversation resuming from earlier this week.',
    TimeGap.lastWeek: 'Note: Conversation resuming from last week.',
    TimeGap.longAgo:
        'Note: Conversation resuming after a significant time gap.',
  };

  /// Day of week names for current time context
  static const Map<int, String> _dayNames = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  /// Calculate the time gap category between last message and now
  ///
  /// [lastMessageTime] - Timestamp of the last message in conversation
  /// Returns [TimeGap] enum representing the time category
  static TimeGap calculateTimeGap(DateTime lastMessageTime) {
    try {
      final now = DateTime.now();
      final difference = now.difference(lastMessageTime);

      if (difference.inMinutes < 30) {
        return TimeGap.sameSession;
      } else if (difference.inHours < 4) {
        return TimeGap.recentBreak;
      } else if (difference.inDays == 0) {
        return TimeGap.today;
      } else if (difference.inDays == 1) {
        return TimeGap.yesterday;
      } else if (difference.inDays <= 7) {
        return TimeGap.thisWeek;
      } else if (difference.inDays <= 14) {
        return TimeGap.lastWeek;
      } else {
        return TimeGap.longAgo;
      }
    } catch (e) {
      _logger.error('Error calculating time gap: $e');
      return TimeGap.sameSession; // Safe fallback
    }
  }

  /// Generate time-aware context string for system prompt injection
  ///
  /// [lastMessageTime] - Optional timestamp of last message. If null,
  /// only current time context is generated.
  ///
  /// Returns a formatted string with temporal context information
  static String generateTimeContext(DateTime? lastMessageTime) {
    try {
      final contextParts = <String>[];

      // Add time gap context if we have a previous message
      if (lastMessageTime != null) {
        final timeGap = calculateTimeGap(lastMessageTime);
        final gapContext = _contextTemplates[timeGap];
        if (gapContext != null && gapContext.isNotEmpty) {
          contextParts.add(gapContext);
        }
      }

      // Add current time context
      final currentContext = getCurrentTimeContext();
      if (currentContext.isNotEmpty) {
        contextParts.add(currentContext);
      }

      // Join all context parts with newlines
      return contextParts.join('\n');
    } catch (e) {
      _logger.error('Error generating time context: $e');
      return ''; // Safe fallback - no context added
    }
  }

  /// Get current day and time period context
  ///
  /// Returns a string with current day of week and time period
  /// Example: "Current context: It is Wednesday afternoon."
  /// Note: This method is deprecated, use the enhanced version below

  /// Get human-readable day of week name
  ///
  /// [weekday] - Dart DateTime weekday (1=Monday, 7=Sunday)
  /// Returns the day name string
  static String _getDayOfWeekName(int weekday) {
    return _dayNames[weekday] ?? 'today';
  }

  /// Determine time of day period from hour
  ///
  /// [hour] - 24-hour format hour (0-23)
  /// Returns period string (morning, afternoon, evening, night)
  static String _getTimeOfDay(int hour) {
    if (hour >= 5 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 17) {
      return 'afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'evening';
    } else {
      return 'night';
    }
  }

  /// Generate current time context string
  ///
  /// Returns formatted string with current day, time, and period information
  static String getCurrentTimeContext() {
    try {
      final now = DateTime.now();
      final dayName = _getDayOfWeekName(now.weekday);
      final timeOfDay = _getTimeOfDay(now.hour);
      final time12Hour = _formatTime12Hour(now.hour, now.minute);

      return 'Current context: It is $dayName at $time12Hour ($timeOfDay).';
    } catch (e) {
      _logger.error('Error generating current time context: $e');
      return 'Current context: It is ${_getDayOfWeekName(DateTime.now().weekday)}.';
    }
  }

  /// Enhanced time context generation with conversation gap details
  ///
  /// This method provides more detailed context for longer time gaps,
  /// useful for future enhancements but not included in Phase 1.
  ///
  /// [lastMessageTime] - Timestamp of last message
  /// [includeGapDetails] - Whether to include detailed gap information
  ///
  /// Returns enhanced context string with gap details
  static String generateEnhancedTimeContext(
    DateTime? lastMessageTime, {
    bool includeGapDetails = false,
  }) {
    try {
      final basicContext = generateTimeContext(lastMessageTime);

      if (!includeGapDetails || lastMessageTime == null) {
        return basicContext;
      }

      final now = DateTime.now();
      final difference = now.difference(lastMessageTime);
      final gap = calculateTimeGap(lastMessageTime);

      // Add detailed gap information for longer periods
      String gapDetails = '';
      switch (gap) {
        case TimeGap.thisWeek:
          final daysAgo = difference.inDays;
          gapDetails = ' ($daysAgo day${daysAgo == 1 ? '' : 's'} ago)';
          break;
        case TimeGap.lastWeek:
          final daysAgo = difference.inDays;
          gapDetails = ' ($daysAgo days ago)';
          break;
        case TimeGap.longAgo:
          final weeksAgo = (difference.inDays / 7).floor();
          gapDetails = ' ($weeksAgo week${weeksAgo == 1 ? '' : 's'} ago)';
          break;
        default:
          // No additional details for shorter gaps
          break;
      }

      return basicContext + gapDetails;
    } catch (e) {
      _logger.error('Error generating enhanced time context: $e');
      return generateTimeContext(lastMessageTime); // Fallback to basic context
    }
  }

  /// Generate enhanced time context with precise calculations
  ///
  /// This method integrates with SystemMCP get_current_time for precise
  /// time calculations when gaps are >= 4 hours (FT-060 enhancement).
  ///
  /// [lastMessageTime] - Optional timestamp of last message
  /// Returns enhanced context string with precise durations and current time
  static Future<String> generatePreciseTimeContext(
      DateTime? lastMessageTime) async {
    try {
      _logger.debug('FT-060: Generating precise time context');

      // Get precise current time data from SystemMCP
      final currentTimeData = await _getCurrentTimeData();
      if (currentTimeData == null) {
        _logger.warning(
          'FT-060: Could not get current time data, falling back to basic context',
        );
        return generateTimeContext(lastMessageTime);
      }

      if (lastMessageTime == null) {
        return _formatEnhancedCurrentTimeContext(currentTimeData);
      }

      final gap = calculateTimeGap(lastMessageTime);

      // Use precise calculations for longer gaps (>= 4 hours)
      if (_shouldUsePreciseCalculations(gap)) {
        _logger.info('FT-060: 🎯 Using PRECISE time context for gap: $gap');
        return _generatePreciseGapContext(lastMessageTime, currentTimeData);
      }

      // Use enhanced context even for short gaps to ensure full date is included
      _logger.debug(
        'FT-060: 📝 Using ENHANCED time context for gap: $gap (< 4 hours)',
      );
      return _formatEnhancedCurrentTimeContext(currentTimeData);
    } catch (e) {
      _logger.error('FT-060: Error generating precise time context: $e');
      return generateTimeContext(lastMessageTime); // Safe fallback
    }
  }

  /// Determine if precise calculations should be used for the time gap
  ///
  /// [gap] - The calculated time gap
  /// Returns true if gap warrants precise duration calculations
  static bool _shouldUsePreciseCalculations(TimeGap gap) {
    return gap == TimeGap.recentBreak ||
        gap == TimeGap.today ||
        gap == TimeGap.yesterday ||
        gap == TimeGap.thisWeek ||
        gap == TimeGap.lastWeek ||
        gap == TimeGap.longAgo;
  }

  /// Get current time data from SystemMCP service
  ///
  /// Returns parsed time data map or null if unavailable
  static Future<Map<String, dynamic>?> _getCurrentTimeData() async {
    try {
      final mcpService = SystemMCPService.instance;
      final response = await mcpService.processCommand(
        '{"action":"get_current_time"}',
      );

      // Log the complete raw response
      _logger.debug('FT-060: get_current_time raw response: $response');

      final decoded = json.decode(response);

      if (decoded['status'] == 'success') {
        final timeData = decoded['data'] as Map<String, dynamic>;

        // Log the structured time data for visibility
        _logger.info('FT-060: ⏰ Current time data retrieved:');
        _logger.info(
          '  📅 Date: ${timeData['dayOfWeek']}, ${timeData['readableTime']}',
        );
        _logger.info(
          '  🕐 Time: ${timeData['hour']}:${timeData['minute'].toString().padLeft(2, '0')}:${timeData['second'].toString().padLeft(2, '0')} (${timeData['timeOfDay']})',
        );
        _logger.info('  🌍 Timezone: ${timeData['timezone']}');
        _logger.info('  📊 Unix timestamp: ${timeData['unixTimestamp']}');
        _logger.info('  🔧 ISO8601: ${timeData['iso8601']}');

        return timeData;
      } else {
        _logger.warning(
          'FT-060: SystemMCP get_current_time returned error: ${decoded['message']}',
        );
        return null;
      }
    } catch (e) {
      _logger.error('FT-060: Error getting current time data: $e');
      return null;
    }
  }

  /// Generate precise gap context using exact duration calculations
  ///
  /// [lastMessageTime] - Timestamp of last message
  /// [currentTimeData] - Current time data from SystemMCP
  /// Returns formatted context with precise duration and current time
  static String _generatePreciseGapContext(
    DateTime lastMessageTime,
    Map<String, dynamic> currentTimeData,
  ) {
    try {
      final now = DateTime.parse(currentTimeData['timestamp']);
      final difference = now.difference(lastMessageTime);
      final gap = calculateTimeGap(lastMessageTime);

      final contextParts = <String>[];

      // Add precise gap context
      final baseContext = _contextTemplates[gap] ?? '';
      if (baseContext.isNotEmpty) {
        final preciseDuration = _formatPreciseDuration(difference);
        final enhancedContext = baseContext.replaceFirst(
          '.',
          ' ($preciseDuration ago).',
        );
        contextParts.add(enhancedContext);
      }

      // Add enhanced current time context
      final currentContext = _formatEnhancedCurrentTimeContext(currentTimeData);
      if (currentContext.isNotEmpty) {
        contextParts.add(currentContext);
      }

      return contextParts.join('\n');
    } catch (e) {
      _logger.error('FT-060: Error generating precise gap context: $e');
      return generateTimeContext(lastMessageTime); // Safe fallback
    }
  }

  /// Format enhanced current time context with precise time
  ///
  /// [timeData] - Current time data from SystemMCP
  /// Returns formatted current time context with exact time
  static String _formatEnhancedCurrentTimeContext(
    Map<String, dynamic> timeData,
  ) {
    try {
      // Use the full readableTime from MCP which includes the complete date
      final readableTime = timeData['readableTime'] as String?;
      if (readableTime != null && readableTime.isNotEmpty) {
        return 'Current context: Today is $readableTime.';
      }

      // Fallback to basic format if readableTime is not available
      final dayOfWeek = timeData['dayOfWeek'] as String;
      final hour = timeData['hour'] as int;
      final minute = timeData['minute'] as int;

      // Format as "It is Wednesday at 2:47 PM."
      final timeString = _formatTime12Hour(hour, minute);
      return 'Current context: It is $dayOfWeek at $timeString.';
    } catch (e) {
      _logger.error(
        'FT-060: Error formatting enhanced current time context: $e',
      );
      return getCurrentTimeContext(); // Fallback to basic context
    }
  }

  /// Format precise duration in human-readable format
  ///
  /// [duration] - Duration to format
  /// Returns formatted duration string (e.g., "2 days and 3 hours")
  static String _formatPreciseDuration(Duration duration) {
    if (duration.inDays >= 1) {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      if (hours > 0) {
        return '$days day${days == 1 ? '' : 's'} and $hours hour${hours == 1 ? '' : 's'}';
      } else {
        return '$days day${days == 1 ? '' : 's'}';
      }
    } else if (duration.inHours >= 1) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '$hours hour${hours == 1 ? '' : 's'} and $minutes minute${minutes == 1 ? '' : 's'}';
      } else {
        return '$hours hour${hours == 1 ? '' : 's'}';
      }
    } else {
      final minutes = duration.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }
  }

  /// Format time in 12-hour format with AM/PM
  ///
  /// [hour] - 24-hour format hour (0-23)
  /// [minute] - Minute (0-59)
  /// Returns formatted time string (e.g., "2:47 PM")
  static String _formatTime12Hour(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteString = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteString $period';
  }

  /// Validate and sanitize timestamp input
  ///
  /// [timestamp] - Timestamp to validate
  /// Returns validated timestamp or null if invalid
  static DateTime? validateTimestamp(DateTime? timestamp) {
    if (timestamp == null) return null;

    final now = DateTime.now();

    // Reject future timestamps (more than 1 minute in future to account for clock skew)
    if (timestamp.isAfter(now.add(const Duration(minutes: 1)))) {
      _logger.warning('Rejecting future timestamp: $timestamp');
      return null;
    }

    // Reject extremely old timestamps (more than 1 year ago)
    if (timestamp.isBefore(now.subtract(const Duration(days: 365)))) {
      _logger.warning('Rejecting very old timestamp: $timestamp');
      return null;
    }

    return timestamp;
  }

  /// Generate debug information about time gap calculation
  ///
  /// [lastMessageTime] - Timestamp to analyze
  /// Returns map with debug information
  static Map<String, dynamic> getTimeGapDebugInfo(DateTime? lastMessageTime) {
    if (lastMessageTime == null) {
      return {
        'hasLastMessage': false,
        'timeGap': null,
        'context': getCurrentTimeContext(),
      };
    }

    final now = DateTime.now();
    final difference = now.difference(lastMessageTime);
    final gap = calculateTimeGap(lastMessageTime);

    return {
      'hasLastMessage': true,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'currentTime': now.toIso8601String(),
      'differenceMinutes': difference.inMinutes,
      'differenceHours': difference.inHours,
      'differenceDays': difference.inDays,
      'timeGap': gap.toString(),
      'context': generateTimeContext(lastMessageTime),
    };
  }
}
