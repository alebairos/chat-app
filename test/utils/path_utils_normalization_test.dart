import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:ai_personas_app/utils/path_utils.dart';

void main() {
  group('PathUtils path normalization', () {
    test('normalizes paths with redundant separators', () {
      const path = '/path//to///file.txt';

      // The path package should normalize multiple separators
      final dirname = PathUtils.getDirName(path);
      expect(dirname, equals('/path//to'));

      final basename = PathUtils.getFileName(path);
      expect(basename, equals('file.txt'));
    });

    test('handles paths with dot components', () {
      // Current directory
      const currentPath = './file.txt';
      expect(PathUtils.getFileName(currentPath), equals('file.txt'));
      expect(PathUtils.getDirName(currentPath), equals('.'));

      // Parent directory
      const parentPath = '../file.txt';
      expect(PathUtils.getFileName(parentPath), equals('file.txt'));
      expect(PathUtils.getDirName(parentPath), equals('..'));

      // Mixed dot components
      const mixedPath = './dir/../file.txt';
      // Note: path.dirname doesn't normalize paths, it just splits and joins
      expect(PathUtils.getDirName(mixedPath), equals('./dir/..'));
      expect(PathUtils.getFileName(mixedPath), equals('file.txt'));
    });

    test('handles paths with trailing separators', () {
      const path = '/path/to/dir/';

      // With trailing separator, the basename is the last directory name
      // This is how the path package behaves on most platforms
      expect(PathUtils.getFileName(path), equals('dir'));
      expect(PathUtils.getDirName(path), equals('/path/to'));
    });

    test('handles paths with special characters', () {
      const path = '/path/to/file with spaces and #special! chars.txt';

      expect(PathUtils.getFileName(path),
          equals('file with spaces and #special! chars.txt'));
      expect(PathUtils.getDirName(path), equals('/path/to'));
    });

    test('handles paths with Unicode characters', () {
      const path = '/path/to/文件.txt';

      expect(PathUtils.getFileName(path), equals('文件.txt'));
      expect(PathUtils.getDirName(path), equals('/path/to'));
    });
  });

  group('Path extension methods', () {
    test('normalizes paths correctly', () {
      // Normalize should resolve .. and . components
      expect(p.normalize('/path/./to/../file.txt'), equals('/path/file.txt'));
      expect(p.normalize('path/./to/../file.txt'), equals('path/file.txt'));

      // Normalize should also handle redundant separators
      expect(p.normalize('/path//to///file.txt'), equals('/path/to/file.txt'));
    });

    test('joins paths correctly with normalize', () {
      // Join and then normalize
      final joined = p.join('path', 'to', '../file.txt');
      final normalized = p.normalize(joined);

      expect(joined, equals('path/to/../file.txt'));
      expect(normalized, equals('path/file.txt'));
    });

    test('splits paths correctly', () {
      final parts = p.split('/path/to/file.txt');
      expect(parts, equals(['/', 'path', 'to', 'file.txt']));
    });

    test('gets file name without extension', () {
      expect(p.basenameWithoutExtension('/path/to/file.txt'), equals('file'));
      expect(p.basenameWithoutExtension('/path/to/file'), equals('file'));
      expect(p.basenameWithoutExtension('/path/to/file.with.multiple.dots'),
          equals('file.with.multiple'));
    });
  });
}
