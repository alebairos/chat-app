import 'package:isar/isar.dart';
import '../models/activity_model.dart';

import '../services/oracle_activity_parser.dart';
import '../utils/logger.dart';
import 'integrated_mcp_processor.dart';
import 'chat_storage_service.dart';

/// FT-119: Activity request for queuing during rate limits
class ActivityRequest {
  final String userMessage;
  final DateTime requestedAt;
  final int retryCount;

  ActivityRequest({
    required this.userMessage,
    required this.requestedAt,
    this.retryCount = 0,
  });

  /// Create a copy with incremented retry count
  ActivityRequest withRetry() {
    return ActivityRequest(
      userMessage: userMessage,
      requestedAt: requestedAt,
      retryCount: retryCount + 1,
    );
  }
}

/// FT-119: Activity queue for graceful degradation during rate limits
class ActivityQueue {
  static final List<ActivityRequest> _pendingActivities = [];
  static final Logger _logger = Logger();
  static const int _maxQueueSize = 20;
  static const int _maxRetries = 3;

  /// Queue an activity request for later processing
  static void queueActivity(String userMessage, DateTime requestTime) {
    // Prevent queue overflow
    if (_pendingActivities.length >= _maxQueueSize) {
      _logger.warning('FT-119: Activity queue full, removing oldest request');
      _pendingActivities.removeAt(0);
    }

    final request = ActivityRequest(
      userMessage: userMessage,
      requestedAt: requestTime,
    );

    _pendingActivities.add(request);
    _logger.info(
        'FT-119: Queued activity request (queue size: ${_pendingActivities.length})');
  }

  /// Check if there are pending activities
  static bool hasPendingActivities() {
    return _pendingActivities.isNotEmpty;
  }

  /// Get number of pending activities
  static int getPendingCount() {
    return _pendingActivities.length;
  }

  /// Process the activity queue (attempt to process oldest request)
  static Future<void> processQueue() async {
    if (_pendingActivities.isEmpty) return;

    final request = _pendingActivities.first;
    _logger.debug(
        'FT-119: Attempting to process queued activity (age: ${DateTime.now().difference(request.requestedAt).inMinutes}min)');

    try {
      // Try to process the activity
      final success = await _tryProcessActivity(request);

      if (success) {
        _pendingActivities.removeAt(0);
        _logger.info(
            'FT-119: Successfully processed queued activity (${_pendingActivities.length} remaining)');
      } else if (request.retryCount >= _maxRetries) {
        _pendingActivities.removeAt(0);
        _logger
            .warning('FT-119: Discarding activity after $_maxRetries retries');
      } else {
        // Update with retry count
        _pendingActivities[0] = request.withRetry();
        _logger.debug(
            'FT-119: Activity processing failed, will retry (attempt ${request.retryCount + 1}/$_maxRetries)');
      }
    } catch (e) {
      _logger.error('FT-119: Error processing activity queue: $e');
    }
  }

  /// Try to process a single activity request
  static Future<bool> _tryProcessActivity(ActivityRequest request) async {
    try {
      await IntegratedMCPProcessor.processTimeAndActivity(
        userMessage: request.userMessage,
        claudeResponse: '', // Empty response for queued processing
      );

      return true;
    } catch (e) {
      _logger.debug('FT-119: Activity processing failed: $e');
      return false;
    }
  }

  /// Get queue status for debugging
  static Map<String, dynamic> getQueueStatus() {
    return {
      'pendingCount': _pendingActivities.length,
      'maxQueueSize': _maxQueueSize,
      'oldestRequest': _pendingActivities.isNotEmpty
          ? _pendingActivities.first.requestedAt.toIso8601String()
          : null,
      'requests': _pendingActivities
          .map((req) => {
                'message': req.userMessage.length > 50
                    ? '${req.userMessage.substring(0, 50)}...'
                    : req.userMessage,
                'requestedAt': req.requestedAt.toIso8601String(),
                'retryCount': req.retryCount,
              })
          .toList(),
    };
  }

  /// Clear the queue (for testing or manual intervention)
  static void clearQueue() {
    final count = _pendingActivities.length;
    _pendingActivities.clear();
    _logger.info('FT-119: Cleared activity queue ($count requests removed)');
  }
}

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

  /// Check if the database is available and accessible
  static Future<bool> isDatabaseAvailable() async {
    try {
      print('🔍 ActivityMemoryService: Checking database availability...');

      if (_isar == null) {
        print('❌ ActivityMemoryService: _isar is null');
        return false;
      }

      print(
          '🔍 ActivityMemoryService: _isar instance exists, checking if open...');
      print('🔍 ActivityMemoryService: Isar name: ${_isar!.name}');
      print('🔍 ActivityMemoryService: Isar directory: ${_isar!.directory}');

      // Try to access the database to see if it's still open
      final count = await _isar!.activityModels.count();
      print('✅ ActivityMemoryService: Database available, count: $count');
      return true;
    } catch (e) {
      print('❌ ActivityMemoryService: Database not available: $e');
      print('🔍 ActivityMemoryService: Error type: ${e.runtimeType}');
      if (_isar != null) {
        print('🔍 ActivityMemoryService: Isar instance exists but threw error');
        print('🔍 ActivityMemoryService: Isar name: ${_isar!.name}');
      }
      _logger.warning('Database not available: $e');
      return false;
    }
  }

  /// Reinitialize the database connection if needed
  static Future<bool> ensureDatabaseConnection() async {
    print('🔄 ActivityMemoryService: ensureDatabaseConnection() called');

    if (await isDatabaseAvailable()) {
      print(
          '✅ ActivityMemoryService: Database already available, no reconnection needed');
      return true;
    }

    try {
      // Try to reinitialize with a fresh database connection
      print(
          '🔄 ActivityMemoryService: Attempting to reestablish database connection...');
      _logger.info('Attempting to reestablish database connection...');

      // Create a new ChatStorageService to get a fresh database connection
      print('🔄 ActivityMemoryService: Creating new ChatStorageService...');
      final storageService = ChatStorageService();

      print('🔄 ActivityMemoryService: Getting fresh database instance...');
      final freshIsar = await storageService.db;

      print('🔄 ActivityMemoryService: Fresh Isar instance obtained');
      print('🔍 ActivityMemoryService: Fresh Isar name: ${freshIsar.name}');
      print(
          '🔍 ActivityMemoryService: Fresh Isar directory: ${freshIsar.directory}');

      // Reinitialize with the fresh connection
      print(
          '🔄 ActivityMemoryService: Reinitializing with fresh connection...');
      _isar = freshIsar;

      // Test the new connection
      print('🔄 ActivityMemoryService: Testing new connection...');
      final isAvailable = await isDatabaseAvailable();
      if (isAvailable) {
        print(
            '✅ ActivityMemoryService: Successfully reestablished database connection');
        return true;
      } else {
        print(
            '❌ ActivityMemoryService: Failed to reestablish database connection');
        return false;
      }
    } catch (e) {
      print('❌ ActivityMemoryService: Exception during reconnection: $e');
      print('🔍 ActivityMemoryService: Exception type: ${e.runtimeType}');
      _logger.error('Failed to reestablish database connection: $e');
      return false;
    }
  }

  /// Try to reinitialize the database with a new Isar instance
  static Future<bool> reinitializeDatabase(Isar newIsar) async {
    try {
      print(
          '🔄 ActivityMemoryService: Attempting to reinitialize with new Isar instance...');
      _isar = newIsar;

      // Test the new connection
      final isAvailable = await isDatabaseAvailable();
      if (isAvailable) {
        print(
            '✅ ActivityMemoryService: Successfully reinitialized database connection');
        return true;
      } else {
        print(
            '❌ ActivityMemoryService: Failed to reinitialize database connection');
        return false;
      }
    } catch (e) {
      print(
          '❌ ActivityMemoryService: Error during database reinitialization: $e');
      return false;
    }
  }

  /// Ensure fresh database connection using proven Stats tab pattern
  /// This is the reliable approach that always works
  static Future<bool> ensureFreshConnection() async {
    try {
      print('🔄 ActivityMemoryService: Ensuring fresh database connection...');
      _logger
          .info('Ensuring fresh database connection using Stats tab pattern');

      // Use the same robust approach as Stats tab
      final storageService = ChatStorageService();
      final freshIsar = await storageService.db;

      print('✅ ActivityMemoryService: Fresh Isar instance obtained');
      final success = await reinitializeDatabase(freshIsar);

      if (success) {
        print(
            '✅ ActivityMemoryService: Fresh connection established successfully');
        return true;
      } else {
        print('❌ ActivityMemoryService: Failed to establish fresh connection');
        return false;
      }
    } catch (e) {
      print('❌ ActivityMemoryService: Error ensuring fresh connection: $e');
      _logger.error('Failed to ensure fresh connection: $e');
      return false;
    }
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
    Map<String, dynamic> metadata = const {},
    // FT-156: Message linking parameters
    String? sourceMessageId,
    String? sourceMessageText,
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
        metadata: metadata,
        // FT-156: Message linking
        sourceMessageId: sourceMessageId,
        sourceMessageText: sourceMessageText,
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
      final recentActivities = await getRecentActivities(days);

      // Only provide minimal context - no detailed lists
      if (recentActivities.isNotEmpty) {
        final activeDimensions =
            recentActivities.map((a) => a.dimension).toSet().length;

        final totalActivities = recentActivities.length;

        // Very minimal summary - just enough for context, not for display
        return 'Activity context: $totalActivities activities across $activeDimensions dimensions this week.';
      } else {
        return 'No recent activities recorded.';
      }
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
      print('🔍 ActivityMemoryService: getActivityStats called for $days days');

      // Check if database is available before proceeding
      final dbAvailable = await isDatabaseAvailable();
      if (!dbAvailable) {
        print(
            '❌ ActivityMemoryService: Database not available, returning empty stats');
        _logger.warning('Database not available, returning empty stats');
        return {
          'period': days == 0 ? 'today' : 'last_${days}_days',
          'total_activities': 0,
          'activities': <Map<String, dynamic>>[],
          'summary': _getEmptySummary(),
          'database_error': 'Database connection not available',
        };
      }

      print(
          '✅ ActivityMemoryService: Database available, proceeding with query');

      // Calculate date range (FT-083 fix + today support)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      late DateTime startDate;
      late DateTime queryEndDate;

      if (days == 0) {
        // Special case: Query today's activities only
        startDate = today;
        queryEndDate = now;
        print(
            '🔍 ActivityMemoryService: Querying TODAY\'s activities from ${startDate.toIso8601String()} to ${queryEndDate.toIso8601String()}');
      } else {
        // Query previous days (exclude today)
        startDate = today.subtract(Duration(days: days));
        final endDate = today.subtract(const Duration(days: 1));
        queryEndDate =
            DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
        print(
            '🔍 ActivityMemoryService: Querying PREVIOUS $days days from ${startDate.toIso8601String()} to ${queryEndDate.toIso8601String()}');
      }

      // Get activities in calculated timeframe
      final activities = await _database.activityModels
          .filter()
          .completedAtBetween(startDate, queryEndDate)
          .sortByCompletedAtDesc()
          .findAll();

      print('✅ ActivityMemoryService: Found ${activities.length} activities');

      // Calculate summary statistics
      final summary = _calculateSummaryStats(activities);

      // Format activities for display
      final formattedActivities = activities
          .map((activity) => {
                'code': activity.activityCode,
                'name': activity.activityName,
                'time': _formatTime(activity.completedAt),
                'full_timestamp': activity.completedAt.toIso8601String(),
                // FT-089: Fix confidence data bug - use confidenceScore field instead of parsing string
                'confidence': activity.confidenceScore,
                'dimension': activity.dimension,
                'source': activity.source,
                'notes': activity.notes,
                'metadata': activity.metadata,
                // FT-156: Message linking for coaching memory
                'source_message_id': activity.sourceMessageId,
                'source_message_text': activity.sourceMessageText,
              })
          .toList();

      print('✅ ActivityMemoryService: Returning stats for $days days');
      return {
        'period': days == 0 ? 'today' : 'last_${days}_days',
        'total_activities': activities.length,
        'activities': formattedActivities,
        'summary': summary,
      };
    } catch (e) {
      print('❌ ActivityMemoryService: Exception in getActivityStats: $e');
      _logger.error('Failed to get activity stats: $e');
      return {
        'period': days == 0 ? 'today' : 'last_${days}_days',
        'total_activities': 0,
        'activities': <Map<String, dynamic>>[],
        'summary': _getEmptySummary(),
        'database_error': e.toString(),
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

  /// Get enhanced activity statistics with streaks, time patterns, and all-time data
  static Future<Map<String, dynamic>> getEnhancedActivityStats(
      {int days = 7}) async {
    try {
      // Get basic stats
      final basicStats = await getActivityStats(days: days);

      // Get all-time count
      final allTimeCount = await getTotalActivityCount();

      // Calculate streaks
      final streaks = await _calculateActivityStreaks();

      // Calculate time patterns
      final timePatterns = await _calculateTimePatterns(days: days);

      // Get Oracle suggestions (activities not yet tried)
      final oracleSuggestions = await _getOracleActivitySuggestions();

      // Combine all data
      return {
        ...basicStats,
        'all_time_count': allTimeCount,
        'streaks': streaks,
        'time_patterns': timePatterns,
        'oracle_suggestions': oracleSuggestions,
      };
    } catch (e) {
      _logger.error('Failed to get enhanced activity stats: $e');
      return {
        'period': days == 0 ? 'today' : '${days}_days',
        'total_activities': 0,
        'activities': [],
        'summary': _getEmptySummary(),
        'all_time_count': 0,
        'streaks': {},
        'time_patterns': {},
        'oracle_suggestions': [],
      };
    }
  }

  /// Calculate activity streaks for different activities
  static Future<Map<String, dynamic>> _calculateActivityStreaks() async {
    try {
      final now = DateTime.now();
      final activities = await _database.activityModels.where().findAll();

      // Sort in descending order (most recent first)
      activities.sort((a, b) => b.completedAt.compareTo(a.completedAt));

      if (activities.isEmpty) {
        return {
          'longest_streak': {'activity': 'None', 'days': 0},
          'current_streaks': [],
        };
      }

      // Group activities by code and calculate streaks
      final Map<String, List<DateTime>> activityDates = {};

      for (final activity in activities) {
        final code = activity.activityCode ?? activity.description ?? 'Unknown';
        final date = DateTime(
          activity.completedAt.year,
          activity.completedAt.month,
          activity.completedAt.day,
        );

        activityDates.putIfAbsent(code, () => []);
        if (!activityDates[code]!.any((d) =>
            d.year == date.year &&
            d.month == date.month &&
            d.day == date.day)) {
          activityDates[code]!.add(date);
        }
      }

      // Calculate streaks for each activity
      String longestStreakActivity = 'None';
      int longestStreakDays = 0;
      final List<Map<String, dynamic>> currentStreaks = [];

      for (final entry in activityDates.entries) {
        final code = entry.key;
        final dates = entry.value
          ..sort((a, b) => b.compareTo(a)); // Most recent first

        if (dates.isEmpty) continue;

        // Calculate current streak
        int currentStreak = 0;
        DateTime checkDate = DateTime(now.year, now.month, now.day);

        for (int i = 0; i < dates.length; i++) {
          final activityDate = dates[i];
          final daysDiff = checkDate.difference(activityDate).inDays;

          if (daysDiff == currentStreak) {
            currentStreak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }

        // Calculate longest streak for this activity
        int longestStreak = 0;
        int tempStreak = 1;

        for (int i = 1; i < dates.length; i++) {
          final daysDiff = dates[i - 1].difference(dates[i]).inDays;
          if (daysDiff == 1) {
            tempStreak++;
          } else {
            longestStreak =
                tempStreak > longestStreak ? tempStreak : longestStreak;
            tempStreak = 1;
          }
        }
        longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

        // Update global longest streak
        if (longestStreak > longestStreakDays) {
          longestStreakDays = longestStreak;
          longestStreakActivity = code;
        }

        // Add to current streaks if > 0
        if (currentStreak > 0) {
          currentStreaks.add({
            'activity': code,
            'days': currentStreak,
            'longest': longestStreak,
          });
        }
      }

      // Sort current streaks by days (descending)
      currentStreaks
          .sort((a, b) => (b['days'] as int).compareTo(a['days'] as int));

      return {
        'longest_streak': {
          'activity': longestStreakActivity,
          'days': longestStreakDays,
        },
        'current_streaks':
            currentStreaks.take(5).toList(), // Top 5 current streaks
      };
    } catch (e) {
      _logger.error('Failed to calculate activity streaks: $e');
      return {
        'longest_streak': {'activity': 'None', 'days': 0},
        'current_streaks': [],
      };
    }
  }

  /// Calculate time patterns (morning, afternoon, evening distribution)
  static Future<Map<String, dynamic>> _calculateTimePatterns(
      {int days = 7}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final activities = await _database.activityModels
          .filter()
          .completedAtBetween(startDate, now)
          .findAll();

      if (activities.isEmpty) {
        return {
          'most_active_time': 'No data',
          'time_distribution': {
            'morning': 0,
            'afternoon': 0,
            'evening': 0,
            'night': 0,
          },
          'hourly_distribution': {},
        };
      }

      // Count activities by time periods
      int morning = 0; // 6-12
      int afternoon = 0; // 12-18
      int evening = 0; // 18-22
      int night = 0; // 22-6

      final Map<int, int> hourlyCount = {};

      for (final activity in activities) {
        final hour = activity.completedAt.hour;

        // Count by time period
        if (hour >= 6 && hour < 12) {
          morning++;
        } else if (hour >= 12 && hour < 18) {
          afternoon++;
        } else if (hour >= 18 && hour < 22) {
          evening++;
        } else {
          night++;
        }

        // Count by hour
        hourlyCount[hour] = (hourlyCount[hour] ?? 0) + 1;
      }

      // Find most active time
      final timeDistribution = {
        'morning': morning,
        'afternoon': afternoon,
        'evening': evening,
        'night': night,
      };

      String mostActiveTime = 'morning';
      int maxCount = morning;

      timeDistribution.forEach((period, count) {
        if (count > maxCount) {
          maxCount = count;
          mostActiveTime = period;
        }
      });

      return {
        'most_active_time': mostActiveTime,
        'time_distribution': timeDistribution,
        'hourly_distribution':
            hourlyCount.map((key, value) => MapEntry(key.toString(), value)),
      };
    } catch (e) {
      _logger.error('Failed to calculate time patterns: $e');
      return {
        'most_active_time': 'No data',
        'time_distribution': {
          'morning': 0,
          'afternoon': 0,
          'evening': 0,
          'night': 0,
        },
        'hourly_distribution': {},
      };
    }
  }

  /// Get Oracle activity suggestions (activities not yet tried)
  static Future<List<Map<String, dynamic>>>
      _getOracleActivitySuggestions() async {
    try {
      // Get all Oracle activities from parser
      final oracleResult = await OracleActivityParser.parseFromPersona();
      final oracleActivities = <Map<String, dynamic>>[];

      // Extract activities from Oracle result
      for (final activity in oracleResult.activities.values) {
        oracleActivities.add({
          'code': activity.code,
          'name': activity.name,
          'dimension': activity.dimension,
          'description': activity.name,
        });
      }

      // Get user's completed activity codes
      final completedActivities = await _database.activityModels
          .filter()
          .activityCodeIsNotNull()
          .distinctByActivityCode()
          .findAll();

      final completedCodes =
          completedActivities.map((a) => a.activityCode!).toSet();

      // Find Oracle activities not yet tried
      final suggestions = <Map<String, dynamic>>[];

      for (final oracle in oracleActivities) {
        final code = oracle['code'] as String?;
        if (code != null && !completedCodes.contains(code)) {
          suggestions.add({
            'code': code,
            'name': oracle['name'],
            'dimension': oracle['dimension'],
            'description': oracle['description'] ?? oracle['name'],
          });
        }
      }

      // Limit to 10 suggestions and prioritize by dimension diversity
      final dimensionCounts = <String, int>{};
      final diverseSuggestions = <Map<String, dynamic>>[];

      for (final suggestion in suggestions) {
        final dimension = suggestion['dimension'] as String;
        final count = dimensionCounts[dimension] ?? 0;

        if (count < 2 && diverseSuggestions.length < 10) {
          diverseSuggestions.add(suggestion);
          dimensionCounts[dimension] = count + 1;
        }
      }

      return diverseSuggestions;
    } catch (e) {
      _logger.error('Failed to get Oracle activity suggestions: $e');
      return [];
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

  /// Get all activities with optional date filtering (for export)
  static Future<List<ActivityModel>> getAllActivitiesForExport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Check if database is available
      final dbAvailable = await isDatabaseAvailable();
      if (!dbAvailable) {
        throw Exception('Activity database is not available');
      }

      // Build query with date filtering
      List<ActivityModel> activities;

      if (startDate != null && endDate != null) {
        activities = await _database.activityModels
            .filter()
            .completedAtBetween(startDate, endDate)
            .sortByCompletedAt()
            .findAll();
      } else if (startDate != null) {
        activities = await _database.activityModels
            .filter()
            .completedAtGreaterThan(startDate)
            .sortByCompletedAt()
            .findAll();
      } else if (endDate != null) {
        activities = await _database.activityModels
            .filter()
            .completedAtLessThan(endDate)
            .sortByCompletedAt()
            .findAll();
      } else {
        activities = await _database.activityModels
            .where()
            .sortByCompletedAt()
            .findAll();
      }

      _logger.info('Retrieved ${activities.length} activities for export');
      return activities;
    } catch (e) {
      _logger.error('Failed to retrieve activities for export: $e');
      return [];
    }
  }

  /// Check if activity exists (for duplicate detection during import)
  static Future<bool> activityExists({
    required DateTime completedAt,
    String? activityCode,
    String? activityName,
  }) async {
    try {
      // Check for existing activity with same timestamp and either same code or name
      final existingQuery =
          _database.activityModels.filter().completedAtEqualTo(completedAt);

      if (activityCode != null) {
        // For Oracle activities, check by code
        final existing =
            await existingQuery.activityCodeEqualTo(activityCode).findFirst();
        return existing != null;
      } else if (activityName != null) {
        // For custom activities, check by name
        final existing =
            await existingQuery.activityNameEqualTo(activityName).findFirst();
        return existing != null;
      }

      return false;
    } catch (e) {
      _logger.warning('Error checking if activity exists: $e');
      return false; // If we can't check, allow import
    }
  }

  /// Import activity with preserved timestamps (FT-124 fix)
  static Future<ActivityModel> importActivity(ActivityModel activity) async {
    try {
      await _database.writeTxn(() async {
        await _database.activityModels.put(activity);
      });

      _logger.info(
          'Imported activity: ${activity.description} at ${activity.formattedTime} (preserved timestamp)');
      return activity;
    } catch (e) {
      _logger.error('Failed to import activity: $e');
      rethrow;
    }
  }

  /// FT-161: Delete all activities from the database
  static Future<void> deleteAllActivities() async {
    try {
      _logger.info('FT-161: Starting to delete all activities');

      // Get count before deletion for logging
      final countBefore = await _database.activityModels.count();

      await _database.writeTxn(() async {
        await _database.activityModels.clear();
      });

      final countAfter = await _database.activityModels.count();
      _logger.info(
          'FT-161: Deleted $countBefore activities, $countAfter remaining');
    } catch (e) {
      _logger.error('FT-161: Failed to delete all activities: $e');
      rethrow;
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
