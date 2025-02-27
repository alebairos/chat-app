import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/life_plan/models/life_plan_command.dart';
import 'package:character_ai_clone/models/life_plan/dimensions.dart';

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
        expect(LifePlanDimension.fromCode(Dimensions.physical.code),
            equals(LifePlanDimension.physical));
        expect(LifePlanDimension.fromCode(Dimensions.mental.code),
            equals(LifePlanDimension.mental));
        expect(LifePlanDimension.fromCode(Dimensions.relationships.code),
            equals(LifePlanDimension.relationships));
        expect(LifePlanDimension.fromCode(Dimensions.spirituality.code),
            equals(LifePlanDimension.spirituality));
        expect(LifePlanDimension.fromCode(Dimensions.work.code),
            equals(LifePlanDimension.work));
      });

      test('handles case-insensitive dimension codes', () {
        expect(
            LifePlanDimension.fromCode(Dimensions.physical.code.toLowerCase()),
            equals(LifePlanDimension.physical));
        expect(LifePlanDimension.fromCode(Dimensions.mental.code.toLowerCase()),
            equals(LifePlanDimension.mental));
        expect(
            LifePlanDimension.fromCode(
                Dimensions.relationships.code.toLowerCase()),
            equals(LifePlanDimension.relationships));
        expect(
            LifePlanDimension.fromCode(
                Dimensions.spirituality.code.toLowerCase()),
            equals(LifePlanDimension.spirituality));
        expect(LifePlanDimension.fromCode(Dimensions.work.code.toLowerCase()),
            equals(LifePlanDimension.work));
      });

      test('throws ArgumentError for invalid dimension codes', () {
        expect(
            () => LifePlanDimension.fromCode('INVALID'), throwsArgumentError);
        expect(() => LifePlanDimension.fromCode(''), throwsArgumentError);
      });

      test('dimensions have correct properties', () {
        expect(
            LifePlanDimension.physical.code, equals(Dimensions.physical.code));
        expect(LifePlanDimension.physical.emoji,
            equals(Dimensions.physical.emoji));
        expect(LifePlanDimension.physical.title,
            equals(Dimensions.physical.title));

        expect(LifePlanDimension.mental.code, equals(Dimensions.mental.code));
        expect(LifePlanDimension.mental.emoji, equals(Dimensions.mental.emoji));
        expect(LifePlanDimension.mental.title, equals(Dimensions.mental.title));

        expect(LifePlanDimension.relationships.code,
            equals(Dimensions.relationships.code));
        expect(LifePlanDimension.relationships.emoji,
            equals(Dimensions.relationships.emoji));
        expect(LifePlanDimension.relationships.title,
            equals(Dimensions.relationships.title));

        expect(LifePlanDimension.spirituality.code,
            equals(Dimensions.spirituality.code));
        expect(LifePlanDimension.spirituality.emoji,
            equals(Dimensions.spirituality.emoji));
        expect(LifePlanDimension.spirituality.title,
            equals(Dimensions.spirituality.title));

        expect(LifePlanDimension.work.code, equals(Dimensions.work.code));
        expect(LifePlanDimension.work.emoji, equals(Dimensions.work.emoji));
        expect(LifePlanDimension.work.title, equals(Dimensions.work.title));
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
