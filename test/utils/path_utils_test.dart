import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:mocktail/mocktail.dart';

import 'package:ai_personas_app/utils/path_utils.dart';

class MockDirectory extends Mock implements Directory {}

class MockFile extends Mock implements File {}

void main() {
  group('PathUtils', () {
    test('isAbsolutePath correctly identifies absolute paths', () {
      expect(PathUtils.isAbsolutePath('/absolute/path'), isTrue);
      expect(PathUtils.isAbsolutePath('relative/path'), isFalse);
    });

    test('getFileName extracts file name correctly', () {
      expect(PathUtils.getFileName('/path/to/file.txt'), equals('file.txt'));
      expect(PathUtils.getFileName('file.txt'), equals('file.txt'));
    });

    test('getDirName extracts directory name correctly', () {
      expect(PathUtils.getDirName('/path/to/file.txt'), equals('/path/to'));
      expect(PathUtils.getDirName('dir/file.txt'), equals('dir'));
    });

    test('handles empty and invalid paths correctly', () {
      // Empty path
      expect(PathUtils.getFileName(''), equals(''));
      expect(PathUtils.getDirName(''), equals('.'));

      // Path with only delimiters
      expect(PathUtils.getFileName('/'), equals('/'));
      expect(PathUtils.getDirName('/'), equals('/'));

      // Path with special characters
      expect(PathUtils.getFileName('/path/to/file with spaces.txt'),
          equals('file with spaces.txt'));
      expect(PathUtils.getDirName('/path/with spaces/file.txt'),
          equals('/path/with spaces'));
    });

    test('handles path with special components', () {
      // The path package doesn't automatically normalize paths
      // It just splits and joins path components
      expect(
          PathUtils.getDirName('/path/to/../file.txt'), equals('/path/to/..'));
      expect(PathUtils.getDirName('/path/./to/file.txt'), equals('/path/./to'));

      // Paths with multiple slashes
      expect(PathUtils.getFileName('/path//to/file.txt'), equals('file.txt'));
      expect(PathUtils.getDirName('/path//to/file.txt'), equals('/path//to'));
    });

    group('path extension methods', () {
      test('joins paths correctly', () {
        // On posix systems, an absolute path segment (starting with /) will discard all previous segments
        expect(p.join('path', 'to', 'file.txt'), equals('path/to/file.txt'));
        expect(p.join('/path', 'to', 'file.txt'), equals('/path/to/file.txt'));
        expect(p.join('path', '/to', 'file.txt'),
            equals('/to/file.txt')); // Absolute path segment discards previous
        expect(p.join('path', 'to/', 'file.txt'), equals('path/to/file.txt'));
      });

      test('handles file extensions correctly', () {
        expect(p.extension('/path/to/file.txt'), equals('.txt'));
        expect(p.extension('/path/to/file'), equals(''));
        expect(
            p.extension('/path/to/file.with.multiple.dots'), equals('.dots'));
        expect(p.extension('/path.with.dots/file'), equals(''));
        expect(p.extension('file.txt'), equals('.txt'));
      });

      test('handles path separators', () {
        // On macOS, backslashes are treated as regular characters, not separators
        expect(p.basename('path\\to\\file.txt'), equals('path\\to\\file.txt'));

        // Forward slashes are always treated as separators
        expect(p.basename('path/to/file.txt'), equals('file.txt'));

        // Mixed separators - backslash is just a character on POSIX
        expect(p.basename('path/to\\file.txt'), equals('to\\file.txt'));
      });
    });

    // Note: We're not testing absoluteToRelative and relativeToAbsolute
    // as they require the path_provider package which is difficult to mock
    // in tests. These methods should be tested in integration tests.
  });
}
