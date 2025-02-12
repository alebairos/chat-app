import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/services/life_plan_service.dart';
import 'package:character_ai_clone/models/life_plan/index.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LifePlanService service;

  // Mock CSV data
  const mockGoalsData = '''dimension;id;description;trackId
SF;OPP1;Perder peso;ME1
SM;OMS1;Meditar diariamente;ME2
R;OR1;Melhorar relacionamentos;RE1''';

  const mockHabitsData = '''id;description;intensity;duration;R;T;SF;E;SM
SF1;Exercício;Alta;30min;0;0;5;0;2
SM1;Meditação;Média;15min;0;1;0;3;5
R1;Escuta ativa;Alta;30min;5;2;0;0;1''';

  const mockTracksData =
      '''dimension;trackCode;trackName;challengeCode;challengeName;level;habitId;frequency
SF;ME1;Energia;ME1PC;Primeiro Contato;1;SF1;7
SF;ME1;Energia;ME1PC;Primeiro Contato;1;SM1;3
SM;ME2;Mente;ME2PC;Básico;1;SM1;5''';

  setUp(() async {
    // Create a mock root bundle
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        if (message == null) return null;
        final key = utf8.decode(message.buffer.asUint8List());
        print('Loading asset: $key'); // Debug log
        String data;
        switch (key) {
          case 'assets/data/Objetivos.csv':
            data = mockGoalsData;
            print('Returning goals data: $data'); // Debug log
            break;
          case 'assets/data/habitos.csv':
            data = mockHabitsData;
            print('Returning habits data: $data'); // Debug log
            break;
          case 'assets/data/Trilhas.csv':
            data = mockTracksData;
            print('Returning tracks data: $data'); // Debug log
            break;
          default:
            print('Unknown asset requested: $key'); // Debug log
            return null;
        }
        return ByteData.sublistView(utf8.encode(data));
      },
    );

    service = LifePlanService();
    await service.initialize();

    // Debug logs after initialization
    print('Goals loaded: ${service.goals.length}');
    print('Habits loaded: ${service.habits.length}');
    print('Tracks loaded: ${service.tracks.length}');
  });

  group('LifePlanService', () {
    test('loads goals correctly', () {
      expect(service.goals.length, equals(3));

      final physicalGoal = service.goals.first;
      expect(physicalGoal.dimension, equals('SF'));
      expect(physicalGoal.id, equals('OPP1'));
      expect(physicalGoal.description, equals('Perder peso'));
      expect(physicalGoal.trackId, equals('ME1'));
    });

    test('loads habits correctly', () {
      expect(service.habits.length, equals(3));

      final exerciseHabit = service.habits.first;
      expect(exerciseHabit.id, equals('SF1'));
      expect(exerciseHabit.description, equals('Exercício'));
      expect(exerciseHabit.impact.physical, equals(5));
      expect(exerciseHabit.impact.mental, equals(2));
    });

    test('loads tracks correctly', () {
      expect(service.tracks.length, equals(2)); // ME1 and ME2

      final energyTrack = service.tracks['ME1'];
      expect(energyTrack, isNotNull);
      expect(energyTrack!.name, equals('Energia'));
      expect(energyTrack.challenges.length, equals(1));
      expect(energyTrack.challenges.first.habits.length, equals(2));
    });

    test('getGoalsByDimension returns correct goals', () {
      final physicalGoals = service.getGoalsByDimension('SF');
      expect(physicalGoals.length, equals(1));
      expect(physicalGoals.first.description, equals('Perder peso'));

      final mentalGoals = service.getGoalsByDimension('SM');
      expect(mentalGoals.length, equals(1));
      expect(mentalGoals.first.description, equals('Meditar diariamente'));
    });

    test('getHabitById returns correct habit', () {
      final habit = service.getHabitById('SF1');
      expect(habit, isNotNull);
      expect(habit!.description, equals('Exercício'));

      final nonExistentHabit = service.getHabitById('INVALID');
      expect(nonExistentHabit, isNull);
    });

    test('getTrackById returns correct track', () {
      final track = service.getTrackById('ME1');
      expect(track, isNotNull);
      expect(track!.name, equals('Energia'));

      final nonExistentTrack = service.getTrackById('INVALID');
      expect(nonExistentTrack, isNull);
    });

    test('getHabitsForChallenge returns correct habits', () {
      final habits = service.getHabitsForChallenge('ME1', 'ME1PC');
      expect(habits.length, equals(2));
      expect(habits.map((h) => h.id).toList(), equals(['SF1', 'SM1']));

      final noHabits = service.getHabitsForChallenge('INVALID', 'INVALID');
      expect(noHabits, isEmpty);
    });

    test('getRecommendedHabits returns habits above impact threshold', () {
      final physicalHabits = service.getRecommendedHabits('SF', minImpact: 3);
      expect(physicalHabits.length, equals(1));
      expect(physicalHabits.first.id, equals('SF1'));

      final mentalHabits = service.getRecommendedHabits('SM', minImpact: 4);
      expect(mentalHabits.length, equals(1));
      expect(mentalHabits.first.id, equals('SM1'));
    });

    test('singleton instance works correctly', () {
      final service1 = LifePlanService();
      final service2 = LifePlanService();
      expect(identical(service1, service2), isTrue);
    });
  });
}
