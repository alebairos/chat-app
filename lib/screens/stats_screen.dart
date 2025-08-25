import 'package:flutter/material.dart';
import '../services/activity_memory_service.dart';
import '../services/chat_storage_service.dart';
import '../widgets/stats/stats_summary.dart';
import '../widgets/stats/activity_card.dart';
import '../widgets/stats/basic_patterns.dart';
import '../widgets/stats/activity_streaks.dart';
import '../widgets/stats/time_patterns.dart';
import '../widgets/stats/oracle_suggestions.dart';
import '../widgets/stats/simple_charts.dart';

/// Stats screen displaying real activity tracking data from FT-064
/// Enhanced with comprehensive data display as per FT-066 specification
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic> _todayStats = {};
  Map<String, dynamic> _weekStats = {};
  Map<String, dynamic> _enhancedStats = {};

  @override
  void initState() {
    super.initState();
    _loadActivityStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retry loading data if we had an error and the screen becomes visible again
    if (_hasError) {
      print(
          '🔄 StatsScreen: Screen became visible again, attempting database reconnection...');
      _tryReconnectDatabase().then((reconnected) {
        if (reconnected) {
          print(
              '✅ StatsScreen: Auto-reconnection successful, loading stats...');
          _loadActivityStats();
        }
      });
    }
  }

  Future<void> _loadActivityStats() async {
    try {
      print('🔍 StatsScreen: Starting to load activity stats...');
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Load today's stats, week stats, and enhanced stats
      print('🔍 StatsScreen: Loading today\'s stats...');
      // FT-088: Fix critical bug - use days: 0 for today's activities (not days: 1 which is yesterday)
      final todayData = await ActivityMemoryService.getActivityStats(days: 0);
      print(
          '🔍 StatsScreen: Today\'s stats loaded: ${todayData['total_activities']} activities');

      print('🔍 StatsScreen: Loading week stats...');
      final weekData = await ActivityMemoryService.getActivityStats(days: 7);
      print(
          '🔍 StatsScreen: Week stats loaded: ${weekData['total_activities']} activities');

      print('🔍 StatsScreen: Loading enhanced stats...');
      final enhancedData =
          await ActivityMemoryService.getEnhancedActivityStats(days: 7);
      print('🔍 StatsScreen: Enhanced stats loaded');

      // Check for database errors in the response
      final todayError = todayData['database_error'] as String?;
      final weekError = weekData['database_error'] as String?;
      final enhancedError = enhancedData['database_error'] as String?;

      if (todayError != null || weekError != null || enhancedError != null) {
        print(
            '❌ StatsScreen: Database error detected: today=$todayError, week=$weekError, enhanced=$enhancedError');

        // Try to reconnect to the database
        final reconnected = await _tryReconnectDatabase();
        if (reconnected) {
          print('🔄 StatsScreen: Database reconnected, retrying...');
          // Retry loading stats
          await _loadActivityStats();
          return;
        }

        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              'Database connection issue: ${todayError ?? weekError ?? enhancedError}';
        });
        return;
      }

      print('✅ StatsScreen: All stats loaded successfully');
      setState(() {
        _todayStats = todayData;
        _weekStats = weekData;
        _enhancedStats = enhancedData;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      print('❌ StatsScreen: Exception occurred: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load data: $e';
      });
      print('Error loading activity stats: $e');
    }
  }

  /// Try to reconnect to the database
  Future<bool> _tryReconnectDatabase() async {
    try {
      print('🔄 StatsScreen: Attempting to reconnect to database...');

      // Get a fresh database connection from the storage service
      final storageService = ChatStorageService();
      final newIsar = await storageService.db;

      // Try to reinitialize the ActivityMemoryService with the new connection
      final success = await ActivityMemoryService.reinitializeDatabase(newIsar);

      if (success) {
        print('✅ StatsScreen: Successfully reconnected to database');
        return true;
      } else {
        print('❌ StatsScreen: Failed to reconnect to database');
        return false;
      }
    } catch (e) {
      print('❌ StatsScreen: Error during database reconnection: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your activity data...'),
            ],
          ),
        ),
      );
    }

    // Show error state if there was a database connection issue
    if (_hasError) {
      return _buildErrorState();
    }

    final todayActivities = _todayStats['activities'] as List<dynamic>? ?? [];
    final weekActivities = _weekStats['activities'] as List<dynamic>? ?? [];
    final todayTotal = _todayStats['total_activities'] as int? ?? 0;
    final todaySummary = _todayStats['summary'] as Map<String, dynamic>? ?? {};
    final weekSummary = _weekStats['summary'] as Map<String, dynamic>? ?? {};

    // Enhanced stats data
    final allTimeCount = _enhancedStats['all_time_count'] as int? ?? 0;
    final streaks = _enhancedStats['streaks'] as Map<String, dynamic>? ?? {};
    final timePatterns =
        _enhancedStats['time_patterns'] as Map<String, dynamic>? ?? {};
    final oracleSuggestions =
        _enhancedStats['oracle_suggestions'] as List<dynamic>? ?? [];

    // Show empty state if no activities (but only if we successfully loaded data)
    if (todayTotal == 0 && weekActivities.isEmpty && allTimeCount == 0) {
      return _buildEmptyState();
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadActivityStats,
        child: ListView(
          children: [
            // Today's Summary with All-Time Count
            StatsSummary(
              totalActivities: todayTotal,
              lastActivityTime: _getLastActivityTime(todayActivities),
              activeDimensions: _getActiveDimensions(todaySummary),
              period: 'today',
            ),

            // All-Time Statistics Card
            if (allTimeCount > 0) ...[
              _buildAllTimeStatsCard(allTimeCount),
            ],

            // Activity Streaks
            if (streaks.isNotEmpty) ...[
              ActivityStreaks(streaks: streaks),
            ],

            // Time Patterns
            if (timePatterns.isNotEmpty) ...[
              TimePatterns(timePatterns: timePatterns),
            ],

            // Recent Activities Section
            if (todayActivities.isNotEmpty) ...[
              _buildSectionHeader('Today\'s Activities'),
              ...todayActivities
                  .map((activity) => _buildActivityCard(activity)),
            ],

            // This Week's Patterns
            if (weekSummary.isNotEmpty) ...[
              BasicPatterns(summary: weekSummary),
            ],

            // Visual Charts
            if (weekSummary.isNotEmpty) ...[
              // Dimension Distribution Chart
              SimpleCharts.dimensionDistributionChart(
                dimensionData:
                    weekSummary['by_dimension'] as Map<String, dynamic>? ?? {},
                totalActivities: weekSummary['total_occurrences'] as int? ?? 0,
              ),

              // Activity Frequency Chart
              SimpleCharts.activityFrequencyChart(
                activityData:
                    weekSummary['by_activity'] as Map<String, dynamic>? ?? {},
                maxCount: _getMaxActivityCount(
                    weekSummary['by_activity'] as Map<String, dynamic>? ?? {}),
              ),
            ],

            // Time Distribution Chart
            if (timePatterns.isNotEmpty) ...[
              SimpleCharts.timeDistributionChart(
                timeData: timePatterns['time_distribution']
                        as Map<String, dynamic>? ??
                    {},
              ),
            ],

            // Oracle Activity Suggestions
            if (oracleSuggestions.isNotEmpty) ...[
              OracleSuggestions(
                suggestions: oracleSuggestions.cast<Map<String, dynamic>>(),
              ),
            ],

            // Recent Week Activities (if different from today)
            if (weekActivities.length > todayActivities.length) ...[
              _buildSectionHeader('This Week\'s Activities'),
              ...weekActivities
                  .take(10)
                  .map((activity) => _buildActivityCard(activity)),
            ],

            // Add some bottom padding
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No activities tracked yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start chatting with Ari to automatically\ntrack your activities and see them here!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load activity data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'The database connection was lost. This can happen when switching between screens. The app will automatically try to reconnect.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadActivityStats,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _tryReconnectDatabase,
                    icon: const Icon(Icons.wifi_find),
                    label: const Text('Reconnect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Technical details: $_errorMessage',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildActivityCard(dynamic activity) {
    return ActivityCard(
      code: activity['code'] as String?,
      name: activity['name'] as String? ?? 'Unknown Activity',
      time: activity['time'] as String? ?? '',
      // FT-089: Removed confidence parameter - now using simple "Completed" indicator
      dimension: activity['dimension'] as String? ?? '',
      source: activity['source'] as String? ?? '',
    );
  }

  String _getLastActivityTime(List<dynamic> activities) {
    if (activities.isEmpty) return '';

    final lastActivity = activities.first;

    // FT-088: Use full_timestamp instead of reconstructing date from time
    final fullTimestamp = lastActivity['full_timestamp'] as String?;
    if (fullTimestamp == null || fullTimestamp.isEmpty) {
      // Fallback to old method if no full timestamp
      final time = lastActivity['time'] as String?;
      return time ?? '';
    }

    // Calculate relative time using proper full timestamp
    try {
      final activityTime = DateTime.parse(fullTimestamp);
      final now = DateTime.now();
      final diff = now.difference(activityTime);

      if (diff.isNegative) {
        // Should not happen with proper data, but handle gracefully
        return 'Recently';
      }

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else {
        return '${diff.inDays} days ago';
      }
    } catch (e) {
      // Fallback to displaying the raw time if parsing fails
      final time = lastActivity['time'] as String?;
      return time ?? 'Recently';
    }
  }

  List<String> _getActiveDimensions(Map<String, dynamic> summary) {
    final byDimension = summary['by_dimension'] as Map<String, dynamic>? ?? {};
    return byDimension.keys.toList();
  }

  int _getMaxActivityCount(Map<String, dynamic> activityData) {
    if (activityData.isEmpty) return 0;
    return activityData.values
        .fold<int>(0, (max, count) => (count as int) > max ? count : max);
  }

  Widget _buildAllTimeStatsCard(int allTimeCount) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.timeline,
                  size: 20,
                  color: Colors.deepPurple,
                ),
                SizedBox(width: 8),
                Text(
                  'All-Time Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.withOpacity(0.1),
                    Colors.blue.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.deepPurple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.deepPurple,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          allTimeCount.toString(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const Text(
                          'Total Activities Completed',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
