import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'dart:convert';

import '../../lib/services/activity_memory_service.dart';
import '../../lib/services/system_mcp_service.dart';
import '../../lib/models/activity_model.dart';

void main() {
  group('FT-068 Activity Stats MCP Command', () {
    late Isar isar;
    late SystemMCPService mcpService;

    setUpAll(() async {
      // Initialize in-memory Isar for testing
      isar = await Isar.open(
        [ActivityModelSchema],
        directory: '',
        name: 'test_ft_068',
      );

      ActivityMemoryService.initialize(isar);
      mcpService = SystemMCPService();
    });

    tearDownAll(() async {
      await isar.close(deleteFromDisk: true);
    });

    tearDown(() async {
      // Clear activities after each test
      await ActivityMemoryService.clearAllActivities();
    });

    test('should return empty stats when no activities exist', () async {
      // Test MCP command with empty database
      final command = '{"action": "get_activity_stats"}';
      final result = await mcpService.processCommand(command);

      final response = json.decode(result);

      expect(response['status'], equals('success'));
      expect(response['data']['total_activities'], equals(0));
      expect(response['data']['period'], equals('today'));
      expect(response['data']['activities'], isEmpty);
      expect(response['data']['summary']['unique_activities'], equals(0));
    });

    test('should return today\'s activities with correct format', () async {
      // Add test activities
      await ActivityMemoryService.logActivity(
        activityCode: 'T8',
        activityName: 'Realizar sessão de trabalho focado (pomodoro)',
        dimension: 'TG',
        source: 'Test',
        confidence: 0.9,
      );

      await ActivityMemoryService.logActivity(
        activityCode: 'SF1',
        activityName: 'Beber água',
        dimension: 'SF',
        source: 'Test',
        confidence: 0.8,
      );

      // Test MCP command
      final command = '{"action": "get_activity_stats"}';
      final result = await mcpService.processCommand(command);

      final response = json.decode(result);

      expect(response['status'], equals('success'));
      expect(response['data']['total_activities'], equals(2));
      expect(response['data']['period'], equals('today'));
      expect(response['data']['activities'], hasLength(2));

      // Check activity structure
      final firstActivity = response['data']['activities'][0];
      expect(firstActivity['code'], isNotNull);
      expect(firstActivity['name'], isNotNull);
      expect(firstActivity['time'],
          matches(RegExp(r'^\d{2}:\d{2}$'))); // HH:MM format
      expect(firstActivity['confidence'], isA<double>());
      expect(firstActivity['dimension'], isNotNull);

      // Check summary statistics
      final summary = response['data']['summary'];
      expect(summary['unique_activities'], equals(2));
      expect(summary['total_occurrences'], equals(2));
      expect(summary['by_dimension']['TG'], equals(1));
      expect(summary['by_dimension']['SF'], equals(1));
    });

    test('should handle days parameter correctly', () async {
      // Add test activity
      await ActivityMemoryService.logActivity(
        activityCode: 'SM8',
        activityName: 'Pausas regulares durante trabalho',
        dimension: 'SM',
        source: 'Test',
      );

      // Test with days parameter
      final command = '{"action": "get_activity_stats", "days": 7}';
      final result = await mcpService.processCommand(command);

      final response = json.decode(result);

      expect(response['status'], equals('success'));
      expect(response['data']['period'], equals('last_7_days'));
      expect(response['data']['total_activities'], equals(1));
    });

    test('should calculate summary statistics correctly', () async {
      // Add multiple activities with duplicates
      await ActivityMemoryService.logActivity(
        activityCode: 'SF1',
        activityName: 'Beber água',
        dimension: 'SF',
        source: 'Test',
      );

      await ActivityMemoryService.logActivity(
        activityCode: 'SF1',
        activityName: 'Beber água',
        dimension: 'SF',
        source: 'Test',
      );

      await ActivityMemoryService.logActivity(
        activityCode: 'T8',
        activityName: 'Trabalho focado',
        dimension: 'TG',
        source: 'Test',
      );

      final command = '{"action": "get_activity_stats"}';
      final result = await mcpService.processCommand(command);

      final response = json.decode(result);
      final summary = response['data']['summary'];

      expect(summary['total_occurrences'], equals(3));
      expect(summary['unique_activities'], equals(2));
      expect(summary['most_frequent'], equals('SF1'));
      expect(summary['max_frequency'], equals(2));
      expect(summary['by_activity']['SF1'], equals(2));
      expect(summary['by_activity']['T8'], equals(1));
    });

    test('should handle invalid commands gracefully', () async {
      final command = '{"action": "get_activity_stats", "days": "invalid"}';
      final result = await mcpService.processCommand(command);

      // When parsing fails, days will be null and default to 1
      final response = json.decode(result);
      expect(response['status'], equals('success'));
      expect(response['data']['period'], equals('today'));
    });

    test('should handle missing action parameter', () async {
      final command = '{"days": 7}';
      final result = await mcpService.processCommand(command);

      final response = json.decode(result);
      expect(response['status'], equals('error'));
      expect(
          response['message'], contains('Missing required parameter: action'));
    });

    test('should format time correctly', () async {
      await ActivityMemoryService.logActivity(
        activityCode: 'T8',
        activityName: 'Test activity',
        dimension: 'TG',
        source: 'Test',
      );

      final command = '{"action": "get_activity_stats"}';
      final result = await mcpService.processCommand(command);

      final response = json.decode(result);
      final activity = response['data']['activities'][0];

      // Time should be in HH:MM format
      expect(activity['time'], matches(RegExp(r'^\d{2}:\d{2}$')));

      // Full timestamp should be ISO8601
      expect(activity['full_timestamp'], contains('T'));
      expect(() => DateTime.parse(activity['full_timestamp']), returnsNormally);
    });
  });
}
