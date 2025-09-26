import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/flat_metadata_parser.dart';

void main() {
  group('FlatMetadataParser', () {
    testWidgets('extracts basic quantitative measurements', (tester) async {
      final metadata = {
        'quantitative_steps_value': 7000,
        'quantitative_steps_unit': 'steps',
        'quantitative_distance_value': 400,
        'quantitative_distance_unit': 'meters',
        'behavioral_mood': 'positive', // Should be ignored
        'contextual_timing': 'afternoon', // Should be ignored
      };

      final results = FlatMetadataParser.extractQuantitative(metadata);

      expect(results.length, equals(2));

      // Check steps measurement
      final stepsResult = results.firstWhere((item) => item['key'] == 'steps');
      expect(stepsResult['value'], equals('7000'));
      expect(stepsResult['unit'], equals('steps'));
      expect(stepsResult['display'], equals('7000 steps'));
      expect(stepsResult['icon'], equals('👣'));

      // Check distance measurement
      final distanceResult =
          results.firstWhere((item) => item['key'] == 'distance');
      expect(distanceResult['value'], equals('400'));
      expect(distanceResult['unit'], equals('meters'));
      expect(distanceResult['display'], equals('400 meters'));
      expect(distanceResult['icon'], equals('📏'));
    });

    testWidgets('handles missing units with fallback inference',
        (tester) async {
      final metadata = {
        'quantitative_weight_value': 10,
        // Missing unit - should infer 'kg'
        'quantitative_volume_value': 250,
        'quantitative_volume_unit': 'ml',
      };

      final results = FlatMetadataParser.extractQuantitative(metadata);

      expect(results.length, equals(2));

      // Check weight with inferred unit
      final weightResult =
          results.firstWhere((item) => item['key'] == 'weight');
      expect(weightResult['value'], equals('10'));
      expect(weightResult['unit'], equals('kg')); // Inferred
      expect(weightResult['display'], equals('10 kg'));
      expect(weightResult['icon'], equals('🏋️'));
    });

    testWidgets('detects flat structure correctly', (tester) async {
      final flatMetadata = {
        'quantitative_steps_value': 7000,
        'quantitative_steps_unit': 'steps',
      };

      final nestedMetadata = {
        'quantitative': {
          'steps': {'value': 7000, 'unit': 'steps'}
        }
      };

      final noQuantitativeMetadata = {
        'behavioral_mood': 'positive',
        'contextual_timing': 'afternoon',
      };

      expect(FlatMetadataParser.hasQuantitativeData(flatMetadata), isTrue);
      expect(FlatMetadataParser.hasQuantitativeData(nestedMetadata), isFalse);
      expect(FlatMetadataParser.hasQuantitativeData(noQuantitativeMetadata),
          isFalse);
    });

    testWidgets('gets available measurements correctly', (tester) async {
      final metadata = {
        'quantitative_steps_value': 7000,
        'quantitative_distance_value': 400,
        'quantitative_weight_value': 10,
        'behavioral_mood': 'positive', // Should be ignored
      };

      final measurements =
          FlatMetadataParser.getAvailableMeasurements(metadata);

      expect(measurements.length, equals(3));
      expect(measurements, contains('steps'));
      expect(measurements, contains('distance'));
      expect(measurements, contains('weight'));
      expect(measurements, isNot(contains('behavioral')));
    });

    testWidgets('handles empty metadata gracefully', (tester) async {
      final emptyMetadata = <String, dynamic>{};

      final results = FlatMetadataParser.extractQuantitative(emptyMetadata);
      final measurements =
          FlatMetadataParser.getAvailableMeasurements(emptyMetadata);
      final hasData = FlatMetadataParser.hasQuantitativeData(emptyMetadata);

      expect(results, isEmpty);
      expect(measurements, isEmpty);
      expect(hasData, isFalse);
    });

    testWidgets('prevents duplicate measurements', (tester) async {
      final metadata = {
        'quantitative_steps_value': 7000,
        'quantitative_steps_unit': 'steps',
        // This shouldn't create a duplicate since we process by measurement type
      };

      final results = FlatMetadataParser.extractQuantitative(metadata);

      expect(results.length, equals(1));
      expect(results[0]['key'], equals('steps'));
    });

    testWidgets('handles all supported measurement types', (tester) async {
      final metadata = {
        'quantitative_steps_value': 7000,
        'quantitative_steps_unit': 'steps',
        'quantitative_distance_value': 5000,
        'quantitative_distance_unit': 'meters',
        'quantitative_volume_value': 250,
        'quantitative_volume_unit': 'ml',
        'quantitative_weight_value': 10,
        'quantitative_weight_unit': 'kg',
        'quantitative_duration_value': 30,
        'quantitative_duration_unit': 'minutes',
        'quantitative_reps_value': 12,
        'quantitative_reps_unit': 'reps',
        'quantitative_sets_value': 3,
        'quantitative_sets_unit': 'sets',
      };

      final results = FlatMetadataParser.extractQuantitative(metadata);

      expect(results.length, equals(7));

      final measurementTypes = results.map((item) => item['key']).toSet();
      expect(measurementTypes, contains('steps'));
      expect(measurementTypes, contains('distance'));
      expect(measurementTypes, contains('volume'));
      expect(measurementTypes, contains('weight'));
      expect(measurementTypes, contains('duration'));
      expect(measurementTypes, contains('reps'));
      expect(measurementTypes, contains('sets'));
    });
  });
}
