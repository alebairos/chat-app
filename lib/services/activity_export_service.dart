import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/activity_model.dart';
import '../utils/logger.dart';
import 'activity_memory_service.dart';
import 'chat_storage_service.dart';

/// Result of an import operation
class ImportResult {
  final int imported;
  final int skipped;
  final int errors;
  final List<String> errorMessages;

  ImportResult({
    required this.imported,
    required this.skipped,
    required this.errors,
    this.errorMessages = const [],
  });

  bool get hasErrors => errors > 0;
  int get total => imported + skipped + errors;
}

/// Validation result for import data
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, this.errors = const []});
}

/// Service responsible for exporting and importing activity data
class ActivityExportService {
  final Logger _logger = Logger();

  /// Export complete activity database to JSON format
  Future<String?> exportActivityDatabase({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.info('Starting activity database export...');

      // Use existing ActivityMemoryService methods for data retrieval
      final activities = await _getAllActivitiesChronological(
        startDate: startDate,
        endDate: endDate,
      );

      if (activities.isEmpty) {
        _logger.info('No activities found for export');
        throw Exception('No activity data to export');
      }

      _logger.info('Found ${activities.length} activities to export');

      // Generate export content in JSON format
      final exportContent = _generateJSONExport(activities, startDate, endDate);

      // Create export file
      final filePath = await _createExportFile(exportContent);

      _logger.info('Export file created at: $filePath');

      // Share the file using platform's native sharing
      await _shareExportFile(filePath);

      return filePath;
    } catch (e) {
      _logger.error('Error during activity export: $e');
      rethrow;
    }
  }

  /// Create export file without sharing (for UI control over sharing)
  Future<String> createExportFile({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.info('Starting activity export file creation...');

      final activities = await _getAllActivitiesChronological(
        startDate: startDate,
        endDate: endDate,
      );

      if (activities.isEmpty) {
        _logger.info('No activities found for export');
        throw Exception('No activity data to export');
      }

      _logger.info('Found ${activities.length} activities to export');

      // Generate export content in JSON format
      final exportContent = _generateJSONExport(activities, startDate, endDate);

      // Create export file
      final filePath = await _createExportFile(exportContent);

      _logger.info('Export file created at: $filePath');

      return filePath;
    } catch (e) {
      _logger.error('Error during activity export file creation: $e');
      rethrow;
    }
  }

  /// Share an existing export file
  Future<void> shareExportFile(String filePath) async {
    await _shareExportFile(filePath);
  }

  /// Import activities from JSON export file
  Future<ImportResult> importActivityDatabase(String filePath) async {
    try {
      _logger.info('Starting activity database import from: $filePath');

      // Read and validate import file
      final importData = await _readImportFile(filePath);

      // Validate data format and integrity
      final validationResult = _validateImportData(importData);
      if (!validationResult.isValid) {
        throw Exception(
            'Invalid import file: ${validationResult.errors.join(', ')}');
      }

      // Import activities using ActivityMemoryService.logActivity
      final importResult = await _importActivities(importData['activities']);

      _logger.info(
          'Import completed: ${importResult.imported} imported, ${importResult.skipped} skipped, ${importResult.errors} errors');

      // FINAL TIMESTAMP RESTORATION: Ensure file timestamp is preserved after all operations
      await _finalTimestampRestore(filePath, importData);

      return importResult;
    } catch (e) {
      _logger.error('Error during activity import: $e');
      rethrow;
    }
  }

  /// Get all activities using existing service methods
  Future<List<ActivityModel>> _getAllActivitiesChronological({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    print('🔍 ActivityExportService: _getAllActivitiesChronological() called');

    // Use the proven Stats tab pattern: always ensure fresh connection
    print('🔍 ActivityExportService: Ensuring fresh database connection...');
    _logger.info('Using reliable fresh connection pattern for export');

    try {
      final success = await ActivityMemoryService.ensureFreshConnection();
      if (!success) {
        print('❌ ActivityExportService: Failed to establish fresh connection');
        throw Exception(
            'Activity database connection failed. Please restart the app and try again.');
      }
      print('✅ ActivityExportService: Fresh database connection established');
    } catch (e) {
      print('❌ ActivityExportService: Error establishing fresh connection: $e');
      throw Exception('Failed to establish database connection: $e');
    }

    print('🔍 ActivityExportService: Calling getAllActivitiesForExport...');
    final activities = await ActivityMemoryService.getAllActivitiesForExport(
      startDate: startDate,
      endDate: endDate,
    );

    print('✅ ActivityExportService: Retrieved ${activities.length} activities');
    return activities;
  }

  /// Generate JSON export content
  String _generateJSONExport(
      List<ActivityModel> activities, DateTime? startDate, DateTime? endDate) {
    final exportData = {
      'export_metadata': {
        'version': '1.0',
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0', // TODO: Get from package info
        'total_activities': activities.length,
        'date_range': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        }
      },
      'activities':
          activities.map((activity) => _activityToJson(activity)).toList(),
    };

    // Pretty print JSON for readability
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportData);
  }

  /// Convert ActivityModel to JSON map
  Map<String, dynamic> _activityToJson(ActivityModel activity) {
    return {
      'id': activity.id,
      'activityCode': activity.activityCode,
      'activityName': activity.activityName,
      'dimension': activity.dimension,
      'source': activity.source,
      'description': activity.description,
      'userDescription': activity.userDescription,
      'timestamp': activity.timestamp.toIso8601String(),
      'confidence': activity.confidence,
      'reasoning': activity.reasoning,
      'detectionMethod': activity.detectionMethod,
      'timeContext': activity.timeContext,
      'completedAt': activity.completedAt.toIso8601String(),
      'hour': activity.hour,
      'minute': activity.minute,
      'dayOfWeek': activity.dayOfWeek,
      'timeOfDay': activity.timeOfDay,
      'durationMinutes': activity.durationMinutes,
      'notes': activity.notes,
      'createdAt': activity.createdAt.toIso8601String(),
      'confidenceScore': activity.confidenceScore,
    };
  }

  /// Create the export file in temporary directory
  Future<String> _createExportFile(String content) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final filename = 'activity_export_$timestamp.json';
    final file = File('${directory.path}/$filename');

    // Write with UTF-8 encoding to support international characters
    await file.writeAsString(content, encoding: utf8);

    return file.path;
  }

  /// Share the export file using platform's native sharing
  Future<void> _shareExportFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Export file not found: $filePath');
    }

    // Get file size for logging
    final fileSize = await file.length();
    _logger.info('Sharing export file: $fileSize bytes');

    try {
      // Share the file with timeout to prevent hanging
      final xFile = XFile(filePath);
      await Share.shareXFiles(
        [xFile],
        text:
            'Activity Export - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
        subject: 'Activity Database Export',
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.warning('Share operation timed out after 30 seconds');
          // Return a default ShareResult to satisfy the return type
          return const ShareResult('', ShareResultStatus.unavailable);
        },
      );

      _logger.info('Share operation completed successfully');
    } catch (e) {
      _logger.warning('Share operation encountered an issue: $e');
      // Don't rethrow - the file was created successfully, sharing is optional
    }
  }

  /// Read and parse import file while preserving file timestamps
  Future<Map<String, dynamic>> _readImportFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('Import file not found: $filePath');
      }

      // Log comprehensive file metadata BEFORE import
      final originalStat = await file.stat();
      final originalModified = originalStat.modified;
      final originalAccessed = originalStat.accessed;
      final originalSize = originalStat.size;
      final originalType = originalStat.type;

      _logger.info('📁 BEFORE IMPORT - File Metadata:');
      _logger.info('   📄 Path: $filePath');
      _logger.info('   📅 Modified: $originalModified');
      _logger.info('   👁️ Accessed: $originalAccessed');
      _logger.info('   📏 Size: $originalSize bytes');
      _logger.info('   🏷️ Type: $originalType');

      // Read file content
      final content = await file.readAsString(encoding: utf8);
      final data = json.decode(content) as Map<String, dynamic>;

      // Attempt to restore original timestamps (may not work on all platforms)
      try {
        // Note: This may not work on iOS/mobile platforms due to file system restrictions
        await file.setLastModified(originalModified);
        _logger.info('✅ Successfully restored original file modification time');
      } catch (e) {
        _logger.warning(
            '⚠️ Could not restore original file timestamps (platform limitation): $e');
        // This is expected on mobile platforms - not a critical error
      }

      // Log comprehensive file metadata AFTER import attempt
      final finalStat = await file.stat();
      final finalModified = finalStat.modified;
      final finalAccessed = finalStat.accessed;
      final finalSize = finalStat.size;

      _logger.info('📁 AFTER IMPORT - File Metadata:');
      _logger.info('   📄 Path: $filePath');
      _logger.info('   📅 Modified: $finalModified');
      _logger.info('   👁️ Accessed: $finalAccessed');
      _logger.info('   📏 Size: $finalSize bytes');

      // Compare timestamps
      final modifiedChanged = originalModified != finalModified;
      final accessedChanged = originalAccessed != finalAccessed;
      final sizeChanged = originalSize != finalSize;

      _logger.info('📊 METADATA COMPARISON:');
      _logger.info(
          '   📅 Modified changed: $modifiedChanged ${modifiedChanged ? "($originalModified → $finalModified)" : ""}');
      _logger.info(
          '   👁️ Accessed changed: $accessedChanged ${accessedChanged ? "($originalAccessed → $finalAccessed)" : ""}');
      _logger.info(
          '   📏 Size changed: $sizeChanged ${sizeChanged ? "($originalSize → $finalSize)" : ""}');

      return data;
    } catch (e) {
      throw Exception('Failed to read import file: $e');
    }
  }

  /// Validate import data format and structure
  ValidationResult _validateImportData(Map<String, dynamic> data) {
    final errors = <String>[];

    // Check for required top-level fields
    if (!data.containsKey('export_metadata')) {
      errors.add('Missing export_metadata field');
    }

    if (!data.containsKey('activities')) {
      errors.add('Missing activities field');
    }

    // Validate export metadata
    if (data.containsKey('export_metadata')) {
      final metadata = data['export_metadata'] as Map<String, dynamic>?;
      if (metadata == null) {
        errors.add('Invalid export_metadata format');
      } else {
        if (!metadata.containsKey('version')) {
          errors.add('Missing version in export_metadata');
        }
      }
    }

    // Validate activities array
    if (data.containsKey('activities')) {
      final activities = data['activities'];
      if (activities is! List) {
        errors.add('Activities field must be an array');
      } else {
        // Validate a sample of activities
        for (int i = 0; i < activities.length && i < 5; i++) {
          final activity = activities[i];
          if (activity is! Map<String, dynamic>) {
            errors.add('Activity at index $i is not a valid object');
            continue;
          }

          // Check required fields
          final requiredFields = ['activityName', 'dimension', 'completedAt'];
          for (final field in requiredFields) {
            if (!activity.containsKey(field)) {
              errors.add('Activity at index $i missing required field: $field');
            }
          }
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Import activities using existing logActivity method
  Future<ImportResult> _importActivities(List<dynamic> activitiesData) async {
    _logger.info(
        '🚀 STARTING _importActivities with ${activitiesData.length} activities');

    // Ensure fresh database connection before starting import
    _logger.info(
        '🔍 ActivityExportService: Ensuring fresh connection for import...');
    try {
      final success = await ActivityMemoryService.ensureFreshConnection();
      if (!success) {
        throw Exception('Failed to establish database connection for import');
      }
      _logger.info(
          '✅ ActivityExportService: Fresh connection established for import');
    } catch (e) {
      _logger.error(
          '❌ ActivityExportService: Error establishing connection for import: $e');
      throw Exception('Database connection error during import: $e');
    }

    int imported = 0;
    int skipped = 0;
    int errors = 0;
    final errorMessages = <String>[];

    for (int i = 0; i < activitiesData.length; i++) {
      try {
        final activityData = activitiesData[i] as Map<String, dynamic>;

        // Check for duplicates based on timestamp and activity code
        final isDuplicate = await _checkForDuplicate(activityData);
        if (isDuplicate) {
          skipped++;
          _logger.debug('Skipping duplicate activity at index $i');
          continue;
        }

        // FT-124 Fix: Use importActivity to preserve original timestamps
        final activityModel = _createActivityFromImport(activityData);
        await ActivityMemoryService.importActivity(activityModel);

        imported++;

        if (imported % 10 == 0) {
          _logger.debug('Imported $imported activities...');
        }
      } catch (e) {
        errors++;
        final errorMsg = 'Failed to import activity at index $i: $e';
        errorMessages.add(errorMsg);
        _logger.warning(errorMsg);
      }
    }

    return ImportResult(
      imported: imported,
      skipped: skipped,
      errors: errors,
      errorMessages: errorMessages,
    );
  }

  /// Check if an activity already exists (duplicate detection)
  Future<bool> _checkForDuplicate(Map<String, dynamic> activityData) async {
    try {
      // Parse the timestamp from import data
      final completedAtStr = activityData['completedAt'] as String?;
      if (completedAtStr == null) return false;

      final completedAt = DateTime.parse(completedAtStr);
      final activityCode = activityData['activityCode'] as String?;
      final activityName = activityData['activityName'] as String;

      // Use ActivityMemoryService method for duplicate checking
      return await ActivityMemoryService.activityExists(
        completedAt: completedAt,
        activityCode: activityCode,
        activityName: activityName,
      );
    } catch (e) {
      _logger.warning('Error checking for duplicate: $e');
      return false; // If we can't check, allow import
    }
  }

  /// Create ActivityModel from import data preserving original timestamps (FT-124)
  ActivityModel _createActivityFromImport(Map<String, dynamic> data) {
    try {
      // Parse original timestamps from import data
      final completedAt = DateTime.parse(data['completedAt'] as String);
      final timestamp = data['timestamp'] != null
          ? DateTime.parse(data['timestamp'] as String)
          : completedAt;
      final createdAt = data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : completedAt;

      // Create ActivityModel with preserved timestamps
      final activity = ActivityModel.fromDetection(
        activityCode: data['activityCode'] as String?,
        activityName: data['activityName'] as String,
        dimension: data['dimension'] as String,
        source: data['source'] as String? ?? 'Import',
        completedAt: completedAt, // PRESERVE ORIGINAL TIMESTAMP
        dayOfWeek:
            data['dayOfWeek'] as String? ?? _getDayOfWeek(completedAt.weekday),
        timeOfDay:
            data['timeOfDay'] as String? ?? _getTimeOfDay(completedAt.hour),
        durationMinutes: data['durationMinutes'] as int?,
        notes: data['notes'] as String?,
        confidenceScore: (data['confidenceScore'] as num?)?.toDouble() ?? 1.0,
      );

      // Set additional fields that might not be in fromDetection
      if (data['id'] != null) {
        activity.id = data['id'] as int;
      }
      if (data['description'] != null) {
        activity.description = data['description'] as String;
      }
      if (data['userDescription'] != null) {
        activity.userDescription = data['userDescription'] as String;
      }
      if (data['confidence'] != null) {
        activity.confidence = data['confidence'] as String;
      }
      if (data['reasoning'] != null) {
        activity.reasoning = data['reasoning'] as String;
      }
      if (data['detectionMethod'] != null) {
        activity.detectionMethod = data['detectionMethod'] as String;
      }
      if (data['timeContext'] != null) {
        activity.timeContext = data['timeContext'] as String;
      }

      // Override timestamps to preserve original values
      activity.timestamp = timestamp;
      activity.createdAt = createdAt;
      activity.hour = completedAt.hour;
      activity.minute = completedAt.minute;

      return activity;
    } catch (e) {
      _logger.error('Error creating activity from import data: $e');
      rethrow;
    }
  }

  /// Helper to get day of week name
  String _getDayOfWeek(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  /// Helper to get time of day category
  String _getTimeOfDay(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  /// Final timestamp restoration after all import operations complete
  Future<void> _finalTimestampRestore(
      String filePath, Map<String, dynamic> importData) async {
    try {
      _logger.info(
          '🔄 FINAL: Restoring file timestamp after import completion...');

      final file = File(filePath);
      if (!await file.exists()) {
        _logger.warning(
            '⚠️ FINAL: File no longer exists, cannot restore timestamp');
        return;
      }

      // Get the original export timestamp from the import data
      final exportMetadata =
          importData['export_metadata'] as Map<String, dynamic>?;
      if (exportMetadata == null || exportMetadata['export_date'] == null) {
        _logger.warning('⚠️ FINAL: No export timestamp found in metadata');
        return;
      }

      final originalExportTime =
          DateTime.parse(exportMetadata['export_date'] as String);
      _logger.info(
          '🎯 FINAL: Restoring to original export time: $originalExportTime');

      // Check current timestamp before final restoration
      final currentStat = await file.stat();
      _logger
          .info('📅 FINAL BEFORE: Current timestamp: ${currentStat.modified}');

      // Restore to original export time
      await file.setLastModified(originalExportTime);

      // Verify final restoration
      final finalStat = await file.stat();
      _logger.info('📅 FINAL AFTER: Final timestamp: ${finalStat.modified}');

      final success = finalStat.modified.isAtSameMomentAs(originalExportTime) ||
          (finalStat.modified.difference(originalExportTime).inSeconds.abs() <
              2);

      if (success) {
        _logger
            .info('✅ FINAL: Successfully preserved original export timestamp');
      } else {
        _logger.warning(
            '⚠️ FINAL: Timestamp restoration may have been overridden by system');
      }
    } catch (e) {
      _logger.warning(
          '⚠️ FINAL: Could not restore final timestamp (platform limitation): $e');
    }
  }

  /// Get export statistics for display purposes
  Future<Map<String, dynamic>> getExportStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.info('🔍 ActivityExportService: getExportStatistics() called');

      // Use reliable fresh connection pattern instead of availability check
      _logger.info(
          '🔍 ActivityExportService: Ensuring fresh database connection for statistics...');

      try {
        final success = await ActivityMemoryService.ensureFreshConnection();
        if (!success) {
          _logger.warning(
              '❌ ActivityExportService: Failed to establish fresh connection for statistics');
          return {
            'total_activities': 0,
            'oracle_activities': 0,
            'custom_activities': 0,
            'date_range': {'earliest': null, 'latest': null},
            'dimensions': <String, int>{},
            'database_error': 'Failed to establish database connection',
          };
        }
        _logger.info(
            '✅ ActivityExportService: Fresh connection established for statistics');
      } catch (e) {
        _logger.error(
            '❌ ActivityExportService: Error establishing connection for statistics: $e');
        return {
          'total_activities': 0,
          'oracle_activities': 0,
          'custom_activities': 0,
          'date_range': {'earliest': null, 'latest': null},
          'dimensions': <String, int>{},
          'database_error': 'Database connection error: $e',
        };
      }

      final activities = await _getAllActivitiesChronological(
        startDate: startDate,
        endDate: endDate,
      );

      final stats = {
        'total_activities': activities.length,
        'oracle_activities': activities.where((a) => a.isOracleActivity).length,
        'custom_activities': activities.where((a) => a.isCustomActivity).length,
        'date_range': {
          'earliest': activities.isNotEmpty
              ? activities.first.completedAt.toIso8601String()
              : null,
          'latest': activities.isNotEmpty
              ? activities.last.completedAt.toIso8601String()
              : null,
        },
        'dimensions': _getDimensionStats(activities),
      };

      return stats;
    } catch (e) {
      _logger.error('Failed to get export statistics: $e');
      return {
        'total_activities': 0,
        'oracle_activities': 0,
        'custom_activities': 0,
        'date_range': {'earliest': null, 'latest': null},
        'dimensions': <String, int>{},
        'database_error': e.toString(),
      };
    }
  }

  /// Get dimension statistics
  Map<String, int> _getDimensionStats(List<ActivityModel> activities) {
    final dimensionCounts = <String, int>{};

    for (final activity in activities) {
      dimensionCounts[activity.dimension] =
          (dimensionCounts[activity.dimension] ?? 0) + 1;
    }

    return dimensionCounts;
  }
}
