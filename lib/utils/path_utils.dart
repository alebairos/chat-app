import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'logger.dart';

/// Utility class for handling file paths
class PathUtils {
  static final Logger _logger = Logger();

  /// Converts an absolute path to a relative path based on the app's documents directory
  /// Returns null if the path is not within the documents directory
  static Future<String?> absoluteToRelative(String absolutePath) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final docPath = docDir.path;

      if (absolutePath.startsWith(docPath)) {
        final result = absolutePath.substring(docPath.length + 1);
        return result;
      }
      return null;
    } catch (e) {
      _logger.error('Error converting absolute to relative path: $e');
      return null;
    }
  }

  /// Converts a relative path to an absolute path by prepending the app's documents directory
  static Future<String> relativeToAbsolute(String relativePath) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final docPath = docDir.path;
      final absolutePath = p.join(docPath, relativePath);

      // Check for directory existence
      try {
        final directory = Directory(p.dirname(absolutePath));
        if (!await directory.exists()) {
          _logger.debug(
              'Directory does not exist: ${directory.path}, creating it');
          await directory.create(recursive: true);
        }
      } catch (dirError) {
        _logger.error(
            'Failed to ensure directory exists for $absolutePath: $dirError (proceeding with path conversion)');
        // Proceeding, as the primary goal is path conversion.
        // The actual file operation later will fail if the directory is truly needed and couldn't be created.
      }

      _logger.debug(
          'Converted relative path: $relativePath to absolute: $absolutePath');
      return absolutePath;
    } catch (e) {
      _logger.error('Error converting relative to absolute path: $e');
      return relativePath; // Return original path as fallback for major errors in path retrieval/joining
    }
  }

  /// Checks if a path is absolute
  static bool isAbsolutePath(String path) {
    return p.isAbsolute(path);
  }

  /// Checks if a file exists at the given path (handles both absolute and relative paths)
  static Future<bool> fileExists(String path) async {
    try {
      String absolutePath;
      if (isAbsolutePath(path)) {
        absolutePath = path;
      } else {
        absolutePath = await relativeToAbsolute(path);
      }

      final file = File(absolutePath);
      final exists = await file.exists();
      if (!exists) {
        _logger.debug('File does not exist at path: $absolutePath');
      }
      return exists;
    } catch (e) {
      _logger.error('Error checking if file exists: $e');
      return false;
    }
  }

  /// Gets the file name from a path
  static String getFileName(String path) {
    return p.basename(path);
  }

  /// Gets the directory name from a path
  static String getDirName(String path) {
    return p.dirname(path);
  }

  /// Creates a directory if it doesn't exist
  static Future<bool> ensureDirectoryExists(String path) async {
    try {
      String absolutePath;
      if (isAbsolutePath(path)) {
        absolutePath = path;
      } else {
        absolutePath = await relativeToAbsolute(path);
      }

      final directory = Directory(absolutePath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return true;
    } catch (e) {
      _logger.error('Error creating directory: $e');
      return false;
    }
  }
}
