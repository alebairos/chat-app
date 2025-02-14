import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/life_plan/models/life_plan_command.dart';

void main() {
  group('LifePlanCommand', () {
    group('Command Type Tests', () {
      test('correctly identifies plan command', () {
        final command = LifePlanCommand.fromText('/plan');
        expect(command.type, equals(LifePlanCommandType.plan));
        expect(command.dimension, isNull);
      });

      test('correctly identifies explore command without dimension', () {
        final command = LifePlanCommand.fromText('/explore');
        expect(command.type, equals(LifePlanCommandType.explore));
        expect(command.dimension, isNull);
      });

      test('correctly identifies explore command with valid dimension', () {
        final command = LifePlanCommand.fromText('/explore SF');
        expect(command.type, equals(LifePlanCommandType.explore));
        expect(command.dimension, equals(LifePlanDimension.physical));
      });

      test('handles explore command with invalid dimension', () {
        final command = LifePlanCommand.fromText('/explore INVALID');
        expect(command.type, equals(LifePlanCommandType.explore));
        expect(command.dimension, isNull);
      });

      test('defaults to help command for unknown commands', () {
        final command = LifePlanCommand.fromText('/unknown');
        expect(command.type, equals(LifePlanCommandType.help));
        expect(command.dimension, isNull);
      });
    });

    group('Command Validation Tests', () {
      test('correctly identifies valid commands', () {
        expect(LifePlanCommand.isCommand('/plan'), isTrue);
        expect(LifePlanCommand.isCommand('/explore'), isTrue);
        expect(LifePlanCommand.isCommand('/help'), isTrue);
      });

      test('correctly identifies invalid commands', () {
        expect(LifePlanCommand.isCommand('plan'), isFalse);
        expect(LifePlanCommand.isCommand('not a command'), isFalse);
        expect(LifePlanCommand.isCommand(''), isFalse);
        expect(LifePlanCommand.isCommand('/invalid'), isFalse);
      });

      test('handles whitespace in commands', () {
        expect(LifePlanCommand.isCommand('  /plan  '), isTrue);
        expect(LifePlanCommand.isCommand('/explore SF  '), isTrue);
      });
    });

    group('LifePlanDimension Tests', () {
      test('correctly maps dimension codes', () {
        expect(LifePlanDimension.fromCode('SF'),
            equals(LifePlanDimension.physical));
        expect(
            LifePlanDimension.fromCode('SM'), equals(LifePlanDimension.mental));
        expect(LifePlanDimension.fromCode('R'),
            equals(LifePlanDimension.relationships));
      });

      test('handles case-insensitive dimension codes', () {
        expect(LifePlanDimension.fromCode('sf'),
            equals(LifePlanDimension.physical));
        expect(
            LifePlanDimension.fromCode('sm'), equals(LifePlanDimension.mental));
        expect(LifePlanDimension.fromCode('r'),
            equals(LifePlanDimension.relationships));
      });

      test('throws ArgumentError for invalid dimension codes', () {
        expect(
            () => LifePlanDimension.fromCode('INVALID'), throwsArgumentError);
        expect(() => LifePlanDimension.fromCode(''), throwsArgumentError);
      });

      test('dimensions have correct properties', () {
        expect(LifePlanDimension.physical.code, equals('SF'));
        expect(LifePlanDimension.physical.emoji, equals('💪'));
        expect(LifePlanDimension.physical.title, equals('Physical Realm'));

        expect(LifePlanDimension.mental.code, equals('SM'));
        expect(LifePlanDimension.mental.emoji, equals('🧠'));
        expect(LifePlanDimension.mental.title, equals('Mental Domain'));

        expect(LifePlanDimension.relationships.code, equals('R'));
        expect(LifePlanDimension.relationships.emoji, equals('❤️'));
        expect(LifePlanDimension.relationships.title,
            equals('Relationships Kingdom'));
      });
    });

    group('Command Type String Tests', () {
      test('command types have correct string representations', () {
        expect(LifePlanCommandType.plan.command, equals('/plan'));
        expect(LifePlanCommandType.explore.command, equals('/explore'));
        expect(LifePlanCommandType.help.command, equals('/help'));
      });
    });
  });
}
