# FT-122: Activity Database Export & Import

**Feature ID**: FT-122  
**Priority**: High  
**Category**: Data Management > Backup & Restore  
**Effort Estimate**: 2-3 days  
**Dependencies**: Existing ActivityMemoryService, file_picker package  
**Status**: Specification  

## Overview

Implement comprehensive export and import functionality for the activities database to enable users to backup their activity history and restore it on new devices or after app deletion. This addresses the current limitation where activities are stored only in local storage with no backup mechanism.

## Problem Statement

**Current Issues:**
- Activities database is local-only with no backup capability
- Users lose all activity history when switching devices or reinstalling app
- No way to transfer activity data between devices
- Risk of permanent data loss if device is lost or damaged

**User Impact:**
- Loss of valuable activity tracking history and patterns
- Inability to maintain continuity across device changes
- No disaster recovery for activity data
- Reduced confidence in long-term activity tracking

## Solution: Activity Database Export & Import System

### Core Approach
Create a robust export/import system leveraging existing ActivityMemoryService methods, using JSON format for structured activity data integrity and completeness.

## Functional Requirements

### Export Functionality
- **FR-122-01**: Export complete activities database to JSON format
- **FR-122-02**: Support date range filtering for partial exports
- **FR-122-03**: Use existing ActivityMemoryService database queries for data retrieval
- **FR-122-04**: Include all activity metadata (codes, dimensions, timestamps, confidence)
- **FR-122-05**: Generate human-readable export files with proper formatting
- **FR-122-06**: Share export files through platform's native sharing system

### Import Functionality
- **FR-122-07**: Import activities from JSON export files
- **FR-122-08**: Validate import file format and data integrity
- **FR-122-09**: Handle duplicate activities during import (merge strategy)
- **FR-122-10**: Provide import progress feedback to user
- **FR-122-11**: Support partial imports with error recovery
- **FR-122-12**: Maintain existing activities while importing new ones

### Data Integrity
- **FR-122-13**: Preserve all ActivityModel fields during export/import
- **FR-122-14**: Maintain timestamp precision and timezone information
- **FR-122-15**: Validate Oracle activity codes and dimensions
- **FR-122-16**: Ensure confidence scores and metadata are preserved
- **FR-122-17**: Handle custom activities and Oracle activities consistently

## Non-Functional Requirements

### Performance
- **NFR-122-01**: Handle large activity datasets (1000+ activities) efficiently
- **NFR-122-02**: Use batched processing to prevent memory issues
- **NFR-122-03**: Provide progress indicators for long-running operations
- **NFR-122-04**: Complete export/import operations within reasonable time limits

### Reliability
- **NFR-122-05**: Ensure 100% data completeness in exports (no missing activities)
- **NFR-122-06**: Validate data integrity before and after import
- **NFR-122-07**: Handle edge cases and corrupted data gracefully
- **NFR-122-08**: Provide clear error messages for failed operations

### Usability
- **NFR-122-09**: Integrate seamlessly with existing Settings screen
- **NFR-122-10**: Use familiar export/import UI patterns
- **NFR-122-11**: Provide clear confirmation and success feedback
- **NFR-122-12**: Support standard file sharing and selection workflows

## Technical Implementation

### 1. ActivityExportService

**File**: `lib/services/activity_export_service.dart`

```dart
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
      final exportContent = _generateJSONExport(activities);

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

      _logger.info('Import completed: ${importResult.imported} imported, ${importResult.skipped} skipped');

      return importResult;
    } catch (e) {
      _logger.error('Error during activity import: $e');
      rethrow;
    }
  }
}
```

### 2. Export Data Format

**JSON Structure:**
```json
{
  "export_metadata": {
    "version": "1.0",
    "export_date": "2025-09-16T10:30:00.000Z",
    "app_version": "1.0.0",
    "total_activities": 437,
    "date_range": {
      "start": "2025-01-01T00:00:00.000Z",
      "end": "2025-09-16T10:30:00.000Z"
    }
  },
  "activities": [
    {
      "id": 1,
      "activityCode": "SF1",
      "activityName": "Beber água",
      "dimension": "saude_fisica",
      "source": "Oracle oracle_prompt_3.0.md",
      "description": "Hidratação essencial",
      "userDescription": "Bebi água",
      "timestamp": "2025-09-16T08:30:00.000Z",
      "confidence": "high",
      "reasoning": "User explicitly mentioned drinking water",
      "detectionMethod": "semantic_ft064",
      "timeContext": "morning routine",
      "completedAt": "2025-09-16T08:30:00.000Z",
      "hour": 8,
      "minute": 30,
      "dayOfWeek": "Monday",
      "timeOfDay": "morning",
      "durationMinutes": null,
      "notes": "Refreshing start to the day",
      "createdAt": "2025-09-16T08:31:00.000Z",
      "confidenceScore": 0.95
    }
  ]
}
```

### 3. Settings Screen Integration

**File**: `lib/screens/settings_screen.dart`

```dart
// Add to existing settings options
ListTile(
  leading: Icon(Icons.download),
  title: Text('Export Activity Data'),
  subtitle: Text('Backup your activity history'),
  onTap: () => _exportActivityData(),
),
ListTile(
  leading: Icon(Icons.upload),
  title: Text('Import Activity Data'),
  subtitle: Text('Restore activity history from backup'),
  onTap: () => _importActivityData(),
),

/// Export activity data with user confirmation
Future<void> _exportActivityData() async {
  try {
    // Show confirmation dialog
    final confirmed = await _showExportConfirmation();
    if (!confirmed) return;

    // Show loading indicator
    _showLoadingDialog('Exporting activity data...');

    // Perform export
    final exportService = ActivityExportService();
    final filePath = await exportService.exportActivityDatabase();

    // Hide loading and show success
    Navigator.pop(context); // Hide loading
    if (filePath != null) {
      _showSuccessDialog('Activity data exported successfully');
    }
  } catch (e) {
    Navigator.pop(context); // Hide loading
    _showErrorDialog('Export failed: $e');
  }
}

/// Import activity data with file selection
Future<void> _importActivityData() async {
  try {
    // Show file picker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path!;

    // Show confirmation dialog
    final confirmed = await _showImportConfirmation();
    if (!confirmed) return;

    // Show loading indicator
    _showLoadingDialog('Importing activity data...');

    // Perform import
    final exportService = ActivityExportService();
    final importResult = await exportService.importActivityDatabase(filePath);

    // Hide loading and show results
    Navigator.pop(context); // Hide loading
    _showImportResultDialog(importResult);
  } catch (e) {
    Navigator.pop(context); // Hide loading
    _showErrorDialog('Import failed: $e');
  }
}
```

### 4. Data Retrieval Implementation

**Leverage Existing ActivityMemoryService Methods:**

```dart
/// Get all activities using existing service methods
Future<List<ActivityModel>> _getAllActivitiesChronological({
  DateTime? startDate,
  DateTime? endDate,
}) async {
  try {
    // Use existing database access pattern
    final isar = ActivityMemoryService._database;
    
    // Build query with date filtering
    var query = isar.activityModels.where();
    
    if (startDate != null && endDate != null) {
      query = query.filter().completedAtBetween(startDate, endDate);
    } else if (startDate != null) {
      query = query.filter().completedAtGreaterThan(startDate);
    } else if (endDate != null) {
      query = query.filter().completedAtLessThan(endDate);
    }
    
    // Get all activities sorted chronologically
    final activities = await query.sortByCompletedAt().findAll();
    
    _logger.info('Retrieved ${activities.length} activities for export');
    return activities;
  } catch (e) {
    _logger.error('Failed to retrieve activities for export: $e');
    return [];
  }
}

/// Import activities using existing logActivity method
Future<ImportResult> _importActivities(List<dynamic> activitiesData) async {
  int imported = 0;
  int skipped = 0;
  
  for (final activityData in activitiesData) {
    try {
      // Check for duplicates based on timestamp and activity code
      final isDuplicate = await _checkForDuplicate(activityData);
      if (isDuplicate) {
        skipped++;
        continue;
      }
      
      // Use existing ActivityMemoryService.logActivity method
      await ActivityMemoryService.logActivity(
        activityCode: activityData['activityCode'],
        activityName: activityData['activityName'],
        dimension: activityData['dimension'],
        source: activityData['source'],
        durationMinutes: activityData['durationMinutes'],
        notes: activityData['notes'],
        confidence: activityData['confidenceScore'] ?? 1.0,
      );
      
      imported++;
    } catch (e) {
      _logger.warning('Failed to import activity: $e');
      skipped++;
    }
  }
  
  return ImportResult(imported: imported, skipped: skipped);
}
```

## Implementation Strategy

### Phase 1: Core Export Functionality (Day 1)
1. **ActivityExportService Creation**
   - Leverage existing ActivityMemoryService database access
   - Create JSON export format with all ActivityModel fields
   - Add file creation and sharing functionality

2. **Export Testing**
   - Test with existing activity datasets
   - Validate JSON format and data completeness
   - Ensure all metadata is preserved

### Phase 2: Import Functionality (Day 2)
1. **Import Implementation**
   - Add JSON file reading and validation
   - Use existing ActivityMemoryService.logActivity for imports
   - Implement duplicate detection based on timestamp and activity code

2. **Data Validation**
   - Validate import file format and structure
   - Ensure compatibility with existing ActivityModel structure
   - Test import with various activity types (Oracle and custom)

### Phase 3: UI Integration & Testing (Day 3)
1. **Settings Screen Integration**
   - Add export/import options to existing settings
   - Implement file picker and sharing workflows
   - Create confirmation and progress dialogs

2. **End-to-End Testing**
   - Test complete export/import cycle
   - Validate data integrity with real activity data
   - Test edge cases and error handling

## Testing Strategy

### Test Scenarios

**Export Testing:**
```
1. Export empty database (should show appropriate message)
2. Export small dataset (< 50 activities)
3. Export large dataset (500+ activities)
4. Export with date range filtering
5. Export with mixed Oracle and custom activities
```

**Import Testing:**
```
1. Import valid export file (should succeed completely)
2. Import file with duplicate activities (should handle gracefully)
3. Import corrupted JSON file (should show clear error)
4. Import file with missing fields (should validate and report)
5. Import large dataset (should show progress)
```

**Data Integrity Testing:**
```
1. Export → Import → Verify all fields match
2. Test timestamp precision preservation
3. Validate Oracle activity codes and dimensions
4. Check confidence scores and metadata
5. Verify custom activities are handled correctly
```

## Success Metrics

### Primary Success Criteria
- ✅ 100% data completeness in exports (no missing activities)
- ✅ Successful import of exported data with full integrity
- ✅ Proper handling of duplicate activities during import
- ✅ Clear user feedback for all export/import operations
- ✅ Seamless integration with existing Settings screen

### Quality Metrics
- **Export Completeness**: All activities included in export files
- **Import Accuracy**: 100% successful import of valid export files
- **Data Integrity**: All ActivityModel fields preserved through export/import cycle
- **User Experience**: Clear progress feedback and error handling
- **Performance**: Handle 1000+ activities within reasonable time limits

## Risks & Mitigations

### Technical Risks
- **Risk**: Large datasets might cause memory issues during export
  - **Mitigation**: Leverage existing ActivityMemoryService efficient database queries
- **Risk**: Import might create duplicate activities
  - **Mitigation**: Implement duplicate detection based on timestamp and activity code
- **Risk**: JSON format changes might break compatibility
  - **Mitigation**: Include version metadata and validation in import process

### Data Risks
- **Risk**: Corrupted export files might cause data loss
  - **Mitigation**: Validate export file integrity before import, provide clear error messages
- **Risk**: Partial imports might leave database in inconsistent state
  - **Mitigation**: Use database transactions and rollback on errors

## Future Enhancements

### Immediate Follow-ups
- Monitor export/import usage patterns and performance
- Gather user feedback on workflow usability
- Add support for selective import (choose which activities to import)

### Long-term Possibilities
- Cloud backup integration for automatic activity sync
- Encrypted export files for enhanced security
- Activity data migration tools for app updates
- Integration with external fitness and productivity apps

## Conclusion

This feature provides essential backup and restore functionality for the activities database, ensuring users never lose their valuable activity tracking history. By following the proven patterns from FT-110 and adapting them for structured activity data, we deliver a reliable, user-friendly solution that maintains data integrity while providing the flexibility users need for device management and data portability.

The implementation prioritizes data completeness, user experience, and future extensibility, establishing a solid foundation for advanced data management features.
