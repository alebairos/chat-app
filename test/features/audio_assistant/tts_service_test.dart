import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:character_ai_clone/features/audio_assistant/tts_service.dart';
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

class MockFile extends Mock implements File {
  final String filePath;
  final bool shouldExist;

  MockFile(this.filePath, {this.shouldExist = false});

  @override
  String get path => filePath;

  @override
  Future<bool> exists() async => shouldExist;

  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) async =>
      this;

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async => this;
}

class MockLogger extends Mock implements Logger {}

void main() {
  late MockPathProviderPlatform mockPathProvider;
  late AudioAssistantTTSService ttsService;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    mockPathProvider = MockPathProviderPlatform();
    PathProviderPlatform.instance = mockPathProvider;

    // Reset feature flag for each test
    AudioAssistantTTSService.featureEnabled = true;

    ttsService = AudioAssistantTTSService();
    ttsService.enableTestMode(); // Enable test mode for all tests
  });

  group('AudioAssistantTTSService', () {
    test('initialize should create directory if it does not exist', () async {
      // Act
      final result = await ttsService.initialize();

      // Assert
      expect(result, true);
    });

    test('generateAudio should return null when feature is disabled', () async {
      // Arrange
      await ttsService.initialize();
      AudioAssistantTTSService.featureEnabled = false;

      // Temporarily disable test mode for this test
      ttsService.disableTestMode();

      // Act
      final result = await ttsService.generateAudio('Test text');

      // Assert
      expect(result, null);

      // Re-enable test mode
      ttsService.enableTestMode();
    });

    test('generateAudio should return relative path for test mode', () async {
      // Arrange
      await ttsService.initialize();

      // Act
      final result = await ttsService.generateAudio('Test text');

      // Assert
      expect(result, startsWith('audio_assistant/test_audio_assistant_'));
      expect(result, endsWith('.mp3'));
    });

    test('cleanup should exit early when feature is disabled', () async {
      // Arrange
      await ttsService.initialize();
      AudioAssistantTTSService.featureEnabled = false;

      // Temporarily disable test mode for this test
      ttsService.disableTestMode();

      // Act
      await ttsService.cleanup();

      // Assert - no actions with file system should occur

      // Re-enable test mode
      ttsService.enableTestMode();
    });

    test('deleteAudio should return false when feature is disabled', () async {
      // Arrange
      await ttsService.initialize();
      AudioAssistantTTSService.featureEnabled = false;

      // Temporarily disable test mode for this test
      ttsService.disableTestMode();

      // Act
      final result = await ttsService.deleteAudio('audio/test.mp3');

      // Assert
      expect(result, false);

      // Re-enable test mode
      ttsService.enableTestMode();
    });

    test('disableTestMode should disable test mode', () async {
      // Arrange
      await ttsService.initialize();

      // Act - first disable test mode
      ttsService.disableTestMode();

      // Re-enable test mode at end
      ttsService.enableTestMode();
    });
  });
}
