import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:character_ai_clone/features/audio_assistant/services/text_to_speech_service.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_generation.dart';

// This test is designed to generate a real audio sample for testing purposes.
// It uses the actual FlutterTTS implementation rather than a mock.
// Note: This test will be skipped in CI environments as it requires a real device.

// Mock for PathProvider to use in tests
class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getApplicationCachePath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<List<String>?> getExternalStoragePaths(
      {StorageDirectory? type}) async {
    return [Directory.systemTemp.path];
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return [Directory.systemTemp.path];
  }

  @override
  Future<String?> getDownloadsPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Skip this test in CI environments or simulators
  final bool isCI = Platform.environment.containsKey('CI');

  // Check if we're running on a real device
  bool isRealDevice = true;

  // We'll determine if we're on a real device by checking if TTS is available
  // This will be set in the setUp function

  group('Generate Audio Sample', () {
    late AudioGeneration ttsService;
    late Directory tempDir;
    late FlutterTts flutterTts;

    setUp(() async {
      // Set up path provider
      PathProviderPlatform.instance = MockPathProviderPlatform();

      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('audio_assistant_test');

      // Create a real FlutterTTS instance to check if we're on a real device
      flutterTts = FlutterTts();

      // Check if we're on a real device by testing if TTS is available
      try {
        isRealDevice = await flutterTts.isLanguageAvailable("en-US");
        print('Running on real device: $isRealDevice');
      } catch (e) {
        isRealDevice = false;
        print('Error checking device type: $e');
        print('Assuming simulator environment');
      }

      // Create the service with a real FlutterTTS instance
      ttsService = TextToSpeechService(flutterTts);
    });

    tearDown(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Generate welcome message audio sample', () async {
      // Skip this test in CI environments or simulators
      if (isCI || !isRealDevice) {
        print('Skipping audio generation test in CI or simulator environment');
        return;
      }

      // Initialize the TTS service
      final initialized = await ttsService.initialize();
      expect(initialized, true,
          reason: 'TTS service should initialize successfully');

      // Define the welcome message
      const welcomeMessage =
          'Welcome to the chat app! I can now respond with voice messages.';

      // Generate the audio file
      final audioFile = await ttsService.generate(welcomeMessage);
      expect(audioFile, isNotNull);
      expect(audioFile.path, isNotEmpty);

      // Verify the file exists
      final file = File(audioFile.path);
      expect(await file.exists(), true,
          reason: 'Generated audio file should exist');

      // Verify the file has content
      final fileSize = await file.length();
      expect(fileSize, greaterThan(0),
          reason: 'Generated audio file should have content');

      // Copy the file to the assets directory
      final assetDir = Directory('assets/audio');
      if (!await assetDir.exists()) {
        await assetDir.create(recursive: true);
      }

      final assetPath = '${assetDir.path}/welcome_message.aiff';
      await file.copy(assetPath);

      // Verify the asset file exists
      final assetFile = File(assetPath);
      expect(await assetFile.exists(), true,
          reason: 'Asset audio file should exist');

      print('Audio sample generated and saved to: $assetPath');
      print('File size: ${await assetFile.length()} bytes');
      print('Duration: ${audioFile.duration.inMilliseconds}ms');

      // Add the file to pubspec.yaml assets section
      // Note: This is a reminder for the developer to manually add the file to pubspec.yaml
      print(
          '\nReminder: Add the following to your pubspec.yaml assets section:');
      print('  - assets/audio/welcome_message.aiff');
    }, skip: isCI || !isRealDevice);

    test('Generate assistant response audio sample', () async {
      // Skip this test in CI environments or simulators
      if (isCI || !isRealDevice) {
        print('Skipping audio generation test in CI or simulator environment');
        return;
      }

      // Initialize the TTS service
      final initialized = await ttsService.initialize();
      expect(initialized, true,
          reason: 'TTS service should initialize successfully');

      // Define the assistant response
      const assistantResponse =
          'I\'ve analyzed your code and found a few issues. '
          'First, there\'s a missing semicolon on line 42. '
          'Second, the function on line 78 could be optimized by using a more efficient algorithm. '
          'Would you like me to fix these issues for you?';

      // Generate the audio file
      final audioFile = await ttsService.generate(assistantResponse);
      expect(audioFile, isNotNull);
      expect(audioFile.path, isNotEmpty);

      // Verify the file exists
      final file = File(audioFile.path);
      expect(await file.exists(), true,
          reason: 'Generated audio file should exist');

      // Verify the file has content
      final fileSize = await file.length();
      expect(fileSize, greaterThan(0),
          reason: 'Generated audio file should have content');

      // Copy the file to the assets directory
      final assetDir = Directory('assets/audio');
      if (!await assetDir.exists()) {
        await assetDir.create(recursive: true);
      }

      final assetPath = '${assetDir.path}/assistant_response.aiff';
      await file.copy(assetPath);

      // Verify the asset file exists
      final assetFile = File(assetPath);
      expect(await assetFile.exists(), true,
          reason: 'Asset audio file should exist');

      print('Audio sample generated and saved to: $assetPath');
      print('File size: ${await assetFile.length()} bytes');
      print('Duration: ${audioFile.duration.inMilliseconds}ms');

      // Add the file to pubspec.yaml assets section
      // Note: This is a reminder for the developer to manually add the file to pubspec.yaml
      print(
          '\nReminder: Add the following to your pubspec.yaml assets section:');
      print('  - assets/audio/assistant_response.aiff');
    }, skip: isCI || !isRealDevice);

    test('Generate real-time audio message test', () async {
      // Skip this test in CI environments or simulators
      if (isCI || !isRealDevice) {
        print('Skipping audio generation test in CI or simulator environment');
        return;
      }

      // Initialize the TTS service
      final initialized = await ttsService.initialize();
      expect(initialized, true,
          reason: 'TTS service should initialize successfully');

      // Define a test message
      const testMessage =
          'This is a test message to verify that text-to-speech is working correctly on a real device.';

      // Generate the audio file
      final audioFile = await ttsService.generate(testMessage);
      expect(audioFile, isNotNull);
      expect(audioFile.path, isNotEmpty);

      // Verify the file exists
      final file = File(audioFile.path);
      expect(await file.exists(), true,
          reason: 'Generated audio file should exist');

      // Verify the file has content
      final fileSize = await file.length();
      expect(fileSize, greaterThan(0),
          reason: 'Generated audio file should have content');

      // Print file details for debugging
      print('Real-time audio file generated at: ${audioFile.path}');
      print('File size: $fileSize bytes');
      print('Duration: ${audioFile.duration.inMilliseconds}ms');

      // Verify the file extension
      expect(
          audioFile.path.endsWith('.mp3') || audioFile.path.endsWith('.aiff'),
          isTrue,
          reason: 'Generated audio file should have a valid audio extension');

      // Print a message to help with manual verification
      print('\nTo manually verify this audio file:');
      print('1. Connect to the device');
      print('2. Navigate to: ${audioFile.path}');
      print('3. Play the file using an audio player');
    }, skip: isCI || !isRealDevice);
  });
}
