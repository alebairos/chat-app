import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/models/playback_state.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_generation.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_message_provider.dart';

class MockAudioGeneration extends Mock implements AudioGeneration {}

class MockAudioPlayback extends Mock implements AudioPlayback {}

// Create a fake AudioFile for mocktail's registerFallbackValue
class FakeAudioFile extends Fake implements AudioFile {}

class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => 'test/mock_audio';
}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail's matchers
    registerFallbackValue(FakeAudioFile());
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  group('AudioMessageProvider', () {
    late MockAudioGeneration mockAudioGeneration;
    late MockAudioPlayback mockAudioPlayback;
    late AudioMessageProvider provider;
    late Directory mockDir;
    const testAudioPath =
        'test/mock_audio/eleven_labs_audio/test_message_id.mp3';
    const testDuration = Duration(seconds: 10);

    setUp(() async {
      mockAudioGeneration = MockAudioGeneration();
      mockAudioPlayback = MockAudioPlayback();

      // Set up mock behavior
      when(() => mockAudioGeneration.isInitialized).thenReturn(true);
      when(() => mockAudioGeneration.initialize())
          .thenAnswer((_) async => true);
      when(() => mockAudioGeneration.generate(any()))
          .thenAnswer((_) async => AudioFile(
                path: testAudioPath,
                duration: testDuration,
              ));
      when(() => mockAudioGeneration.cleanup()).thenAnswer((_) async {});

      when(() => mockAudioPlayback.initialize()).thenAnswer((_) async => true);
      when(() => mockAudioPlayback.load(any())).thenAnswer((_) async => true);
      when(() => mockAudioPlayback.play()).thenAnswer((_) async => true);
      when(() => mockAudioPlayback.pause()).thenAnswer((_) async => true);
      when(() => mockAudioPlayback.stop()).thenAnswer((_) async => true);
      when(() => mockAudioPlayback.dispose()).thenAnswer((_) async {});

      // Create mock audio directory
      mockDir = Directory('test/mock_audio/eleven_labs_audio');
      await mockDir.create(recursive: true);

      provider = AudioMessageProvider(
        audioGeneration: mockAudioGeneration,
        audioPlayback: mockAudioPlayback,
      );
    });

    tearDown(() async {
      await mockDir.delete(recursive: true);
    });

    test('initializes audio generation and playback services', () async {
      final result = await provider.initialize();

      expect(result, isTrue);
      verify(() => mockAudioGeneration.initialize()).called(1);
    });

    test('generates audio for message', () async {
      await provider.initialize();

      const messageId = 'test_message_id';
      const text = 'Test message';

      final audioFile = await provider.generateAudioForMessage(messageId, text);

      expect(audioFile, isNotNull);
      expect(audioFile!.path, equals(testAudioPath));
      expect(audioFile.duration, equals(testDuration));
      verify(() => mockAudioGeneration.generate(text)).called(1);
    });

    test('disposes resources', () async {
      await provider.initialize();
      await provider.dispose();

      verify(() => mockAudioGeneration.cleanup()).called(1);
      verify(() => mockAudioPlayback.dispose()).called(1);
    });

    test('returns false when playing non-existent message', () async {
      await provider.initialize();

      final result = await provider.playAudioForMessage('non_existent_id');

      expect(result, isFalse);
      verifyNever(() => mockAudioPlayback.load(any()));
      verifyNever(() => mockAudioPlayback.play());
    });

    test('gets audio for message', () async {
      // Initialize the provider
      final result = await provider.initialize();
      expect(result, isTrue);

      const messageId = 'test_message_id';
      const text = 'Test message';

      // Create a mock audio file
      final audioFile = File(testAudioPath);
      await audioFile.create(recursive: true);
      await audioFile.writeAsString('mock audio content');

      // First generate the audio to ensure it's in the provider's cache
      final generatedAudio =
          await provider.generateAudioForMessage(messageId, text);

      // Then try to retrieve it
      final retrievedAudio = await provider.getAudioForMessage(messageId);

      // Assert
      expect(generatedAudio, isNotNull);
      expect(generatedAudio?.path, equals(testAudioPath));
      expect(generatedAudio?.duration, equals(testDuration));

      expect(retrievedAudio, isNotNull);
      expect(retrievedAudio?.path, equals(testAudioPath));
      expect(retrievedAudio?.duration, equals(testDuration));

      verify(() => mockAudioGeneration.generate(text)).called(1);
    });

    test('plays audio for message', () async {
      // Initialize the provider
      final result = await provider.initialize();
      expect(result, isTrue);

      const messageId = 'test_message_id';
      const text = 'Test message';

      // Create a mock audio file
      final audioFile = File(testAudioPath);
      await audioFile.create(recursive: true);
      await audioFile.writeAsString('mock audio content');

      // First generate the audio to ensure it's in the provider's cache
      final generatedAudio =
          await provider.generateAudioForMessage(messageId, text);
      expect(generatedAudio, isNotNull);

      // Then try to play it
      final playResult = await provider.playAudioForMessage(messageId);

      // Assert
      expect(playResult, isTrue);
      verify(() => mockAudioPlayback.load(any())).called(1);
      verify(() => mockAudioPlayback.play()).called(1);
    });

    test('loads audio from asset', () async {
      // Initialize the provider
      final result = await provider.initialize();
      expect(result, isTrue);

      const messageId = 'test_message_id';
      const assetPath = 'test/mock_audio/eleven_labs_audio/test.mp3';
      const duration = Duration(seconds: 30);

      // Create a mock asset file
      final assetFile = File(assetPath);
      await assetFile.create(recursive: true);
      await assetFile.writeAsString('mock audio content');

      // Load the audio from asset
      final audioFile = await provider.loadAudioFromAsset(
        messageId,
        assetPath,
        duration,
      );

      // Assert
      expect(audioFile, isNotNull);
      expect(audioFile!.path, equals(assetPath));
      expect(audioFile.duration, equals(duration));

      // Verify it's stored in the provider
      final storedFile = await provider.getAudioForMessage(messageId);
      expect(storedFile, isNotNull);
      expect(storedFile!.path, equals(assetPath));
      expect(storedFile.duration, equals(duration));
    });
  });
}
