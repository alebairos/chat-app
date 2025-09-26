import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/flat_metadata_parser.dart';

/// FT-149: Simple integration test for flat metadata end-to-end flow
void main() {
  group('FT-149 Metadata Integration', () {
    testWidgets('flat metadata parser integrates with UI display format',
        (tester) async {
      // Simulate activity metadata as would be extracted from LLM response
      final activityMetadata = {
        'quantitative_volume_value': 500,
        'quantitative_volume_unit': 'ml',
        'quantitative_steps_value': 1200,
        'quantitative_steps_unit': 'steps',
        // Non-quantitative fields should be ignored
        'confidence': 'high',
        'reasoning': 'User mentioned activity'
      };

      // Test flat metadata detection
      expect(FlatMetadataParser.hasQuantitativeData(activityMetadata), isTrue);

      // Test flat metadata extraction
      final measurements =
          FlatMetadataParser.extractQuantitative(activityMetadata);
      expect(measurements.length, equals(2));

      // Verify volume measurement
      final volumeMeasurement =
          measurements.firstWhere((m) => m['key'] == 'volume');
      expect(volumeMeasurement['value'], equals('500'));
      expect(volumeMeasurement['unit'], equals('ml'));
      expect(volumeMeasurement['display'], equals('500 ml'));
      expect(volumeMeasurement['icon'], equals('💧'));

      // Verify steps measurement
      final stepsMeasurement =
          measurements.firstWhere((m) => m['key'] == 'steps');
      expect(stepsMeasurement['value'], equals('1200'));
      expect(stepsMeasurement['unit'], equals('steps'));
      expect(stepsMeasurement['display'], equals('1200 steps'));
      expect(stepsMeasurement['icon'], equals('👣'));

      // Verify UI display formatting (as used in MetadataInsights widget)
      final insights =
          measurements.map((m) => '${m["icon"]} ${m["display"]}').join(' • ');
      expect(insights, equals('💧 500 ml • 👣 1200 steps'));
    });

    testWidgets('handles metadata without quantitative data gracefully',
        (tester) async {
      // Simulate activity metadata without quantitative fields
      final activityMetadata = {
        'confidence': 'high',
        'reasoning': 'User mentioned activity',
        'behavioral_mood': 'positive'
      };

      // Verify no quantitative data detected
      expect(FlatMetadataParser.hasQuantitativeData(activityMetadata), isFalse);

      // Verify parser returns empty list
      expect(FlatMetadataParser.extractQuantitative(activityMetadata).isEmpty,
          isTrue);
    });
  });
}
