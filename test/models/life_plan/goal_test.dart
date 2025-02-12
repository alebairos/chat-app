import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/models/life_plan/goal.dart';

void main() {
  group('Goal Model', () {
    test('creates Goal from CSV row', () {
      final csvRow = ['SF', 'OPP1', 'Perder peso', 'ME1'];
      final goal = Goal.fromCsv(csvRow);

      expect(goal.dimension, equals('SF'));
      expect(goal.id, equals('OPP1'));
      expect(goal.description, equals('Perder peso'));
      expect(goal.trackId, equals('ME1'));
    });

    test('handles empty or null values in CSV row', () {
      final csvRow = ['SF', '', null, 'ME1'];
      final goal = Goal.fromCsv(csvRow);

      expect(goal.dimension, equals('SF'));
      expect(goal.id, equals(''));
      expect(goal.description, equals('null'));
      expect(goal.trackId, equals('ME1'));
    });

    test('correctly matches dimension', () {
      final goal = Goal(
        dimension: 'SF',
        id: 'OPP1',
        description: 'Perder peso',
        trackId: 'ME1',
      );

      expect(goal.matchesDimension('SF'), isTrue);
      expect(goal.matchesDimension('SM'), isFalse);
    });

    test('toString returns formatted string', () {
      final goal = Goal(
        dimension: 'SF',
        id: 'OPP1',
        description: 'Perder peso',
        trackId: 'ME1',
      );

      expect(
        goal.toString(),
        equals(
            'Goal(dimension: SF, id: OPP1, description: Perder peso, trackId: ME1)'),
      );
    });

    group('LifeDimension Constants', () {
      test('contains all required dimensions', () {
        expect(LifeDimension.physical, equals('SF'));
        expect(LifeDimension.mental, equals('SM'));
        expect(LifeDimension.relationships, equals('R'));
        expect(LifeDimension.work, equals('T'));
        expect(LifeDimension.spiritual, equals('E'));
      });
    });
  });
}
