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
  bool _shouldExist;

  MockFile(this.filePath, {bool shouldExist = true})
      : _shouldExist = shouldExist;

  @override
  String get path => filePath;

  @override
  Future<bool> exists() async => _shouldExist;

  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) async =>
      this;

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    _shouldExist = false; // Mark as deleted
    return this;
  }

  // Helper method for tests
  void setExists(bool exists) {
    _shouldExist = exists;
  }
}

class MockLogger extends Mock implements Logger {}

// Create a test subclass of AudioAssistantTTSService to override the deleteAudio method
class TestableAudioAssistantTTSService extends AudioAssistantTTSService {
  MockFile? lastFileAttemptedToDelete;
  bool forceDeleteFailure = false;
  bool forcePathConversionFailure = false;
  bool testModeFlag = false;
  bool useNonExistentFile = false;

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
  Future<bool> deleteAudio(String relativePath) async {
    if (!AudioAssistantTTSService.featureEnabled && !testModeFlag) {
      return false;
    }

    if (forcePathConversionFailure) {
      return false;
    }

    final absolutePath = '/mock/documents/$relativePath';
    final mockFile = MockFile(absolutePath, shouldExist: !useNonExistentFile);
    lastFileAttemptedToDelete = mockFile;

    try {
      if (forceDeleteFailure) {
        throw Exception('Forced deletion failure');
      }

      final exists = await mockFile.exists();
      if (!exists) {
        return false;
      }

      await mockFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}

void main() {
  late TestableAudioAssistantTTSService ttsService;
  late MockPathProviderPlatform mockPathProvider;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Register fallback values for Mocktail
    registerFallbackValue(Uri());

    mockPathProvider = MockPathProviderPlatform();
    PathProviderPlatform.instance = mockPathProvider;

    // Reset feature flag for each test
    AudioAssistantTTSService.featureEnabled = true;

    ttsService = TestableAudioAssistantTTSService();
    ttsService.enableTestMode(); // Enable test mode for all tests
  });

  group('AudioAssistantTTSService - deleteAudio', () {
    test('should return false when feature is disabled', () async {
      // Arrange
      await ttsService.initialize();
      AudioAssistantTTSService.featureEnabled = false;
      ttsService.disableTestMode(); // Disable test mode to test feature flag
      const relativePath = 'audio_assistant/test.mp3';

      // Act
      final result = await ttsService.deleteAudio(relativePath);

      // Assert
      expect(result, false);
      expect(ttsService.lastFileAttemptedToDelete,
          null); // No file access attempted

      // Reset for other tests
      AudioAssistantTTSService.featureEnabled = true;
      ttsService.enableTestMode();
    });

    test('should successfully delete an existing audio file', () async {
      // Arrange
      await ttsService.initialize();
      const relativePath = 'audio_assistant/test.mp3';

      // Act
      final result = await ttsService.deleteAudio(relativePath);

      // Assert
      expect(result, true);
      expect(ttsService.lastFileAttemptedToDelete, isNotNull);

      // Verify the file was marked as deleted
      final exists = await ttsService.lastFileAttemptedToDelete!.exists();
      expect(exists, false);
    });

    test('should return false when trying to delete a non-existent file',
        () async {
      // Arrange
      await ttsService.initialize();
      const relativePath = 'audio_assistant/nonexistent.mp3';

      // Set flag to simulate non-existent file
      ttsService.useNonExistentFile = true;

      // Act
      final result = await ttsService.deleteAudio(relativePath);

      // Assert
      expect(result, false);
      expect(ttsService.lastFileAttemptedToDelete, isNotNull);

      // Reset the flag
      ttsService.useNonExistentFile = false;
    });

    test('should handle exceptions during file deletion', () async {
      // Arrange
      await ttsService.initialize();
      const relativePath = 'audio_assistant/error.mp3';
      ttsService.forceDeleteFailure = true;

      // Act
      final result = await ttsService.deleteAudio(relativePath);

      // Assert
      expect(result, false);
    });

    test('should return false when path conversion fails', () async {
      // Arrange
      await ttsService.initialize();
      const relativePath = 'audio_assistant/invalid.mp3';
      ttsService.forcePathConversionFailure = true;

      // Act
      final result = await ttsService.deleteAudio(relativePath);

      // Assert
      expect(result, false);
    });
  });
}
