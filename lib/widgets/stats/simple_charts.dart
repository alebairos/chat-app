import 'package:flutter/material.dart';

/// Simple chart widgets for activity statistics visualization
class SimpleCharts {
  /// Create a simple horizontal bar chart for dimension distribution
  static Widget dimensionDistributionChart({
    required Map<String, dynamic> dimensionData,
    required int totalActivities,
  }) {
    if (dimensionData.isEmpty || totalActivities == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
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
                  Icons.pie_chart,
                  size: 20,
                  color: Colors.teal,
                ),
                SizedBox(width: 8),
                Text(
                  'Dimension Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...dimensionData.entries.map((entry) {
              final dimension = entry.key;
              final count = entry.value as int;
              final percentage = count / totalActivities;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _buildDimensionBar(
                  dimension: dimension,
                  count: count,
                  percentage: percentage,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Create a simple activity frequency chart
  static Widget activityFrequencyChart({
    required Map<String, dynamic> activityData,
    required int maxCount,
  }) {
    if (activityData.isEmpty || maxCount == 0) {
      return const SizedBox.shrink();
    }

    // Get top 5 activities
    final sortedActivities = activityData.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    final topActivities = sortedActivities.take(5).toList();

    return Card(
      elevation: 1,
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
                  Icons.bar_chart,
                  size: 20,
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                Text(
                  'Most Frequent Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topActivities.map((entry) {
              final activity = entry.key;
              final count = entry.value as int;
              final percentage = count / maxCount;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _buildActivityBar(
                  activity: activity,
                  count: count,
                  percentage: percentage,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Create a simple time distribution donut-style chart
  static Widget timeDistributionChart({
    required Map<String, dynamic> timeData,
  }) {
    if (timeData.isEmpty) {
      return const SizedBox.shrink();
    }

    final total =
        timeData.values.fold<int>(0, (sum, count) => sum + (count as int));
    if (total == 0) return const SizedBox.shrink();

    return Card(
      elevation: 1,
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
                  Icons.access_time,
                  size: 20,
                  color: Colors.orange,
                ),
                SizedBox(width: 8),
                Text(
                  'Time Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Simple circular progress indicators
            Row(
              children: timeData.entries.map((entry) {
                final period = entry.key;
                final count = entry.value as int;
                final percentage = count / total;

                return Expanded(
                  child: _buildTimeCircle(
                    period: period,
                    count: count,
                    percentage: percentage,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDimensionBar({
    required String dimension,
    required int count,
    required double percentage,
  }) {
    final color = _getDimensionColor(dimension);
    final displayName = _getDimensionDisplayName(dimension);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              '$count (${(percentage * 100).round()}%)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[200],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildActivityBar({
    required String activity,
    required int count,
    required double percentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                activity,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$count times',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Colors.grey[200],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.green,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildTimeCircle({
    required String period,
    required int count,
    required double percentage,
  }) {
    final color = _getTimePeriodColor(period);
    final displayName = _formatTimePeriod(period);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 6,
                ),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Color _getDimensionColor(String dimension) {
    switch (dimension.toUpperCase()) {
      case 'SF':
        return Colors.green;
      case 'SM':
        return Colors.blue;
      case 'TG':
        return Colors.orange;
      case 'R':
        return Colors.pink;
      case 'CE':
        return Colors.purple;
      case 'AE':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  static String _getDimensionDisplayName(String dimension) {
    switch (dimension.toUpperCase()) {
      case 'SF':
        return 'Physical Health';
      case 'SM':
        return 'Mental Health';
      case 'TG':
        return 'Work & Management';
      case 'R':
        return 'Relationships';
      case 'CE':
        return 'Creativity';
      case 'AE':
        return 'Adventure';
      default:
        return dimension;
    }
  }

  static Color _getTimePeriodColor(String period) {
    switch (period.toLowerCase()) {
      case 'morning':
        return Colors.amber;
      case 'afternoon':
        return Colors.orange;
      case 'evening':
        return Colors.deepPurple;
      case 'night':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  static String _formatTimePeriod(String period) {
    switch (period.toLowerCase()) {
      case 'morning':
        return 'Morning';
      case 'afternoon':
        return 'Afternoon';
      case 'evening':
        return 'Evening';
      case 'night':
        return 'Night';
      default:
        return period;
    }
  }
}
