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
      final testDir = 'test_audio_dir';
      final testFileName = 'test_audio_file.mp3';
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
      final outsidePath = '/tmp/outside_path.mp3';
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
      final testDir = 'test_files_dir';
      final testFileName = 'test_file.txt';
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
      exists = await PathUtils.fileExists('non_existent_file.txt');
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

      // Ensure it doesn't exist at first
      final initialDir = Directory(testDirPath);
      if (await initialDir.exists()) {
        await initialDir.delete(recursive: true);
      }

      // Test ensureDirectoryExists
      final createdDir = await PathUtils.ensureDirectoryExists(testDirPath);
      expect(await createdDir.exists(), isTrue);

      // Test that calling it again works fine
      final existingDir = await PathUtils.ensureDirectoryExists(testDirPath);
      expect(await existingDir.exists(), isTrue);

      // Clean up
      await createdDir.delete(recursive: true);
    });
  });
}
