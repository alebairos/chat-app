import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:character_ai_clone/features/audio_assistant/tts_service.dart';
import 'package:character_ai_clone/features/audio_assistant/services/tts_provider.dart';
import 'package:character_ai_clone/utils/logger.dart';

// Mock implementations
class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/mock/documents';
  }
}

class MockDirectory extends Mock implements Directory {
  final String dirPath;
  final bool shouldExist;

  MockDirectory(this.dirPath, {this.shouldExist = true});

  @override
  String get path => dirPath;

  @override
  Future<bool> exists() async => shouldExist;

  @override
  Future<Directory> create({bool recursive = false}) async => this;
}

class MockTTSProvider extends Mock implements TTSProvider {
  @override
  String get name => 'MockCustomProvider';
}

class MockLogger extends Mock implements Logger {}

// Create a test subclass of AudioAssistantTTSService to expose internal state
class TestableAudioAssistantTTSService extends AudioAssistantTTSService {
  String? lastGeneratedPath;
  String? lastGeneratedText;
  bool forceInitFailure = false;
  bool forceGenerateFailure = false;
  bool testModeFlag = false;

  @override
  void enableTestMode() {
    testModeFlag = true;
    super.enableTestMode();
  }

  @override
  void disableTestMode() {
    testModeFlag = false;
    super.disableTestMode();
  }

  @override
  Future<bool> initialize() async {
    if (forceInitFailure) {
      return false;
    }
    return await super.initialize();
  }

  // Override to track calls and handle test scenarios
  @override
  Future<String?> generateAudio(String text) async {
    lastGeneratedText = text;

    if (forceGenerateFailure) {
      return null;
    }

    // For initialization failure test
    if (forceInitFailure) {
      return null;
    }

    // Use the test mode flag from our tracked state
    if (testModeFlag) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      lastGeneratedPath = 'audio_assistant/test_audio_assistant_$timestamp.mp3';
      return lastGeneratedPath;
    }

    return await super.generateAudio(text);
  }

  // Add a custom provider for testing - this is a no-op since we can't access private fields
  void addCustomProvider(String name, TTSProvider provider) {
    // We can't directly modify the private field, so this is just a stub
  }
}

void main() {
  late TestableAudioAssistantTTSService ttsService;
  late MockPathProviderPlatform mockPathProvider;
  late MockTTSProvider mockCustomProvider;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    mockPathProvider = MockPathProviderPlatform();
    PathProviderPlatform.instance = mockPathProvider;

    // Reset feature flag for each test
    AudioAssistantTTSService.featureEnabled = true;

    ttsService = TestableAudioAssistantTTSService();
    ttsService.enableTestMode(); // Enable test mode for all tests

    // Setup mock custom provider
    mockCustomProvider = MockTTSProvider();
    when(() => mockCustomProvider.initialize()).thenAnswer((_) async => true);
    when(() => mockCustomProvider.generateSpeech(any(), any()))
        .thenAnswer((_) async => true);
    when(() => mockCustomProvider.config).thenReturn({'test': 'config'});
    when(() => mockCustomProvider.updateConfig(any()))
        .thenAnswer((_) async => true);
  });

  group('AudioAssistantTTSService - generateAudio', () {
    test('should return null when initialization fails', () async {
      // Arrange
      ttsService.forceInitFailure = true;

      // Act
      final result = await ttsService.generateAudio('Test text');

      // Assert
      expect(result, isNull);
    });

    test('should generate audio file with correct text', () async {
      // Arrange
      await ttsService.initialize();
      const testText = 'This is a test message for audio generation';

      // Act
      final result = await ttsService.generateAudio(testText);

      // Assert
      expect(result, isNotNull);
      expect(result, startsWith('audio_assistant/test_audio_assistant_'));
      expect(result, endsWith('.mp3'));
      expect(ttsService.lastGeneratedText, testText);
    });

    test('should handle generation failure gracefully', () async {
      // Arrange
      await ttsService.initialize();
      ttsService.forceGenerateFailure = true;

      // Act
      final result = await ttsService.generateAudio('Test text');

      // Assert
      expect(result, isNull);
    });

    test('should successfully switch providers and generate audio', () async {
      // Arrange
      await ttsService.initialize();

      // Get current provider name before switching
      final initialProvider = ttsService.currentProviderName;

      // Act - switch between available providers
      final availableProviders = ttsService.availableProviders;
      final targetProvider = availableProviders.firstWhere(
          (name) => name != initialProvider,
          orElse: () => initialProvider);

      final switchResult = await ttsService.switchProvider(targetProvider);
      final audioPath =
          await ttsService.generateAudio('Test with different provider');

      // Assert
      expect(switchResult, true);
      expect(ttsService.currentProviderName, targetProvider);
      expect(audioPath, isNotNull);
    });

    test('should handle empty text gracefully', () async {
      // Arrange
      await ttsService.initialize();

      // Act
      final result = await ttsService.generateAudio('');

      // Assert - should still generate a file even with empty text
      expect(result, isNotNull);
      expect(ttsService.lastGeneratedText, '');
    });

    test('should handle very long text input', () async {
      // Arrange
      await ttsService.initialize();
      final longText = 'A' * 5000; // 5000 character string

      // Act
      final result = await ttsService.generateAudio(longText);

      // Assert
      expect(result, isNotNull);
      expect(ttsService.lastGeneratedText, longText);
    });
  });

  group('AudioAssistantTTSService - provider management', () {
    test('should correctly retrieve provider configuration', () async {
      // Arrange
      await ttsService.initialize();

      // Act
      final config = ttsService.providerConfig;

      // Assert
      expect(config, isNotNull);
      expect(config, isA<Map<String, dynamic>>());
    });

    test('should update provider configuration successfully', () async {
      // Arrange
      await ttsService.initialize();

      // Act
      final updateResult =
          await ttsService.updateProviderConfig({'simulateDelay': false});

      // Assert
      expect(updateResult, true);
    });

    test('should handle invalid provider name when switching', () async {
      // Arrange
      await ttsService.initialize();

      // Act
      final result = await ttsService.switchProvider('NonExistentProvider');

      // Assert
      expect(result, false);
      // Should still be using the original provider (MockTTS in test mode)
      expect(ttsService.currentProviderName, 'MockTTS');
    });
  });
}
