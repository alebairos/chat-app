import 'package:flutter_test/flutter_test.dart';
import '../lib/config/config_loader.dart';
import 'dart:convert';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('config file has valid structure for Claude API', () async {
    // Initialize the config loader
    final configLoader = ConfigLoader();
    final systemPrompt = await configLoader.loadSystemPrompt();

    // Verify we got a valid string
    expect(systemPrompt, isA<String>());
    expect(systemPrompt.isNotEmpty, true);

    // Verify it has the required content
    expect(
      systemPrompt.contains('You are Sergeant Oracle'),
      true,
      reason: 'System prompt should define the AI character identity',
    );

    // Verify it contains all required commands
    final requiredCommands = [
      'get_goals_by_dimension',
      'get_track_by_id',
      'get_habits_for_challenge',
      'get_recommended_habits'
    ];

    for (final command in requiredCommands) {
      expect(
        systemPrompt.contains(command),
        true,
        reason: 'System prompt should include the $command command',
      );
    }

    // Verify it contains formatting instructions
    final formattingElements = [
      'Gestures in *asterisks*',
      'Emojis in `backticks`',
      '**Bold**',
      '_Italics_'
    ];

    for (final element in formattingElements) {
      expect(
        systemPrompt.contains(element),
        true,
        reason: 'System prompt should include $element formatting instruction',
      );
    }
  });
}
