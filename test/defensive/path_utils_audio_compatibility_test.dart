import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mocktail/mocktail.dart';

import 'package:character_ai_clone/utils/path_utils.dart';

// Mock classes
class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/mock/documents';
  }
}

class MockFile extends Mock implements File {}

class MockDirectory extends Mock implements Directory {}

void main() {
  setUp(() {
    // Register the mock path provider
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  group('Path Utils Audio Compatibility', () {
    test('absoluteToRelative should handle audio file paths correctly',
        () async {
      // Test with typical audio file paths
      const basePath = '/mock/documents';
      final audioAbsolutePath = p.join(basePath, 'audio', 'response_123.aiff');

      final relativePath =
          await PathUtils.absoluteToRelative(audioAbsolutePath);

      // Verify the relative path is correctly formatted
      expect(relativePath, 'audio/response_123.aiff');

      // Test with the reverse operation
      final reconstructedPath =
          await PathUtils.relativeToAbsolute(relativePath!);
      expect(reconstructedPath, audioAbsolutePath);
    });

    test('getDirName should handle audio directory paths correctly', () {
      // Typical audio directory path
      final audioPath = p.join('audio', 'response_123.aiff');

      final dirName = PathUtils.getDirName(audioPath);

      // Verify directory name is extracted correctly
      expect(dirName, 'audio');
    });

    test('getFileName should handle audio files with various extensions', () {
      // Test with different audio file extensions
      final aiffPath = p.join('audio', 'response_123.aiff');
      final mp3Path = p.join('audio', 'response_123.mp3');
      final wavPath = p.join('audio', 'response_123.wav');

      expect(PathUtils.getFileName(aiffPath), 'response_123.aiff');
      expect(PathUtils.getFileName(mp3Path), 'response_123.mp3');
      expect(PathUtils.getFileName(wavPath), 'response_123.wav');
    });

    test('file extension handling for audio files', () {
      // Test with different audio file extensions
      final aiffPath = p.join('audio', 'response_123.aiff');
      final mp3Path = p.join('audio', 'response_123.mp3');
      final wavPath = p.join('audio', 'response_123.wav');

      // Using basename and extension from path package since PathUtils doesn't have getFileExtension
      expect(p.extension(aiffPath), '.aiff');
      expect(p.extension(mp3Path), '.mp3');
      expect(p.extension(wavPath), '.wav');
    });

    test('Path manipulation should be consistent between platforms', () {
      // This test ensures path manipulation functions work consistently
      // across platforms, which is crucial for audio file handling

      // Test with platform-specific separators
      const basePath = 'audio';

      // On all platforms, path.join should create proper paths
      final joinedPath = p.join(basePath, 'files', 'response.aiff');

      // Verify the paths are normalized correctly
      expect(PathUtils.getDirName(joinedPath), p.join(basePath, 'files'));
      expect(PathUtils.getFileName(joinedPath), 'response.aiff');
    });

    test('Audio file paths should work with path manipulation functions', () {
      // Test various path manipulations with audio file paths
      final testPaths = [
        'audio/message_123.aiff',
        'audio/recordings/user_456.mp3',
        'audio/assistant/response_789.wav'
      ];

      for (final path in testPaths) {
        // Test that the path is correctly split into directory and filename
        final dir = PathUtils.getDirName(path);
        final file = PathUtils.getFileName(path);

        // Verify we can reconstruct the original path
        final reconstructed = p.join(dir, file);
        expect(reconstructed, path);
      }
    });
  });
}
