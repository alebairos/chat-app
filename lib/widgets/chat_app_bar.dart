import 'package:flutter/material.dart';
import '../config/config_loader.dart';
import '../services/chat_export_service.dart';

/// Utility class containing export dialog functionality
/// This will be used by the enhanced settings screen
class ExportDialogUtils {
  static Future<void> showExportDialog(BuildContext context) async {
    final exportService = ChatExportService();

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
            title: const Text('Export Chat History'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Export your conversation history in WhatsApp format.'),
                  const SizedBox(height: 16),
                  const Text('📊 Export Summary:'),
                  const SizedBox(height: 8),
                  Text('• Total messages: ${stats['totalMessages']}'),
                  Text('• Your messages: ${stats['userMessages']}'),
                  Text('• AI messages: ${stats['aiMessages']}'),
                  if (stats['audioMessages'] > 0)
                    Text('• Audio messages: ${stats['audioMessages']}'),
                  if (stats['personaCounts'] != null &&
                      (stats['personaCounts'] as Map).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('👤 Messages by persona:'),
                    ...(stats['personaCounts'] as Map<String, int>).entries.map(
                          (entry) => Text('  • ${entry.key}: ${entry.value}'),
                        ),
                  ],
                  if (stats['dateRange'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                        '📅 Date range: ${_formatDateRange(stats['dateRange'])}'),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    '💡 The exported file will be shared using your device\'s sharing options.',
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

  static Future<void> _performExport(
      BuildContext context, ChatExportService exportService) async {
    // Show export progress dialog and capture the dialog context
    bool isDialogShown = false;

    // Use a completer to properly manage the dialog lifecycle
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
                Text('Exporting chat history...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      // First create the export file (fast operation)
      final filePath = await exportService.createExportFile();

      // Close progress dialog as soon as file is created
      if (isDialogShown && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogShown = false;
      }

      // Now trigger the sharing (this opens iOS share sheet)
      if (context.mounted) {
        await exportService.shareExportFile(filePath);

        // Show success message after sharing (user might have cancelled sharing)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat exported successfully!'),
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
        if (e.toString().contains('No chat history to export')) {
          errorMessage = 'No messages found to export';
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

  static String _formatDateRange(Map<String, dynamic> dateRange) {
    try {
      final earliest = dateRange['earliest'] as DateTime;
      final latest = dateRange['latest'] as DateTime;

      final format = earliest.year == latest.year ? 'MMM dd' : 'MMM dd, yyyy';

      return '${_formatDate(earliest, format)} - ${_formatDate(latest, format)}';
    } catch (e) {
      return 'Unknown';
    }
  }

  static String _formatDate(DateTime date, String format) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    if (format == 'MMM dd') {
      return '${months[date.month - 1]} ${date.day}';
    } else {
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  static Future<void> showAboutDialog(
      BuildContext context, ConfigLoader configLoader) async {
    final personaDisplayName = await configLoader.activePersonaDisplayName;
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('About $personaDisplayName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '$personaDisplayName is an AI assistant powered by Claude.'),
                const SizedBox(height: 16),
                const Text('You can:'),
                const SizedBox(height: 8),
                const Text('• Send text messages'),
                const Text('• Record audio messages'),
                const Text('• Long press your messages to delete them'),
                const Text('• Scroll up to load older messages'),
                const Text('• Export your chat history'),
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
  }
}
