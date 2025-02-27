import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/life_plan/models/life_plan_response.dart';
import 'package:character_ai_clone/life_plan/models/life_plan_command.dart';

void main() {
  group('LifePlanResponse', () {
    group('Error Response Tests', () {
      test('creates error response with correct formatting', () {
        final response = LifePlanResponse.error('Test error message');

        expect(response.isError, isTrue);
        expect(response.message, contains('*adjusts spectacles* `🧐`'));
        expect(response.message, contains('Test error message'));
      });
    });

    group('Plan Response Tests', () {
      test('creates plan response with all dimensions', () {
        final response = LifePlanResponse.plan();

        expect(response.isError, isFalse);
        expect(response.message, contains('*adjusts chronometer* `⚔️`'));
        expect(response.message, contains('Salve, time wanderer!'));
        expect(response.message, contains('Choose a dimension:'));
        expect(response.message, contains('SF: Physical Health'));
        expect(response.message, contains('SM: Mental Health'));
        expect(response.message, contains('R: Relationships'));
      });
    });

    group('Explore Response Tests', () {
      test('creates explore response for physical dimension', () {
        final response = LifePlanResponse.explore(LifePlanDimension.physical);

        expect(response.isError, isFalse);
        expect(response.message, contains('*consults ancient map* `💪`'));
        expect(response.message.toLowerCase(), contains('physical realm'));
        expect(response.message, contains('noble choice'));
      });

      test('creates explore response for mental dimension', () {
        final response = LifePlanResponse.explore(LifePlanDimension.mental);

        expect(response.isError, isFalse);
        expect(response.message, contains('*consults ancient map* `🧠`'));
        expect(response.message.toLowerCase(), contains('mental domain'));
        expect(response.message, contains('noble choice'));
      });

      test('creates explore response for relationships dimension', () {
        final response =
            LifePlanResponse.explore(LifePlanDimension.relationships);

        expect(response.isError, isFalse);
        expect(response.message, contains('*consults ancient map* `❤️`'));
        expect(
            response.message.toLowerCase(), contains('relationships kingdom'));
        expect(response.message, contains('noble choice'));
      });

      test('creates error response for null dimension', () {
        final response = LifePlanResponse.explore(null);

        expect(response.isError, isTrue);
        expect(response.message,
            contains('Which dimension would you like to explore?'));
        expect(response.message, contains('SF for Physical'));
        expect(response.message, contains('SM for Mental'));
        expect(response.message, contains('R for Relationships'));
      });
    });

    group('Help Response Tests', () {
      test('creates help response with all commands', () {
        final response = LifePlanResponse.help();

        expect(response.isError, isFalse);
        expect(response.message, contains('*unfurls ancient scroll* `📜`'));
        expect(response.message, contains('/plan'));

        // Check for explore commands for each dimension
        for (final dimension in LifePlanDimension.values) {
          expect(response.message, contains('/explore ${dimension.code}'));
          expect(response.message.toLowerCase(),
              contains(dimension.title.toLowerCase()));
        }

        expect(response.message, contains('Per aspera ad astra'));
      });
    });

    group('Unknown Command Response Tests', () {
      test('creates unknown command response', () {
        final response = LifePlanResponse.unknown();

        expect(response.isError, isTrue);
        expect(response.message, contains('I do not recognize that command'));
        expect(response.message, contains('/help'));
      });
    });

    group('Response Immutability Tests', () {
      test('response objects preserve their values', () {
        const response =
            LifePlanResponse(message: 'Test', isError: false);

        expect(response.message, equals('Test'));
        expect(response.isError, isFalse);

        // Verify that we can't modify the values
        expect(() {
          // ignore: invalid_use_of_protected_member
          (response as dynamic).message = 'New message';
        }, throwsNoSuchMethodError);

        expect(() {
          // ignore: invalid_use_of_protected_member
          (response as dynamic).isError = true;
        }, throwsNoSuchMethodError);
      });
    });
  });
}
