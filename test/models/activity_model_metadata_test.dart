import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/models/activity_model.dart';

/// FT-149: Test ActivityModel metadata storage and retrieval
void main() {
  group('ActivityModel Metadata Storage', () {
    testWidgets('stores and retrieves quantitative metadata correctly',
        (tester) async {
      final metadata = {
        'quantitative_steps_value': 7000,
        'quantitative_steps_unit': 'steps',
        'quantitative_volume_value': 500,
        'quantitative_volume_unit': 'ml'
      };

      final activity = ActivityModel.fromDetection(
        activityCode: 'SF15',
        activityName: 'Caminhar 7000 passos',
        dimension: 'SF',
        source: 'FT-149 Test',
        completedAt: DateTime.now(),
        dayOfWeek: 'Wednesday',
        timeOfDay: 'afternoon',
        metadata: metadata,
      );

      // Verify metadata is stored as JSON string
      expect(activity.metadata, isNotNull);

      // Parse stored metadata
      final storedMetadata = jsonDecode(activity.metadata!);
      expect(storedMetadata['quantitative_steps_value'], equals(7000));
      expect(storedMetadata['quantitative_steps_unit'], equals('steps'));
      expect(storedMetadata['quantitative_volume_value'], equals(500));
      expect(storedMetadata['quantitative_volume_unit'], equals('ml'));
    });

    testWidgets('handles empty metadata correctly', (tester) async {
      final activity = ActivityModel.fromDetection(
        activityCode: 'SF1',
        activityName: 'Beber água',
        dimension: 'SF',
        source: 'FT-149 Test',
        completedAt: DateTime.now(),
        dayOfWeek: 'Wednesday',
        timeOfDay: 'afternoon',
        // No metadata passed - should default to empty
      );

      // Verify metadata is null for empty metadata
      expect(activity.metadata, isNull);
    });

    testWidgets('custom activities have no metadata', (tester) async {
      final activity = ActivityModel.custom(
        activityName: 'Custom activity',
        dimension: 'custom',
        completedAt: DateTime.now(),
        dayOfWeek: 'Wednesday',
        timeOfDay: 'afternoon',
      );

      // Verify custom activities have no metadata
      expect(activity.metadata, isNull);
    });
  });
}
