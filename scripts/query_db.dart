import 'package:flutter/material.dart';
import 'package:ai_personas_app/services/activity_memory_service.dart';
import 'package:ai_personas_app/services/chat_storage_service.dart';
import 'package:ai_personas_app/models/activity_model.dart';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  print('🔍 Querying database...');

  final storageService = ChatStorageService();

  try {
    // Wait for database connection
    final isar = await storageService.db;
    print('✅ Database connected');

    // Initialize ActivityMemoryService
    ActivityMemoryService.initialize(isar);

    // Query total counts
    final totalActivities = await ActivityMemoryService.getTotalActivityCount();

    print('\n📊 DATABASE SUMMARY:');
    print('Activities: $totalActivities');

    if (totalActivities > 0) {
      print('\n🎯 TODAY\'S ACTIVITIES:');
      final todayActivities = await ActivityMemoryService.getTodayActivities();
      print('Today count: ${todayActivities.length}');

      for (final activity in todayActivities) {
        final time =
            '${activity.completedAt.hour.toString().padLeft(2, '0')}:${activity.completedAt.minute.toString().padLeft(2, '0')}';
        print(
            '  • ${activity.activityCode} (${activity.activityName}) at $time');
      }

      print('\n📅 LAST 7 DAYS:');
      final recentActivities =
          await ActivityMemoryService.getRecentActivities(7);
      print('Week count: ${recentActivities.length}');

      // Group by date
      final Map<String, List<ActivityModel>> byDate = {};
      for (final activity in recentActivities) {
        final date =
            '${activity.completedAt.year}-${activity.completedAt.month.toString().padLeft(2, '0')}-${activity.completedAt.day.toString().padLeft(2, '0')}';
        byDate[date] ??= [];
        byDate[date]!.add(activity);
      }

      byDate.forEach((date, activities) {
        print('  $date: ${activities.length} activities');
      });

      print('\n🧪 TESTING MCP COMMAND:');

      // Test our new getActivityStats method
      final statsToday = await ActivityMemoryService.getActivityStats(days: 1);
      print('MCP Stats (today): ${statsToday['total_activities']} activities');
      print('Period: ${statsToday['period']}');

      final activities = statsToday['activities'] as List;
      for (final activity in activities.take(5)) {
        print(
            '  • ${activity['code']}: ${activity['name']} at ${activity['time']}');
      }

      final summary = statsToday['summary'];
      print('Summary:');
      print('  - By dimension: ${summary['by_dimension']}');
      print(
          '  - Most frequent: ${summary['most_frequent']} (${summary['max_frequency']}x)');
    }

    await storageService.close();
    print('\n✅ Query complete!');
  } catch (e, s) {
    print('❌ Error: $e');
    print('Stack trace: $s');
  }
}
