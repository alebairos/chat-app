import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:character_ai_clone/features/audio_assistant/services/text_to_speech_service.dart';

/// This is a simple test to verify that TTS works on a real device.
/// Run this test with: flutter test test/features/audio_assistant/real_device_tts_test.dart
///
/// Note: This test will be skipped on simulators and CI environments.
/// It's designed to be run manually on a real device to verify TTS functionality.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Determine if we're running on a real device
  bool isRealDevice = false;

  group('Real Device TTS Test', () {
    late TextToSpeechService ttsService;
    late FlutterTts flutterTts;
    Directory? tempDir;

    setUp(() async {
      // Create a real FlutterTTS instance
      flutterTts = FlutterTts();

      // Check if we're on a real device
      try {
        // Try to initialize the TTS engine
        await flutterTts.setLanguage('en-US');
        isRealDevice = true;
        print('Running on real device: $isRealDevice');
      } catch (e) {
        isRealDevice = false;
        print('Error checking device type: $e');
        print('Assuming simulator environment');
      }

      // Skip further setup if not on a real device
      if (!isRealDevice) {
        return;
      }

      // Create the TTS service
      ttsService = TextToSpeechService(flutterTts);

      try {
        // Create a temporary directory for testing
        final tempDirPath = (await getTemporaryDirectory()).path;
        tempDir = Directory('$tempDirPath/tts_test');
        if (!await tempDir!.exists()) {
          await tempDir!.create(recursive: true);
        }
      } catch (e) {
        print('Error creating temporary directory: $e');
        // Continue without a temp directory
      }
    });

    tearDown(() async {
      // Clean up
      if (tempDir != null && await tempDir!.exists()) {
        try {
          await tempDir!.delete(recursive: true);
        } catch (e) {
          print('Error cleaning up: $e');
        }
      }
    });

    test('Generate audio file on real device', () async {
      // Skip on simulators
      if (!isRealDevice) {
        print('Skipping test on simulator');
        return;
      }

      // Initialize the TTS service
      final initialized = await ttsService.initialize();
      expect(initialized, true,
          reason: 'TTS service should initialize successfully');

      // Generate audio for a test message
      const testMessage =
          'This is a test message to verify text-to-speech functionality on a real device.';
      print('Generating audio for: "$testMessage"');

      final audioFile = await ttsService.generate(testMessage);
      print('Audio file generated at: ${audioFile.path}');

      // Verify the file exists
      final file = File(audioFile.path);
      final exists = await file.exists();
      print('File exists: $exists');

      expect(exists, true, reason: 'Generated audio file should exist');

      // Verify the file has content
      final fileSize = await file.length();
      print('File size: $fileSize bytes');

      expect(fileSize, greaterThan(0),
          reason: 'Generated audio file should have content');

      // Print the duration
      print('Estimated duration: ${audioFile.duration.inMilliseconds}ms');

      // Print instructions for manual verification
      print('\n=== MANUAL VERIFICATION INSTRUCTIONS ===');
      print('To verify this audio file:');
      print('1. Connect to the device');
      print('2. Navigate to: ${audioFile.path}');
      print('3. Play the file using an audio player');
      print('4. Verify that the audio is clear and matches the text');
      print('=======================================\n');
    });

    test('Generate audio with Portuguese text', () async {
      // Skip on simulators
      if (!isRealDevice) {
        print('Skipping test on simulator');
        return;
      }

      // Initialize the TTS service
      final initialized = await ttsService.initialize();
      expect(initialized, true,
          reason: 'TTS service should initialize successfully');

      // Set language to Portuguese
      await flutterTts.setLanguage('pt-BR');

      // Generate audio for a Portuguese test message
      const testMessage =
          'Olá! Como vai você? Este é um teste de conversão de texto para fala em português.';
      print('Generating audio for Portuguese text: "$testMessage"');

      final audioFile = await ttsService.generate(testMessage);
      print('Audio file generated at: ${audioFile.path}');

      // Verify the file exists
      final file = File(audioFile.path);
      final exists = await file.exists();
      print('File exists: $exists');

      expect(exists, true, reason: 'Generated audio file should exist');

      // Verify the file has content
      final fileSize = await file.length();
      print('File size: $fileSize bytes');

      expect(fileSize, greaterThan(0),
          reason: 'Generated audio file should have content');

      // Print the duration
      print('Estimated duration: ${audioFile.duration.inMilliseconds}ms');

      // Print instructions for manual verification
      print('\n=== MANUAL VERIFICATION INSTRUCTIONS ===');
      print('To verify this Portuguese audio file:');
      print('1. Connect to the device');
      print('2. Navigate to: ${audioFile.path}');
      print('3. Play the file using an audio player');
      print(
          '4. Verify that the audio is clear and matches the Portuguese text');
      print('=======================================\n');

      // Reset language back to English
      await flutterTts.setLanguage('en-US');
    });
  });
}
