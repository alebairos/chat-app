import 'package:flutter/material.dart';
import '../services/activity_memory_service.dart';
import '../widgets/stats/stats_summary.dart';
import '../widgets/stats/activity_card.dart';
import '../widgets/stats/basic_patterns.dart';

/// Stats screen displaying real activity tracking data from FT-064
/// Enhanced with comprehensive data display as per FT-066 specification
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _todayStats = {};
  Map<String, dynamic> _weekStats = {};

  @override
  void initState() {
    super.initState();
    _loadActivityStats();
  }

  Future<void> _loadActivityStats() async {
    try {
      setState(() => _isLoading = true);

      // Load today's stats and recent week stats
      final todayData = await ActivityMemoryService.getActivityStats(days: 1);
      final weekData = await ActivityMemoryService.getActivityStats(days: 7);

      setState(() {
        _todayStats = todayData;
        _weekStats = weekData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Error handling - show empty state
      print('Error loading activity stats: $e');
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

    final todayActivities = _todayStats['activities'] as List<dynamic>? ?? [];
    final weekActivities = _weekStats['activities'] as List<dynamic>? ?? [];
    final todayTotal = _todayStats['total_activities'] as int? ?? 0;
    final todaySummary = _todayStats['summary'] as Map<String, dynamic>? ?? {};
    final weekSummary = _weekStats['summary'] as Map<String, dynamic>? ?? {};

    // Show empty state if no activities
    if (todayTotal == 0 && weekActivities.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadActivityStats,
        child: ListView(
          children: [
            // Today's Summary
            StatsSummary(
              totalActivities: todayTotal,
              lastActivityTime: _getLastActivityTime(todayActivities),
              activeDimensions: _getActiveDimensions(todaySummary),
              period: 'today',
            ),

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
      confidence: (activity['confidence'] as num?)?.toDouble() ?? 0.0,
      dimension: activity['dimension'] as String? ?? '',
      source: activity['source'] as String? ?? '',
    );
  }

  String _getLastActivityTime(List<dynamic> activities) {
    if (activities.isEmpty) return '';

    final lastActivity = activities.first;
    final time = lastActivity['time'] as String?;
    if (time == null || time.isEmpty) return '';

    // Calculate relative time (e.g., "2 hours ago")
    try {
      final now = DateTime.now();
      final parts = time.split(':');
      final activityTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      final diff = now.difference(activityTime);
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minutes ago';
      } else {
        return '${diff.inHours} hours ago';
      }
    } catch (e) {
      return time;
    }
  }

  List<String> _getActiveDimensions(Map<String, dynamic> summary) {
    final byDimension = summary['by_dimension'] as Map<String, dynamic>? ?? {};
    return byDimension.keys.toList();
  }
}
