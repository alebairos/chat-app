import 'package:flutter_test/flutter_test.dart';
import '../../../lib/features/audio_assistant/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioAssistantTTSService', () {
    late AudioAssistantTTSService ttsService;

    setUp(() {
      ttsService = AudioAssistantTTSService();
    });

    test('can be created', () {
      expect(ttsService, isNotNull);
    });

    test('has test mode flag', () {
      expect(ttsService, isNotNull);
      ttsService.enableTestMode();
      // We'll add more test mode functionality later
    });

    test('initializes successfully', () async {
      ttsService.enableTestMode();
      final result = await ttsService.initialize();
      expect(result, isTrue);
    });

    test('generateAudio throws when not initialized', () async {
      ttsService.enableTestMode();
      expect(
        () => ttsService.generateAudio('test text'),
        throwsA(isA<Exception>()),
      );
    });

    test('generateAudio works when initialized', () async {
      ttsService.enableTestMode();
      await ttsService.initialize();
      final audioPath = await ttsService.generateAudio('test text');
      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('audio_assistant_'));
    });

    test('cleanup doesn\'t throw in test mode', () async {
      ttsService.enableTestMode();
      expect(
        () => ttsService.cleanup(),
        returnsNormally,
      );
    });

    test('service maintains initialized state after cleanup', () async {
      ttsService.enableTestMode();
      await ttsService.initialize();
      await ttsService.cleanup();

      // Should still be able to generate audio after cleanup
      final audioPath = await ttsService.generateAudio('test text');
      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('audio_assistant_'));
    });

    test('service can be reinitialized after cleanup', () async {
      ttsService.enableTestMode();
      await ttsService.initialize();
      await ttsService.cleanup();

      // Should be able to reinitialize
      final result = await ttsService.initialize();
      expect(result, isTrue);

      // Should be able to generate audio after reinitialization
      final audioPath = await ttsService.generateAudio('test text');
      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('audio_assistant_'));
    });

    test('service handles multiple cleanup calls gracefully', () async {
      ttsService.enableTestMode();
      await ttsService.initialize();

      // Multiple cleanup calls should not throw
      await ttsService.cleanup();
      await ttsService.cleanup();
      await ttsService.cleanup();

      // Should still be able to generate audio after multiple cleanups
      final audioPath = await ttsService.generateAudio('test text');
      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('audio_assistant_'));
    });

    test('service maintains test mode state after cleanup and reinitialization',
        () async {
      ttsService.enableTestMode();
      await ttsService.initialize();
      await ttsService.cleanup();
      await ttsService.initialize();

      // Should still be in test mode and generate test paths
      final audioPath = await ttsService.generateAudio('test text');
      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('test_audio_assistant_'));
    });

    test('handles initialization errors gracefully', () async {
      // In test mode, we should still get a successful initialization
      ttsService.enableTestMode();
      final result = await ttsService.initialize();
      expect(result, isTrue);

      // Try to initialize again - should still return true
      final secondResult = await ttsService.initialize();
      expect(secondResult, isTrue);
    });

    test('handles empty text input gracefully', () async {
      ttsService.enableTestMode();
      await ttsService.initialize();

      // Should handle empty text without throwing
      final audioPath = await ttsService.generateAudio('');
      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('test_audio_assistant_'));
    });

    test('handles cleanup when not initialized', () async {
      ttsService.enableTestMode();

      // Cleanup should not throw even when not initialized
      await ttsService.cleanup();

      // Should still be able to initialize and generate audio
      await ttsService.initialize();
      final audioPath = await ttsService.generateAudio('test text');
      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('test_audio_assistant_'));
    });

    test('handles very long text input gracefully', () async {
      ttsService.enableTestMode();
      await ttsService.initialize();

      // Generate a very long text string
      final longText = 'test text ' * 1000;

      // Should handle long text without throwing
      final audioPath = await ttsService.generateAudio(longText);
      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('test_audio_assistant_'));
    });

    test('handles text with special characters gracefully', () async {
      ttsService.enableTestMode();
      await ttsService.initialize();

      final audioPath =
          await ttsService.generateAudio('Hello! How are you? @#\$%');
      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('test_audio_assistant_'));
    });

    test('handles text with Unicode characters gracefully', () async {
      ttsService.enableTestMode();
      await ttsService.initialize();

      // Text with various Unicode characters (emojis, non-Latin characters)
      final unicodeText = 'Hello 👋 你好 🌍';

      final audioPath = await ttsService.generateAudio(unicodeText);
      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('test_audio_assistant_'));
    });

    test('handles whitespace-only text gracefully', () async {
      ttsService.enableTestMode();
      await ttsService.initialize();

      // Text with only whitespace characters
      final whitespaceText = '   \t\n\r';

      final audioPath = await ttsService.generateAudio(whitespaceText);
      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('test_audio_assistant_'));
    });

    test('handles text with control characters gracefully', () async {
      ttsService.enableTestMode();
      await ttsService.initialize();

      // Text with control characters (null, bell, backspace, etc.)
      final controlText = 'Hello\x00\x07\x08World';

      final audioPath = await ttsService.generateAudio(controlText);
      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('test_audio_assistant_'));
    });

    test('handles text with mixed line endings gracefully', () async {
      ttsService.enableTestMode();
      await ttsService.initialize();

      // Text with mixed line endings (CRLF, LF, CR)
      final mixedEndingsText = 'Line 1\r\nLine 2\nLine 3\r';

      final audioPath = await ttsService.generateAudio(mixedEndingsText);
      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('test_audio_assistant_'));
    });

    test('handles text with invisible Unicode characters gracefully', () async {
      ttsService.enableTestMode();
      await ttsService.initialize();

      // Text with invisible Unicode characters (zero-width space, zero-width joiner, etc.)
      final invisibleText = 'Hello\u200B\u200C\u200DWorld';

      final audioPath = await ttsService.generateAudio(invisibleText);
      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('test_audio_assistant_'));
    });
  });
}
