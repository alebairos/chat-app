import 'package:flutter/material.dart';

/// Widget for displaying time-based activity patterns
class TimePatterns extends StatelessWidget {
  final Map<String, dynamic> timePatterns;

  const TimePatterns({
    super.key,
    required this.timePatterns,
  });

  @override
  Widget build(BuildContext context) {
    final mostActiveTime =
        timePatterns['most_active_time'] as String? ?? 'No data';
    final timeDistribution =
        timePatterns['time_distribution'] as Map<String, dynamic>? ?? {};
    final hourlyDistribution =
        timePatterns['hourly_distribution'] as Map<String, dynamic>? ?? {};

    if (timeDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalActivities = timeDistribution.values
        .fold<int>(0, (sum, count) => sum + (count as int));

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
                  Icons.schedule,
                  size: 20,
                  color: Colors.indigo,
                ),
                SizedBox(width: 8),
                Text(
                  'Time Patterns',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Most Active Time Highlight
            if (mostActiveTime != 'No data') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.indigo.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTimeIcon(mostActiveTime),
                      color: Colors.indigo,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Most Active Time',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimePeriod(mostActiveTime),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Time Distribution
            const Text(
              'Activity Distribution',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            ...timeDistribution.entries.map((entry) {
              final period = entry.key;
              final count = entry.value as int;
              final percentage =
                  totalActivities > 0 ? (count / totalActivities) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _buildTimeDistributionBar(
                  period: period,
                  count: count,
                  percentage: percentage,
                ),
              );
            }).toList(),

            // Peak Hours (if available)
            if (hourlyDistribution.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Peak Hours',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _buildPeakHours(hourlyDistribution),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDistributionBar({
    required String period,
    required int count,
    required double percentage,
  }) {
    final color = _getTimePeriodColor(period);
    final displayName = _formatTimePeriod(period);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _getTimeIcon(period),
                  size: 16,
                  color: color,
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
              '$count activities',
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

  Widget _buildPeakHours(Map<String, dynamic> hourlyDistribution) {
    // Find top 3 peak hours
    final sortedHours = hourlyDistribution.entries.toList()
      ..sort((a, b) => (a.value as int).compareTo(b.value as int));

    final topHours = sortedHours.take(3).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: topHours.map((entry) {
        final hour = int.parse(entry.key.toString());
        final count = entry.value;
        final timeString = '${hour.toString().padLeft(2, '0')}:00';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.indigo.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '$timeString ($count)',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.indigo,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getTimePeriodColor(String period) {
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

  IconData _getTimeIcon(String period) {
    switch (period.toLowerCase()) {
      case 'morning':
        return Icons.wb_sunny;
      case 'afternoon':
        return Icons.wb_sunny_outlined;
      case 'evening':
        return Icons.wb_twilight;
      case 'night':
        return Icons.nightlight_round;
      default:
        return Icons.schedule;
    }
  }

  String _formatTimePeriod(String period) {
    switch (period.toLowerCase()) {
      case 'morning':
        return 'Morning (6AM-12PM)';
      case 'afternoon':
        return 'Afternoon (12PM-6PM)';
      case 'evening':
        return 'Evening (6PM-10PM)';
      case 'night':
        return 'Night (10PM-6AM)';
      default:
        return period;
    }
  }
}
