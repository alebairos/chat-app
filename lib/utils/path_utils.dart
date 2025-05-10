import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Utility class for handling file paths
class PathUtils {
  /// Converts an absolute path to a relative path based on the app's documents directory
  /// Returns null if the path is not within the documents directory
  static Future<String?> absoluteToRelative(String absolutePath) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final docPath = docDir.path;

      if (absolutePath.startsWith(docPath)) {
        return absolutePath
            .substring(docPath.length + 1); // +1 to remove the leading slash
      }
      return null;
    } catch (e) {
      print('Error converting absolute to relative path: $e');
      return null;
    }
  }

  /// Converts a relative path to an absolute path by prepending the app's documents directory
  static Future<String> relativeToAbsolute(String relativePath) async {
    final docDir = await getApplicationDocumentsDirectory();
    return p.join(docDir.path, relativePath);
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

      return await File(absolutePath).exists();
    } catch (e) {
      print('Error checking if file exists: $e');
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
  static Future<Directory> ensureDirectoryExists(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      return await directory.create(recursive: true);
    }
    return directory;
  }
}
