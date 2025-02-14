import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/models/life_plan/track.dart';

void main() {
  group('Track Model', () {
    test('creates Track from CSV rows', () {
      final csvRows = [
        [
          'SF',
          'ER1',
          'Energia recarregada',
          'ER1PC',
          'Primeiro contato',
          '1',
          'SF1',
          '7'
        ],
        [
          'SF',
          'ER1',
          'Energia recarregada',
          'ER1PC',
          'Primeiro contato',
          '1',
          'SF18',
          '3'
        ],
        [
          'SF',
          'ER1',
          'Energia recarregada',
          'ER1PC',
          'Primeiro contato',
          '1',
          'SM1',
          '7'
        ],
      ];

      final track = Track.fromCsvRows(csvRows);

      expect(track.dimension, equals('SF'));
      expect(track.code, equals('ER1'));
      expect(track.name, equals('Energia recarregada'));
      expect(track.challenges.length, equals(1));

      final challenge = track.challenges.first;
      expect(challenge.code, equals('ER1PC'));
      expect(challenge.name, equals('Primeiro contato'));
      expect(challenge.level, equals(1));
      expect(challenge.habits.length, equals(3));

      expect(challenge.habits[0].habitId, equals('SF1'));
      expect(challenge.habits[0].frequency, equals(7));
      expect(challenge.habits[1].habitId, equals('SF18'));
      expect(challenge.habits[1].frequency, equals(3));
      expect(challenge.habits[2].habitId, equals('SM1'));
      expect(challenge.habits[2].frequency, equals(7));
    });

    test('handles empty rows', () {
      final track = Track.fromCsvRows([]);

      expect(track.dimension, isEmpty);
      expect(track.code, isEmpty);
      expect(track.name, isEmpty);
      expect(track.challenges, isEmpty);
    });

    test('groups multiple challenges correctly', () {
      final csvRows = [
        [
          'SF',
          'ER1',
          'Energia recarregada',
          'ER1PC',
          'Primeiro contato',
          '1',
          'SF1',
          '7'
        ],
        [
          'SF',
          'ER1',
          'Energia recarregada',
          'ER1PC',
          'Primeiro contato',
          '1',
          'SF18',
          '3'
        ],
        [
          'SF',
          'ER1',
          'Energia recarregada',
          'ER2AV',
          'Avançado',
          '2',
          'SF2',
          '5'
        ],
        [
          'SF',
          'ER1',
          'Energia recarregada',
          'ER2AV',
          'Avançado',
          '2',
          'SF20',
          '4'
        ],
      ];

      final track = Track.fromCsvRows(csvRows);

      expect(track.challenges.length, equals(2));

      final basicChallenge = track.getChallengeByCode('ER1PC');
      expect(basicChallenge, isNotNull);
      expect(basicChallenge!.name, equals('Primeiro contato'));
      expect(basicChallenge.level, equals(1));
      expect(basicChallenge.habits.length, equals(2));

      final advancedChallenge = track.getChallengeByCode('ER2AV');
      expect(advancedChallenge, isNotNull);
      expect(advancedChallenge!.name, equals('Avançado'));
      expect(advancedChallenge.level, equals(2));
      expect(advancedChallenge.habits.length, equals(2));
    });

    test('handles invalid level values', () {
      final csvRows = [
        ['SF', 'ER1', 'Energia', 'ER1PC', 'Basic', 'invalid', 'SF1', '7'],
      ];

      final track = Track.fromCsvRows(csvRows);
      final challenge = track.challenges.first;

      expect(challenge.level, equals(1)); // Default level
    });

    test('handles invalid frequency values', () {
      final csvRows = [
        ['SF', 'ER1', 'Energia', 'ER1PC', 'Basic', '1', 'SF1', 'invalid'],
      ];

      final track = Track.fromCsvRows(csvRows);
      final habit = track.challenges.first.habits.first;

      expect(habit.frequency, equals(0)); // Default frequency
    });

    test('getChallengeByCode returns null for non-existent code', () {
      final track = Track(
        dimension: 'SF',
        code: 'ER1',
        name: 'Energia',
        challenges: [
          Challenge(
            code: 'ER1PC',
            name: 'Basic',
            level: 1,
            habits: [],
          ),
        ],
      );

      expect(track.getChallengeByCode('NONEXISTENT'), isNull);
    });

    group('toString methods', () {
      test('Track toString includes essential information', () {
        final track = Track(
          dimension: 'SF',
          code: 'ER1',
          name: 'Energia',
          challenges: [],
        );

        expect(track.toString(), contains('dimension: SF'));
        expect(track.toString(), contains('code: ER1'));
        expect(track.toString(), contains('name: Energia'));
      });

      test('Challenge toString includes essential information', () {
        final challenge = Challenge(
          code: 'ER1PC',
          name: 'Basic',
          level: 1,
          habits: [],
        );

        expect(challenge.toString(), contains('code: ER1PC'));
        expect(challenge.toString(), contains('name: Basic'));
        expect(challenge.toString(), contains('level: 1'));
      });

      test('TrackHabit toString includes essential information', () {
        final habit = TrackHabit(
          habitId: 'SF1',
          frequency: 7,
        );

        expect(habit.toString(), contains('habitId: SF1'));
        expect(habit.toString(), contains('frequency: 7'));
      });
    });
  });
}
