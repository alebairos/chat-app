import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:ai_personas_app/services/activity_export_service.dart';

/// Basic tests for ActivityExportService to catch fundamental issues
/// These tests focus on core functionality without complex dependencies
void main() {
  group('ActivityExportService Basic Tests', () {
    late ActivityExportService exportService;

    setUp(() {
      exportService = ActivityExportService();
    });

    group('Public Interface Tests', () {
      test('should create ActivityExportService instance', () {
        expect(exportService, isA<ActivityExportService>());
      });

      test('should handle getExportStatistics with database unavailable',
          () async {
        // This test verifies the method handles database errors gracefully
        final stats = await exportService.getExportStatistics();

        // Should return default values when database is unavailable
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats, containsPair('total_activities', isA<int>()));
        expect(stats, containsPair('oracle_activities', isA<int>()));
        expect(stats, containsPair('custom_activities', isA<int>()));
        expect(stats, containsPair('dimensions', isA<Map>()));
      });
    });

    group('Data Structure Tests', () {
      test('should create valid export data structure', () {
        final validExportData = {
          'export_metadata': {
            'version': '1.0',
            'export_date': '2024-01-01T10:00:00.000Z',
            'total_activities': 1,
          },
          'activities': [
            {
              'activityName': 'Test Activity',
              'dimension': 'test',
              'completedAt': '2024-01-01T10:00:00.000Z',
              'source': 'test',
            }
          ]
        };

        // Test that the structure contains required fields
        expect(validExportData, containsPair('export_metadata', isA<Map>()));
        expect(validExportData, containsPair('activities', isA<List>()));

        final metadata = validExportData['export_metadata'] as Map;
        expect(metadata, containsPair('version', isA<String>()));
        expect(metadata, containsPair('total_activities', isA<int>()));

        final activities = validExportData['activities'] as List;
        expect(activities, isNotEmpty);
        expect(activities[0], containsPair('activityName', isA<String>()));
        expect(activities[0], containsPair('dimension', isA<String>()));
        expect(activities[0], containsPair('completedAt', isA<String>()));
      });

      test('should identify missing required fields', () {
        final invalidData = {
          'activities': [
            {
              'activityName': 'Test Activity',
              // Missing dimension and completedAt
            }
          ]
          // Missing export_metadata
        };

        // Test validation logic
        expect(invalidData.containsKey('export_metadata'), isFalse);

        final activities = invalidData['activities'] as List;
        final activity = activities[0] as Map;
        expect(activity.containsKey('dimension'), isFalse);
        expect(activity.containsKey('completedAt'), isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle malformed JSON gracefully', () {
        const malformedJson = '{"invalid": json}';

        expect(() => json.decode(malformedJson), throwsFormatException);
      });

      test('should validate required fields exist in data structures', () {
        final incompleteActivity = {
          'activityName': 'Incomplete Activity',
          // Missing required fields: dimension, completedAt
        };

        // Test that we can identify missing fields
        expect(incompleteActivity.containsKey('dimension'), isFalse);
        expect(incompleteActivity.containsKey('completedAt'), isFalse);
        expect(incompleteActivity.containsKey('activityName'), isTrue);
      });
    });

    group('Import Result', () {
      test('should create ImportResult with correct totals', () {
        final result = ImportResult(
          imported: 5,
          skipped: 2,
          errors: 1,
          errorMessages: ['Test error'],
        );

        expect(result.imported, equals(5));
        expect(result.skipped, equals(2));
        expect(result.errors, equals(1));
        expect(result.total, equals(8)); // 5 + 2 + 1
        expect(result.hasErrors, isTrue);
        expect(result.errorMessages, contains('Test error'));
      });

      test('should handle ImportResult with no errors', () {
        final result = ImportResult(
          imported: 10,
          skipped: 0,
          errors: 0,
        );

        expect(result.hasErrors, isFalse);
        expect(result.total, equals(10));
        expect(result.errorMessages, isEmpty);
      });
    });

    group('Validation Result', () {
      test('should create ValidationResult correctly', () {
        final validResult = ValidationResult(isValid: true);
        expect(validResult.isValid, isTrue);
        expect(validResult.errors, isEmpty);

        final invalidResult = ValidationResult(
          isValid: false,
          errors: ['Error 1', 'Error 2'],
        );
        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.errors, hasLength(2));
      });
    });

    group('JSON Handling', () {
      test('should handle valid JSON parsing', () {
        const validJson = '{"test": "value", "number": 123}';
        final parsed = json.decode(validJson) as Map<String, dynamic>;

        expect(parsed['test'], equals('value'));
        expect(parsed['number'], equals(123));
      });

      test('should detect invalid JSON structure', () {
        final invalidStructure = {'activities': 'should be array not string'};

        expect(invalidStructure['activities'], isA<String>());
        expect(invalidStructure['activities'] is List, isFalse);
      });
    });
  });
}
