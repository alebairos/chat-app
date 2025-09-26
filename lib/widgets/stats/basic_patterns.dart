import 'package:flutter/material.dart';

/// Widget for displaying basic activity patterns and statistics
class BasicPatterns extends StatelessWidget {
  final Map<String, dynamic> summary;

  const BasicPatterns({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final byDimension = summary['by_dimension'] as Map<String, dynamic>? ?? {};
    final mostFrequent = summary['most_frequent'] as String? ?? '';
    final uniqueActivities = summary['unique_activities'] as int? ?? 0;
    final totalOccurrences = summary['total_occurrences'] as int? ?? 0;

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
                  Icons.analytics,
                  size: 20,
                  color: Colors.purple,
                ),
                SizedBox(width: 8),
                Text(
                  'Patterns & Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Activity Overview
            _buildPatternItem(
              icon: Icons.category,
              label: 'Unique activities',
              value: uniqueActivities.toString(),
              color: Colors.blue,
            ),

            const SizedBox(height: 8),

            _buildPatternItem(
              icon: Icons.repeat,
              label: 'Total occurrences',
              value: totalOccurrences.toString(),
              color: Colors.green,
            ),

            // Most Frequent Activity
            if (mostFrequent.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPatternItem(
                icon: Icons.star,
                label: 'Most frequent',
                value: mostFrequent,
                color: Colors.orange,
              ),
            ],

            // Dimension Breakdown
            if (byDimension.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Activity Distribution',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...byDimension.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: _buildDimensionBar(
                    dimension: entry.key,
                    count: entry.value as int,
                    total: totalOccurrences,
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatternItem({
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
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDimensionBar({
    required String dimension,
    required int count,
    required int total,
  }) {
    final percentage = total > 0 ? (count / total) : 0.0;
    final color = _getDimensionColor(dimension);
    final displayName = _getDimensionDisplayName(dimension);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getDimensionColor(String dimension) {
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

  String _getDimensionDisplayName(String dimension) {
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
}
