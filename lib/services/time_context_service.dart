import '../utils/logger.dart';

/// Enumeration of different time gaps between conversations
enum TimeGap {
  sameSession, // < 30 minutes
  recentBreak, // 30min - 4 hours
  today, // 4-24 hours
  yesterday, // 1-2 days
  thisWeek, // 2-7 days
  lastWeek, // 1-2 weeks
  longAgo // > 2 weeks
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
  static String getCurrentTimeContext() {
    try {
      final now = DateTime.now();
      final dayOfWeek = _getDayOfWeekName(now.weekday);
      final timeOfDay = _getTimeOfDay(now.hour);

      return 'Current context: It is $dayOfWeek $timeOfDay.';
    } catch (e) {
      _logger.error('Error generating current time context: $e');
      return ''; // Safe fallback
    }
  }

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
          gapDetails = ' (${daysAgo} day${daysAgo == 1 ? '' : 's'} ago)';
          break;
        case TimeGap.lastWeek:
          final daysAgo = difference.inDays;
          gapDetails = ' (${daysAgo} days ago)';
          break;
        case TimeGap.longAgo:
          final weeksAgo = (difference.inDays / 7).floor();
          gapDetails = ' (${weeksAgo} week${weeksAgo == 1 ? '' : 's'} ago)';
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
