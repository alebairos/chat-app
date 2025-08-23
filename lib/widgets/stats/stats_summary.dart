import 'package:flutter/material.dart';

/// Widget for displaying today's activity summary
class StatsSummary extends StatelessWidget {
  final int totalActivities;
  final String lastActivityTime;
  final List<String> activeDimensions;
  final String period;

  const StatsSummary({
    super.key,
    required this.totalActivities,
    required this.lastActivityTime,
    required this.activeDimensions,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatPeriodTitle(period),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Activity Count
            _buildSummaryRow(
              icon: Icons.check_circle,
              label: '$totalActivities activities detected',
              value: '',
              color: Colors.green,
            ),

            // Last Activity Time
            if (lastActivityTime.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSummaryRow(
                icon: Icons.access_time,
                label: 'Last activity',
                value: lastActivityTime,
                color: Colors.orange,
              ),
            ],

            // Active Dimensions
            if (activeDimensions.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSummaryRow(
                icon: Icons.dashboard,
                label: 'Dimensions',
                value: activeDimensions.join(', '),
                color: Colors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isEmpty ? label : '$label: $value',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatPeriodTitle(String period) {
    switch (period.toLowerCase()) {
      case 'today':
        return 'Today';
      case 'this_week':
        return 'This Week';
      case 'this_month':
        return 'This Month';
      default:
        return 'Activity Summary';
    }
  }
}
