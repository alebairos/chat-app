import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/activity_export_service.dart';

/// Utility class containing activity export/import dialog functionality
class ActivityExportDialogUtils {
  static Future<void> showExportDialog(BuildContext context) async {
    final exportService = ActivityExportService();

    // Show loading dialog while getting statistics
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final stats = await exportService.getExportStatistics();

      if (context.mounted) {
        // Close loading dialog
        Navigator.pop(context);

        // Show export confirmation dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Activity Data'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Export your activity tracking data for backup or transfer to another device.'),
                  const SizedBox(height: 16),
                  const Text('📊 Export Summary:'),
                  const SizedBox(height: 8),
                  Text('• Total activities: ${stats['total_activities']}'),
                  Text('• Oracle activities: ${stats['oracle_activities']}'),
                  Text('• Custom activities: ${stats['custom_activities']}'),
                  if (stats['dimensions'] != null &&
                      (stats['dimensions'] as Map).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('📂 Activities by dimension:'),
                    ...(stats['dimensions'] as Map<String, int>).entries.map(
                          (entry) => Text('  • ${_formatDimension(entry.key)}: ${entry.value}'),
                        ),
                  ],
                  if (stats['date_range'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                        '📅 Date range: ${_formatDateRange(stats['date_range'])}'),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    '💡 The exported JSON file will be shared using your device\'s sharing options.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  await _performExport(context, exportService);
                },
                child: const Text('Export'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting export statistics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> showImportDialog(BuildContext context) async {
    try {
      // Show file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Activity Export File',
      );

      if (result == null || result.files.isEmpty) return; // User cancelled

      final filePath = result.files.first.path!;

      // Show confirmation dialog
      final confirmed = await _showImportConfirmation(context);
      if (!confirmed) return;

      // Perform import
      await _performImport(context, filePath);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import selection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> _performExport(
      BuildContext context, ActivityExportService exportService) async {
    // Show export progress dialog
    bool isDialogShown = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        isDialogShown = true;
        return PopScope(
          canPop: false, // Prevent dismissal during export
          child: const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Exporting activity data...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Create the export file
      final filePath = await exportService.createExportFile();

      // Close progress dialog
      if (isDialogShown && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogShown = false;
      }

      // Share the file
      if (context.mounted) {
        await exportService.shareExportFile(filePath);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity data exported successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close progress dialog first
      if (isDialogShown && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogShown = false;
      }

      // Show error message
      if (context.mounted) {
        String errorMessage = 'Export failed: $e';
        if (e.toString().contains('No activity data to export')) {
          errorMessage = 'No activities found to export';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  static Future<bool> _showImportConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Activity Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will import activities from the selected file.'),
            SizedBox(height: 16),
            Text('⚠️ Important:'),
            SizedBox(height: 8),
            Text('• Duplicate activities will be skipped'),
            Text('• Existing activities will be preserved'),
            Text('• Invalid entries will be reported'),
            SizedBox(height: 16),
            Text('Continue with import?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  static Future<void> _performImport(BuildContext context, String filePath) async {
    // Show import progress dialog
    bool isDialogShown = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        isDialogShown = true;
        return PopScope(
          canPop: false, // Prevent dismissal during import
          child: const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Importing activity data...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      final exportService = ActivityExportService();
      final importResult = await exportService.importActivityDatabase(filePath);

      // Close progress dialog
      if (isDialogShown && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogShown = false;
      }

      // Show results dialog
      if (context.mounted) {
        await _showImportResults(context, importResult);
      }
    } catch (e) {
      // Close progress dialog first
      if (isDialogShown && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogShown = false;
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  static Future<void> _showImportResults(
      BuildContext context, ImportResult result) async {
    final isSuccess = result.imported > 0 || (result.imported == 0 && result.skipped > 0 && result.errors == 0);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSuccess ? 'Import Completed' : 'Import Issues'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 Import Summary:'),
              const SizedBox(height: 8),
              Text('• Activities imported: ${result.imported}'),
              Text('• Activities skipped (duplicates): ${result.skipped}'),
              if (result.errors > 0) ...[
                Text('• Errors encountered: ${result.errors}'),
                if (result.errorMessages.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('❌ Error details:'),
                  ...result.errorMessages.take(3).map((error) => Text('  • $error')),
                  if (result.errorMessages.length > 3)
                    Text('  • ... and ${result.errorMessages.length - 3} more'),
                ],
              ],
              const SizedBox(height: 16),
              Text(
                isSuccess
                    ? '✅ Import completed successfully!'
                    : '⚠️ Import completed with issues. Check the details above.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static String _formatDimension(String dimension) {
    // Convert dimension codes to readable names
    final dimensionNames = {
      'saude_fisica': 'Physical Health',
      'saude_mental': 'Mental Health',
      'relacionamentos': 'Relationships',
      'espiritualidade': 'Spirituality',
      'trabalho': 'Work',
      'custom': 'Custom',
    };
    
    return dimensionNames[dimension] ?? dimension;
  }

  static String _formatDateRange(Map<String, dynamic> dateRange) {
    try {
      final earliest = dateRange['earliest'] as String?;
      final latest = dateRange['latest'] as String?;

      if (earliest == null || latest == null) {
        return 'No activities found';
      }

      final earliestDate = DateTime.parse(earliest);
      final latestDate = DateTime.parse(latest);

      final format = earliestDate.year == latestDate.year ? 'MMM dd' : 'MMM dd, yyyy';

      return '${_formatDate(earliestDate, format)} - ${_formatDate(latestDate, format)}';
    } catch (e) {
      return 'Unknown';
    }
  }

  static String _formatDate(DateTime date, String format) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (format == 'MMM dd') {
      return '${months[date.month - 1]} ${date.day}';
    } else {
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}
