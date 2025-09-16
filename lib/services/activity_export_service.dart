import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/activity_model.dart';
import '../utils/logger.dart';
import 'activity_memory_service.dart';

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
        throw Exception('Invalid import file: ${validationResult.errors.join(', ')}');
      }

      // Import activities using ActivityMemoryService.logActivity
      final importResult = await _importActivities(importData['activities']);

      _logger.info('Import completed: ${importResult.imported} imported, ${importResult.skipped} skipped, ${importResult.errors} errors');

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
    return await ActivityMemoryService.getAllActivitiesForExport(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Generate JSON export content
  String _generateJSONExport(List<ActivityModel> activities, DateTime? startDate, DateTime? endDate) {
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
      'activities': activities.map((activity) => _activityToJson(activity)).toList(),
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

    // Share the file
    final xFile = XFile(filePath);
    await Share.shareXFiles(
      [xFile],
      text: 'Activity Export - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
      subject: 'Activity Database Export',
    );
  }

  /// Read and parse import file
  Future<Map<String, dynamic>> _readImportFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw Exception('Import file not found: $filePath');
      }

      final content = await file.readAsString(encoding: utf8);
      final data = json.decode(content) as Map<String, dynamic>;
      
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
        
        // Use existing ActivityMemoryService.logActivity method
        await ActivityMemoryService.logActivity(
          activityCode: activityData['activityCode'] as String?,
          activityName: activityData['activityName'] as String,
          dimension: activityData['dimension'] as String,
          source: activityData['source'] as String? ?? 'Import',
          durationMinutes: activityData['durationMinutes'] as int?,
          notes: activityData['notes'] as String?,
          confidence: (activityData['confidenceScore'] as num?)?.toDouble() ?? 1.0,
        );
        
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

  /// Get export statistics for display purposes
  Future<Map<String, dynamic>> getExportStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
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
