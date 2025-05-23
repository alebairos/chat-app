import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:character_ai_clone/utils/path_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PathUtils Integration Tests', () {
    test('absoluteToRelative and relativeToAbsolute work correctly', () async {
      // Get the documents directory
      final docDir = await getApplicationDocumentsDirectory();
      final docPath = docDir.path;

      // Create a test file path
      const testDir = 'test_audio_dir';
      const testFileName = 'test_audio_file.mp3';
      final relativePath = p.join(testDir, testFileName);
      final absolutePath = p.join(docPath, relativePath);

      // Create the directory if it doesn't exist
      final directory = Directory(p.join(docPath, testDir));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Test absoluteToRelative
      final convertedRelativePath =
          await PathUtils.absoluteToRelative(absolutePath);
      expect(convertedRelativePath, relativePath);

      // Test relativeToAbsolute
      final convertedAbsolutePath =
          await PathUtils.relativeToAbsolute(relativePath);
      expect(convertedAbsolutePath, absolutePath);

      // Test absoluteToRelative with path outside documents directory
      const outsidePath = '/tmp/outside_path.mp3';
      final outsideRelativePath =
          await PathUtils.absoluteToRelative(outsidePath);
      expect(outsideRelativePath, isNull);

      // Clean up
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('fileExists works correctly', () async {
      // Get the documents directory
      final docDir = await getApplicationDocumentsDirectory();
      final docPath = docDir.path;

      // Create a test file
      const testDir = 'test_files_dir';
      const testFileName = 'test_file.txt';
      final relativePath = p.join(testDir, testFileName);
      final absolutePath = p.join(docPath, relativePath);

      // Create the directory
      final directory = Directory(p.join(docPath, testDir));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Create the file
      final file = File(absolutePath);
      await file.writeAsString('Test content');

      // Test fileExists with absolute path
      bool exists = await PathUtils.fileExists(absolutePath);
      expect(exists, isTrue);

      // Test fileExists with relative path
      exists = await PathUtils.fileExists(relativePath);
      expect(exists, isTrue);

      // Test fileExists with non-existent file
      const nonExistentFile = 'non_existent_file.txt';
      exists = await PathUtils.fileExists(nonExistentFile);
      expect(exists, isFalse);

      // Clean up
      await file.delete();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('ensureDirectoryExists works correctly', () async {
      // Get the documents directory
      final docDir = await getApplicationDocumentsDirectory();
      final docPath = docDir.path;

      // Test directory path
      final testDirPath = p.join(docPath, 'test_ensure_dir');
      final testDir = Directory(testDirPath);

      // Ensure it doesn't exist at first
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }

      // Test ensureDirectoryExists
      bool success = await PathUtils.ensureDirectoryExists(testDirPath);
      expect(success, isTrue);
      expect(await testDir.exists(), isTrue);

      // Test that calling it again works fine
      success = await PathUtils.ensureDirectoryExists(testDirPath);
      expect(success, isTrue);
      expect(await testDir.exists(), isTrue);

      // Clean up
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });
  });
}
