import 'package:isar/isar.dart';
import '../models/activity_model.dart';

import '../services/oracle_activity_parser.dart';
import '../utils/logger.dart';

/// Service for managing activity memory storage and retrieval
class ActivityMemoryService {
  static final Logger _logger = Logger();
  static Isar? _isar;

  /// Initialize the service with Isar instance
  static void initialize(Isar isar) {
    _isar = isar;
    _logger.info('ActivityMemoryService initialized');
  }

  /// Ensure Isar is initialized
  static Isar get _database {
    if (_isar == null) {
      throw StateError(
          'ActivityMemoryService not initialized. Call initialize() first.');
    }
    return _isar!;
  }

  /// Log a detected activity with precise timestamp
  static Future<ActivityModel> logActivity({
    required String? activityCode,
    required String activityName,
    required String dimension,
    required String source,
    int? durationMinutes,
    String? notes,
    double confidence = 1.0,
  }) async {
    try {
      // Get precise time data from FT-060
      final now = DateTime.now();
      final dayOfWeek = _getDayOfWeek(now.weekday);
      final timeOfDay = _getTimeOfDay(now.hour);

      final activity = ActivityModel.fromDetection(
        activityCode: activityCode,
        activityName: activityName,
        dimension: dimension,
        source: source,
        completedAt: now,
        dayOfWeek: dayOfWeek,
        timeOfDay: timeOfDay,
        durationMinutes: durationMinutes,
        notes: notes,
        confidenceScore: confidence,
      );

      await _database.writeTxn(() async {
        await _database.activityModels.put(activity);
      });

      _logger.info(
          'Logged activity: ${activity.description} at ${activity.formattedTime} (confidence: $confidence)');
      return activity;
    } catch (e) {
      _logger.error('Failed to log activity: $e');
      rethrow;
    }
  }

  /// Log multiple activities from AI detection
  static Future<List<ActivityModel>> logActivities(
      List<Map<String, dynamic>> detectedActivities) async {
    final results = <ActivityModel>[];

    for (final detected in detectedActivities) {
      try {
        final activity = await logActivity(
          activityCode: detected['code'] as String?,
          activityName: detected['name'] as String,
          dimension: detected['dimension'] as String? ?? 'custom',
          source: detected['source'] as String? ?? 'AI Detection',
          durationMinutes: detected['duration_minutes'] as int?,
          notes: detected['notes'] as String?,
          confidence: (detected['confidence'] as num?)?.toDouble() ?? 1.0,
        );

        results.add(activity);
      } catch (e) {
        _logger
            .error('Failed to log detected activity ${detected['name']}: $e');
      }
    }

    _logger.info(
        'Logged ${results.length}/${detectedActivities.length} detected activities');
    return results;
  }

  /// Get recent activities for the last N days
  static Future<List<ActivityModel>> getRecentActivities(int days) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final activities = await _database.activityModels
          .where()
          .filter()
          .completedAtGreaterThan(cutoffDate)
          .findAll();
      activities.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      _logger.debug(
          'Retrieved ${activities.length} activities from last $days days');
      return activities;
    } catch (e) {
      _logger.error('Failed to get recent activities: $e');
      return [];
    }
  }

  /// Get activities by dimension
  static Future<List<ActivityModel>> getActivitiesByDimension(
      String dimension) async {
    try {
      final activities = await _database.activityModels
          .where()
          .filter()
          .dimensionEqualTo(dimension)
          .findAll();
      activities.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      _logger.debug(
          'Retrieved ${activities.length} activities for dimension: $dimension');
      return activities;
    } catch (e) {
      _logger.error('Failed to get activities by dimension $dimension: $e');
      return [];
    }
  }

  /// Get activities by Oracle code
  static Future<List<ActivityModel>> getActivitiesByCode(String code) async {
    try {
      final activities = await _database.activityModels
          .where()
          .filter()
          .activityCodeEqualTo(code)
          .findAll();
      activities.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      _logger
          .debug('Retrieved ${activities.length} activities for code: $code');
      return activities;
    } catch (e) {
      _logger.error('Failed to get activities by code $code: $e');
      return [];
    }
  }

  /// Get activities completed today
  static Future<List<ActivityModel>> getTodayActivities() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final activities = await _database.activityModels
          .where()
          .filter()
          .completedAtBetween(startOfDay, endOfDay)
          .findAll();
      activities.sort((a, b) => a.completedAt.compareTo(b.completedAt));
      _logger.debug('Retrieved ${activities.length} activities for today');
      return activities;
    } catch (e) {
      _logger.error('Failed to get today activities: $e');
      return [];
    }
  }

  /// Generate activity summary for context injection
  static Future<String> generateActivityContext({int days = 7}) async {
    try {
      final oracleResult = await OracleActivityParser.parseFromPersona();
      final recentActivities = await getRecentActivities(days);

      final buffer = StringBuffer();

      // Oracle framework info
      if (oracleResult.isNotEmpty) {
        buffer.writeln('Oracle Framework (${oracleResult.sourceFileName}):');

        // Group activities by dimension
        final dimensionCounts = <String, int>{};
        for (final dimension in oracleResult.dimensions.values) {
          final count = oracleResult.activities.values
              .where((a) => a.dimension == dimension.code)
              .length;
          dimensionCounts[dimension.displayName] = count;
        }

        for (final entry in dimensionCounts.entries) {
          buffer.writeln('• ${entry.key}: ${entry.value} activities available');
        }
        buffer.writeln();
      }

      // Recent activity summary
      if (recentActivities.isNotEmpty) {
        buffer.writeln('Recent Activity Memory ($days days):');

        // Group by dimension
        final byDimension = <String, List<ActivityModel>>{};
        for (final activity in recentActivities) {
          byDimension.putIfAbsent(activity.dimension, () => []).add(activity);
        }

        for (final entry in byDimension.entries) {
          final dimensionName = oracleResult.dimensions.values
              .firstWhere((d) => d.id == entry.key,
                  orElse: () => DimensionDefinition(
                        id: entry.key,
                        code: entry.key.toUpperCase(),
                        fullName: entry.key.toUpperCase(),
                        displayName: entry.key
                            .replaceAll('_', ' ')
                            .split(' ')
                            .map((w) => w.isEmpty
                                ? w
                                : w[0].toUpperCase() + w.substring(1))
                            .join(' '),
                      ))
              .displayName;

          buffer.writeln('• $dimensionName: ${entry.value.length} activities');

          // Show most frequent activities
          final activityCounts = <String, int>{};
          for (final activity in entry.value) {
            final key = activity.isOracleActivity
                ? activity.activityCode!
                : activity.activityName;
            activityCounts[key] = (activityCounts[key] ?? 0) + 1;
          }

          final topActivities = activityCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value))
            ..take(3);

          for (final activityEntry in topActivities) {
            buffer.writeln('  - ${activityEntry.key}: ${activityEntry.value}x');
          }
        }

        // Smart insights
        buffer.writeln('\nSmart Insights:');
        final insights =
            _generateActivityInsights(recentActivities, oracleResult);
        buffer.writeln(insights);
      } else {
        buffer.writeln('No recent activities recorded.');
      }

      return buffer.toString();
    } catch (e) {
      _logger.error('Failed to generate activity context: $e');
      return '';
    }
  }

  /// Generate smart insights from activity patterns
  static String _generateActivityInsights(
      List<ActivityModel> activities, OracleParseResult oracleResult) {
    final insights = <String>[];

    try {
      if (activities.isEmpty) {
        return 'No activity patterns to analyze yet.';
      }

      // Analyze time patterns
      final timePatterns = <String, List<ActivityModel>>{};
      for (final activity in activities) {
        timePatterns.putIfAbsent(activity.timeOfDay, () => []).add(activity);
      }

      final mostActiveTime = timePatterns.entries
          .reduce((a, b) => a.value.length > b.value.length ? a : b);

      insights.add(
          'Peak activity time: ${mostActiveTime.key} (${mostActiveTime.value.length} activities)');

      // Analyze streaks for Oracle activities
      if (oracleResult.isNotEmpty) {
        final oracleActivities =
            activities.where((a) => a.isOracleActivity).toList();
        final streaks = _calculateStreaks(oracleActivities);

        if (streaks.isNotEmpty) {
          final longestStreak =
              streaks.reduce((a, b) => a['days'] > b['days'] ? a : b);
          insights.add(
              'Longest streak: ${longestStreak['activity']} (${longestStreak['days']} days)');
        }
      }

      // Analyze consistency
      final today = DateTime.now();
      final todayActivities = activities
          .where((a) =>
              a.completedAt.day == today.day &&
              a.completedAt.month == today.month &&
              a.completedAt.year == today.year)
          .length;

      if (todayActivities > 0) {
        insights.add('Today: $todayActivities activities completed');
      }

      // Find gaps for important Oracle activities
      if (oracleResult.isNotEmpty) {
        final importantCodes = ['SF1', 'SM1', 'T8']; // Water, meditation, focus
        for (final code in importantCodes) {
          final lastActivity =
              activities.where((a) => a.activityCode == code).isNotEmpty
                  ? activities.where((a) => a.activityCode == code).first
                  : null;

          if (lastActivity != null) {
            final daysSince =
                DateTime.now().difference(lastActivity.completedAt).inDays;
            if (daysSince > 1) {
              final activityDef = oracleResult.activities[code];
              if (activityDef != null) {
                insights.add(
                    'Gap: ${activityDef.name} last done $daysSince days ago');
              }
            }
          }
        }
      }
    } catch (e) {
      _logger.error('Failed to generate insights: $e');
      insights.add('Insights temporarily unavailable');
    }

    return insights.join('\n- ');
  }

  /// Calculate activity streaks
  static List<Map<String, dynamic>> _calculateStreaks(
      List<ActivityModel> activities) {
    final streaks = <Map<String, dynamic>>[];

    try {
      final groupedByCode = <String?, List<ActivityModel>>{};
      for (final activity in activities) {
        groupedByCode
            .putIfAbsent(activity.activityCode, () => [])
            .add(activity);
      }

      for (final entry in groupedByCode.entries) {
        if (entry.key == null) continue;

        final sortedActivities = entry.value
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
        int currentStreak = 0;
        DateTime? lastDate;

        for (final activity in sortedActivities) {
          final activityDate = DateTime(
            activity.completedAt.year,
            activity.completedAt.month,
            activity.completedAt.day,
          );

          if (lastDate == null ||
              lastDate.difference(activityDate).inDays == 1) {
            currentStreak++;
            lastDate = activityDate;
          } else {
            break;
          }
        }

        if (currentStreak > 1) {
          streaks.add({
            'activity': entry.key,
            'days': currentStreak,
          });
        }
      }
    } catch (e) {
      _logger.error('Failed to calculate streaks: $e');
    }

    return streaks;
  }

  /// Get comprehensive activity statistics (FT-068/FT-066)
  /// This method serves both MCP commands and Stats UI
  static Future<Map<String, dynamic>> getActivityStats({int days = 1}) async {
    try {
      // Calculate date range
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1));

      // Get activities in timeframe
      final activities = await _database.activityModels
          .filter()
          .completedAtBetween(startDate, now)
          .sortByCompletedAtDesc()
          .findAll();

      // Calculate summary statistics
      final summary = _calculateSummaryStats(activities);

      // Format activities for display
      final formattedActivities = activities
          .map((activity) => {
                'code': activity.activityCode,
                'name': activity.activityName,
                'time': _formatTime(activity.completedAt),
                'full_timestamp': activity.completedAt.toIso8601String(),
                'confidence': activity.confidence != null
                    ? double.tryParse(activity.confidence!) ?? 0.0
                    : 0.0,
                'dimension': activity.dimension,
                'source': activity.source,
                'notes': activity.notes,
              })
          .toList();

      return {
        'period': days == 1 ? 'today' : 'last_${days}_days',
        'total_activities': activities.length,
        'activities': formattedActivities,
        'summary': summary,
      };
    } catch (e) {
      _logger.error('Failed to get activity stats: $e');
      return {
        'period': days == 1 ? 'today' : 'last_${days}_days',
        'total_activities': 0,
        'activities': <Map<String, dynamic>>[],
        'summary': _getEmptySummary(),
      };
    }
  }

  /// Calculate summary statistics for activities
  static Map<String, dynamic> _calculateSummaryStats(
      List<ActivityModel> activities) {
    if (activities.isEmpty) return _getEmptySummary();

    // Group by dimension
    final Map<String, int> byDimension = {};
    final Map<String, int> byActivity = {};

    for (final activity in activities) {
      // Count by dimension
      byDimension[activity.dimension] =
          (byDimension[activity.dimension] ?? 0) + 1;

      // Count by activity code
      final code = activity.activityCode ?? 'unknown';
      byActivity[code] = (byActivity[code] ?? 0) + 1;
    }

    // Find most frequent activity
    String? mostFrequent;
    int maxFrequency = 0;
    byActivity.forEach((code, count) {
      if (count > maxFrequency) {
        maxFrequency = count;
        mostFrequent = code;
      }
    });

    // Calculate time range
    final sortedActivities = List<ActivityModel>.from(activities)
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    final timeRange = activities.length > 1
        ? '${_formatTime(sortedActivities.first.completedAt)} - ${_formatTime(sortedActivities.last.completedAt)}'
        : _formatTime(activities.first.completedAt);

    return {
      'by_dimension': byDimension,
      'by_activity': byActivity,
      'most_frequent': mostFrequent,
      'max_frequency': maxFrequency,
      'time_range': timeRange,
      'unique_activities': byActivity.length,
      'total_occurrences': activities.length,
    };
  }

  /// Get empty summary for error cases
  static Map<String, dynamic> _getEmptySummary() {
    return {
      'by_dimension': <String, int>{},
      'by_activity': <String, int>{},
      'most_frequent': null,
      'max_frequency': 0,
      'time_range': '',
      'unique_activities': 0,
      'total_occurrences': 0,
    };
  }

  /// Format time for display (HH:MM)
  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get total activity count
  static Future<int> getTotalActivityCount() async {
    try {
      return await _database.activityModels.count();
    } catch (e) {
      _logger.error('Failed to get total activity count: $e');
      return 0;
    }
  }

  /// Clear all activities (for testing)
  static Future<void> clearAllActivities() async {
    try {
      await _database.writeTxn(() async {
        await _database.activityModels.clear();
      });
      _logger.info('Cleared all activities');
    } catch (e) {
      _logger.error('Failed to clear activities: $e');
    }
  }

  /// Helper method to get day of week name
  static String _getDayOfWeek(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  /// Helper method to get time of day category
  static String _getTimeOfDay(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }
}
