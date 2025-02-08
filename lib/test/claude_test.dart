import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/claude_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ClaudeService claudeService;

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    claudeService = ClaudeService();
  });

  test('Claude responds with proper formatting and emoticons', () async {
    final response = await claudeService.sendMessage('Hi');

    // Check if response contains formatting elements
    expect(response.contains('*'), isTrue,
        reason: 'Should contain gestures in asterisks');
    expect(
        response.contains('🤔') ||
            response.contains('💭') ||
            response.contains('⚔️') ||
            response.contains('🌟'),
        isTrue,
        reason: 'Should contain at least one emoticon');

    print('Claude Response:\n$response');
  });
}
