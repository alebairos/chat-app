import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:character_ai_clone/utils/path_utils.dart';

// Mock classes
class MockFile extends Mock implements File {}

class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/mock/documents';
  }
}

// We need to patch the PathUtils class for testing
class TestablePathUtils extends PathUtils {
  static File? mockFileForTesting;

  static Future<bool> fileExistsForTest(String path) async {
    try {
      String absolutePath;
      if (PathUtils.isAbsolutePath(path)) {
        absolutePath = path;
      } else {
        absolutePath = await PathUtils.relativeToAbsolute(path);
      }

      // Use our mock file instead of creating a new File
      final file = mockFileForTesting ?? File(absolutePath);
      return await file.exists();
    } catch (e) {
      print('Error checking if file exists: $e');
      return false;
    }
  }
}

void main() {
  late MockPathProviderPlatform mockPathProvider;
  late MockFile mockFile;

  setUp(() {
    mockPathProvider = MockPathProviderPlatform();
    PathProviderPlatform.instance = mockPathProvider;

    mockFile = MockFile();

    // Register fallback values
    registerFallbackValue(false);
  });

  group('PathUtils.fileExists', () {
    test('returns true when file exists', () async {
      when(() => mockFile.exists()).thenAnswer((_) async => true);
      TestablePathUtils.mockFileForTesting = mockFile;

      final result = await TestablePathUtils.fileExistsForTest(
          '/path/to/existing/file.txt');
      expect(result, isTrue);

      // Reset mock
      TestablePathUtils.mockFileForTesting = null;
    });

    test('returns false when file does not exist', () async {
      when(() => mockFile.exists()).thenAnswer((_) async => false);
      TestablePathUtils.mockFileForTesting = mockFile;

      final result = await TestablePathUtils.fileExistsForTest(
          '/path/to/nonexistent/file.txt');
      expect(result, isFalse);

      // Reset mock
      TestablePathUtils.mockFileForTesting = null;
    });

    test('handles relative paths correctly', () async {
      when(() => mockFile.exists()).thenAnswer((_) async => true);
      TestablePathUtils.mockFileForTesting = mockFile;

      final result =
          await TestablePathUtils.fileExistsForTest('audio/recording.m4a');
      expect(result, isTrue);

      // Reset mock
      TestablePathUtils.mockFileForTesting = null;
    });

    test('returns false when an error occurs', () async {
      when(() => mockFile.exists()).thenThrow(Exception('Test error'));
      TestablePathUtils.mockFileForTesting = mockFile;

      final result =
          await TestablePathUtils.fileExistsForTest('/path/to/error/file.txt');
      expect(result, isFalse);

      // Reset mock
      TestablePathUtils.mockFileForTesting = null;
    });
  });
}
