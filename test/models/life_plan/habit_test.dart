import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/models/life_plan/habit.dart';

void main() {
  group('Habit Model', () {
    test('creates Habit from CSV row', () {
      final csvRow = [
        'R1',
        'Praticar escuta ativa',
        'Alta',
        '30min',
        '5',
        '1',
        '0',
        '0',
        '2'
      ];
      final habit = Habit.fromCsv(csvRow);

      expect(habit.id, equals('R1'));
      expect(habit.description, equals('Praticar escuta ativa'));
      expect(habit.intensity, equals('Alta'));
      expect(habit.duration, equals('30min'));
      expect(habit.impact.relationships, equals(5));
      expect(habit.impact.work, equals(1));
      expect(habit.impact.physical, equals(0));
      expect(habit.impact.spiritual, equals(0));
      expect(habit.impact.mental, equals(2));
    });

    test('handles invalid impact values in CSV row', () {
      final csvRow = [
        'R1',
        'Praticar escuta ativa',
        'Alta',
        '30min',
        'invalid',
        '',
        null,
        'x',
        '2'
      ];
      final habit = Habit.fromCsv(csvRow);

      expect(habit.impact.relationships, equals(0));
      expect(habit.impact.work, equals(0));
      expect(habit.impact.physical, equals(0));
      expect(habit.impact.spiritual, equals(0));
      expect(habit.impact.mental, equals(2));
    });

    test('toString returns formatted string', () {
      final habit = Habit(
        id: 'R1',
        description: 'Praticar escuta ativa',
        impact: HabitImpact(
          relationships: 5,
          work: 1,
          physical: 0,
          spiritual: 0,
          mental: 2,
        ),
      );

      expect(habit.toString(),
          equals('Habit(id: R1, description: Praticar escuta ativa)'));
    });

    group('HabitImpact', () {
      late HabitImpact impact;

      setUp(() {
        impact = HabitImpact(
          relationships: 5,
          work: 1,
          physical: 0,
          spiritual: 0,
          mental: 2,
        );
      });

      test('returns correct impact for each dimension', () {
        expect(impact.getImpactForDimension('R'), equals(5));
        expect(impact.getImpactForDimension('T'), equals(1));
        expect(impact.getImpactForDimension('SF'), equals(0));
        expect(impact.getImpactForDimension('E'), equals(0));
        expect(impact.getImpactForDimension('SM'), equals(2));
      });

      test('returns 0 for unknown dimension', () {
        expect(impact.getImpactForDimension('UNKNOWN'), equals(0));
      });
    });

    test('getImpactForDimension delegates to HabitImpact', () {
      final habit = Habit(
        id: 'R1',
        description: 'Praticar escuta ativa',
        impact: HabitImpact(
          relationships: 5,
          work: 1,
          physical: 0,
          spiritual: 0,
          mental: 2,
        ),
      );

      expect(habit.getImpactForDimension('R'), equals(5));
      expect(habit.getImpactForDimension('UNKNOWN'), equals(0));
    });
  });
}
