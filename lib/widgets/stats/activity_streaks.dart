import 'package:flutter/material.dart';

/// Widget for displaying activity streaks and achievements
class ActivityStreaks extends StatelessWidget {
  final Map<String, dynamic> streaks;

  const ActivityStreaks({
    super.key,
    required this.streaks,
  });

  @override
  Widget build(BuildContext context) {
    final longestStreak =
        streaks['longest_streak'] as Map<String, dynamic>? ?? {};
    final currentStreaks = streaks['current_streaks'] as List<dynamic>? ?? [];

    if (longestStreak.isEmpty && currentStreaks.isEmpty) {
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
                  Icons.local_fire_department,
                  size: 20,
                  color: Colors.orange,
                ),
                SizedBox(width: 8),
                Text(
                  'Activity Streaks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Longest Streak Achievement
            if (longestStreak.isNotEmpty && longestStreak['days'] > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Longest Streak',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${longestStreak['days']} days - ${longestStreak['activity']}',
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

            // Current Active Streaks
            if (currentStreaks.isNotEmpty) ...[
              const Text(
                'Current Streaks',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...currentStreaks.map((streak) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _buildStreakItem(streak as Map<String, dynamic>),
                );
              }).toList(),
            ],

            // Motivational message if no current streaks
            if (currentStreaks.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Colors.blue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Start building streaks by doing activities consistently!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreakItem(Map<String, dynamic> streak) {
    final activity = streak['activity'] as String;
    final days = streak['days'] as int;
    final longest = streak['longest'] as int;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStreakColor(days),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$days days (best: $longest)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStreakColor(days).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '🔥 $days',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getStreakColor(days),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStreakColor(int days) {
    if (days >= 7) return Colors.red; // Hot streak
    if (days >= 3) return Colors.orange; // Good streak
    return Colors.blue; // Starting streak
  }
}
