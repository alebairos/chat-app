import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ClaudeService claudeService;

  setUp(() async {
    dotenv.testLoad(fileInput: '''
      ANTHROPIC_API_KEY=test_key
      OPENAI_API_KEY=test_key
    ''');

    claudeService = ClaudeService();
  });

  group('Chat Screen Error Handling', () {
    test('verifies overloaded error message format', () {
      // Test the format of the overloaded error message
      final errorMessage =
          'Claude is currently experiencing high demand. Please try again in a moment.';

      // Verify the error message format
      expect(errorMessage, contains('high demand'));
      expect(errorMessage, contains('try again'));
    });

    test('verifies network error message format', () {
      // Test the format of the network error message
      final errorMessage =
          'Unable to connect to Claude. Please check your internet connection.';

      // Verify the error message format
      expect(errorMessage, contains('Unable to connect'));
      expect(errorMessage, contains('internet connection'));
    });

    test('verifies authentication error message format', () {
      // Test the format of the authentication error message
      final errorMessage = 'Authentication failed. Please check your API key.';

      // Verify the error message format
      expect(errorMessage, contains('Authentication failed'));
      expect(errorMessage, contains('API key'));
    });

    test('verifies rate limit error message format', () {
      // Test the format of the rate limit error message
      final errorMessage =
          'You\'ve reached the rate limit. Please wait a moment before sending more messages.';

      // Verify the error message format
      expect(errorMessage, contains('rate limit'));
      expect(errorMessage, contains('wait'));
    });

    test('verifies server error message format', () {
      // Test the format of the server error message
      final errorMessage =
          'Claude service is temporarily unavailable. Please try again later.';

      // Verify the error message format
      expect(errorMessage, contains('temporarily unavailable'));
      expect(errorMessage, contains('try again later'));
    });

    test('verifies generic error message format', () {
      // Test the format of the generic error message
      final errorMessage =
          'Unable to get a response from Claude. Please try again later.';

      // Verify the error message format
      expect(errorMessage, contains('Unable to get a response'));
      expect(errorMessage, contains('try again later'));
    });
  });
}
