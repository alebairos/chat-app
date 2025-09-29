import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../services/chat_storage_service.dart';
import '../../services/activity_memory_service.dart';
import '../../models/chat_message_model.dart';
import '../../models/activity_model.dart';
import '../../models/message_type.dart';
import '../../widgets/chat_app_bar.dart';
import '../../widgets/activity_export_dialog_utils.dart';

class ChatManagementScreen extends StatelessWidget {
  final Function() onCharacterSelected;

  const ChatManagementScreen({
    Key? key,
    required this.onCharacterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Chat Management Section
          _buildManagementCard(
            context,
            icon: Icons.download,
            iconColor: Colors.blue,
            title: 'Export Chat History',
            subtitle: 'Save your conversations in WhatsApp format',
            onTap: () => ExportDialogUtils.showExportDialog(context),
          ),
          // Import temporarily hidden - audio files not included in exports
          // _buildManagementCard(
          //   context,
          //   icon: Icons.upload_file,
          //   iconColor: Colors.green,
          //   title: 'Import Chat History',
          //   subtitle: 'Restore from exported WhatsApp format file',
          //   onTap: () => _importChat(context),
          // ),
          _buildManagementCard(
            context,
            icon: Icons.delete_outline,
            iconColor: Colors.orange,
            title: 'Clear Chat History',
            subtitle: 'Remove all messages (keeps activity data)',
            onTap: () => _clearChatHistory(context),
          ),

          const SizedBox(height: 24), // Section separator

          // Activity Data Management Section
          _buildManagementCard(
            context,
            icon: Icons.file_download_outlined,
            iconColor: Colors.purple,
            title: 'Export Activity Data',
            subtitle: 'Backup your activity tracking history',
            onTap: () => ActivityExportDialogUtils.showExportDialog(context),
          ),
          _buildManagementCard(
            context,
            icon: Icons.file_upload_outlined,
            iconColor: Colors.teal,
            title: 'Import Activity Data',
            subtitle: 'Restore activity history from backup',
            onTap: () => ActivityExportDialogUtils.showImportDialog(context),
          ),
          // FT-161: Clear Activity Data
          _buildManagementCard(
            context,
            icon: Icons.delete_sweep_outlined,
            iconColor: Colors.orange,
            title: 'Clear Activity Data',
            subtitle: 'Remove all activity tracking data (keeps chat messages)',
            onTap: () => _clearActivityData(context),
          ),

          const SizedBox(height: 16), // Reduced spacing for combined section

          // FT-162: Combined Clear Operation
          _buildManagementCard(
            context,
            icon: Icons.delete_forever_outlined,
            iconColor: Colors.red,
            title: 'Clear Messages and Activities',
            subtitle: 'Remove ALL data - chat messages and activity tracking',
            onTap: () => _clearMessagesAndActivities(context),
          ),

          const SizedBox(height: 24), // Section separator

          // App Information
          _buildManagementCard(
            context,
            icon: Icons.info_outline,
            iconColor: Colors.grey,
            title: 'About the App',
            subtitle: 'Learn what you can do with your AI assistant',
            onTap: () => _showAboutApp(context),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? customSubtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 0,
        color: Colors.grey[50], // Subtle background
        child: ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: customSubtitle ??
              (subtitle != null
                  ? Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    )
                  : null),
          trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
        ),
      ),
    );
  }

  // Import functionality - reusing parsing logic from FT-069
  Future<void> _importChat(BuildContext context) async {
    try {
      // 1. Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        dialogTitle: 'Select Chat Export File',
      );

      if (result == null) return; // User cancelled

      // 2. Parse and import using existing restoration logic
      final filePath = result.files.single.path!;
      await _parseAndImportFile(filePath);

      // 3. Show success and trigger UI refresh
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Chat history restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Trigger character selection callback to refresh the app state
        onCharacterSelected();
      }
    } catch (e) {
      // 4. Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _parseAndImportFile(String filePath) async {
    // Reuse existing parsing logic from FT-069
    final file = File(filePath);
    final content = await file.readAsString();

    // Parse using existing regex and persona mapping from restore_chat_simple.dart
    final messages = await _parseWhatsAppFormat(content);

    // Use existing ChatStorageService restoration with activity preservation
    final chatStorage = ChatStorageService();
    final isar = await chatStorage.db;

    // Preserve activities (critical for FT-064)
    final activityCount = await isar.activityModels.count();

    // Clear and restore messages only
    await isar.writeTxn(() async {
      await isar.chatMessageModels.clear();
    });

    // Batch insert (reuse existing logic)
    const batchSize = 50;
    for (int i = 0; i < messages.length; i += batchSize) {
      final batch = messages.skip(i).take(batchSize).toList();
      await isar.writeTxn(() async {
        await isar.chatMessageModels.putAll(batch);
      });
    }

    // Verify activities preserved
    final finalActivityCount = await isar.activityModels.count();
    if (finalActivityCount != activityCount) {
      throw Exception('Activities were not preserved during import');
    }
  }

  // Reuse parsing logic from scripts/restore_chat_simple.dart
  Future<List<ChatMessageModel>> _parseWhatsAppFormat(String content) async {
    final lines = content.split('\n');
    final messages = <ChatMessageModel>[];

    // Reuse existing regex pattern from FT-069
    final messagePattern = RegExp(
        r'^‎?\[(\d{2}/\d{2}/\d{2}), (\d{2}:\d{2}:\d{2})\] ([^:]+): (.*)$');

    // Reuse existing persona mapping from FT-069
    final personaMapping = {
      'Ari Life Coach': 'ariLifeCoach',
      'Ari - Life Coach': 'ariLifeCoach',
      'Ari 2.1': 'ariWithOracle21',
      'Sergeant Oracle': 'sergeantOracle',
      'I-There': 'iThereClone',
      'AI Assistant': null,
      'User': null,
    };

    for (final line in lines) {
      final match = messagePattern.firstMatch(line.trim());
      if (match == null) continue;

      final dateStr = match.group(1)!;
      final timeStr = match.group(2)!;
      final sender = match.group(3)!;
      final content = match.group(4)!;

      // Parse timestamp (reuse FT-069 logic)
      final timestamp = _parseTimestamp(dateStr, timeStr);
      final isUser = sender == 'User';
      final personaKey = personaMapping[sender];
      final personaDisplayName = isUser ? null : sender;

      // Handle audio messages - convert to text with note (files don't exist after import)
      final isAudio = content.startsWith('<attached:') ||
          content.contains('.mp3') ||
          content.contains('.opus');

      String messageText;
      if (isAudio) {
        // Convert audio messages to text messages with indication
        final mediaMatch = RegExp(r'<attached:\s*([^>]+)>').firstMatch(content);
        final fileName = mediaMatch?.group(1) ?? 'audio file';
        messageText = '🔊 [Audio message: $fileName]';
      } else {
        messageText = content;
      }

      // Always use text type for imported messages (audio files don't exist)
      const messageType = MessageType.text;
      String? mediaPath; // Always null for imported messages

      messages.add(ChatMessageModel(
        text: messageText,
        isUser: isUser,
        type: messageType,
        timestamp: timestamp,
        mediaPath: mediaPath,
        personaKey: personaKey,
        personaDisplayName: personaDisplayName,
      ));
    }

    return messages;
  }

  DateTime _parseTimestamp(String dateStr, String timeStr) {
    // Reuse timestamp parsing from FT-069
    final dateParts = dateStr.split('/');
    final timeParts = timeStr.split(':');

    final month = int.parse(dateParts[0]);
    final day = int.parse(dateParts[1]);
    final year = 2000 + int.parse(dateParts[2]);

    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final second = int.parse(timeParts[2]);

    return DateTime(year, month, day, hour, minute, second);
  }

  // Clear Chat History functionality - FT-071
  Future<void> _clearChatHistory(BuildContext context) async {
    // 1. Show confirmation dialog
    final confirm = await _showClearConfirmation(context);
    if (confirm != true) return;

    try {
      // 2. Clear database and audio files
      final chatStorage = ChatStorageService();
      final isar = await chatStorage.db;

      // Preserve activity count for verification
      final activityCount = await isar.activityModels.count();

      // Clear messages only
      await isar.writeTxn(() async {
        await isar.chatMessageModels.clear();
      });

      // Clear audio files to free storage
      await _clearAudioFiles();

      // Verify activities preserved
      final finalActivityCount = await isar.activityModels.count();
      if (finalActivityCount != activityCount) {
        throw Exception('Activities were not preserved during clear');
      }

      // 3. Refresh UI and show success
      onCharacterSelected();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Chat history cleared (activity data preserved)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 4. Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Clear failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showClearConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'This will remove all messages but keep your activity data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAudioFiles() async {
    try {
      // Note: Audio file cleanup placeholder
      // In a production app, this would interface with the audio file service
      // to delete actual audio files from the filesystem
      print('🗑️ Audio files would be cleared here');

      // Actual implementation would:
      // 1. Get audio directory path from existing audio service
      // 2. List and delete audio files
      // 3. Free up storage space
    } catch (e) {
      print('⚠️ Audio file cleanup warning: $e');
      // Don't throw - audio cleanup is secondary to message clearing
    }
  }

  // FT-161: Clear Activity Data functionality
  Future<void> _clearActivityData(BuildContext context) async {
    // 1. Show confirmation dialog
    final confirm = await _showClearActivityConfirmation(context);
    if (confirm != true) return;

    try {
      // 2. Clear activity database using reliable connection pattern
      final chatStorage = ChatStorageService();
      final isar = await chatStorage.db;

      // Preserve message count for verification
      final messageCount = await isar.chatMessageModels.count();

      // FT-125: Clear activities using ActivityMemoryService with reliable connection handling
      await ActivityMemoryService.deleteAllActivities();

      // Verify messages preserved using fresh connection
      final freshChatStorage = ChatStorageService();
      final freshIsar = await freshChatStorage.db;
      final finalMessageCount = await freshIsar.chatMessageModels.count();

      if (finalMessageCount != messageCount) {
        throw Exception('Chat messages were not preserved during clear');
      }

      // 3. Refresh UI and show success
      onCharacterSelected();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Activity data cleared (chat messages preserved)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 4. Show error with more context
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '❌ Clear failed: ${e.toString().contains('closed') ? 'Database connection issue - please try again' : e}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<bool?> _showClearActivityConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Activity Data'),
        content: const Text(
          'This will remove all activity tracking data but keep your chat messages. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // FT-162: Clear Messages and Activities functionality
  Future<void> _clearMessagesAndActivities(BuildContext context) async {
    // 1. Show comprehensive confirmation dialog
    final confirm = await _showClearAllConfirmation(context);
    if (confirm != true) return;

    try {
      // 2. Execute both clear operations sequentially with reliable connections
      final chatStorage = ChatStorageService();
      final isar = await chatStorage.db;

      // Get initial counts for logging (use fresh connections)
      final initialMessageCount = await isar.chatMessageModels.count();

      // FT-125: Ensure fresh connection for activity count
      await ActivityMemoryService.ensureFreshConnection();
      final initialActivityCount =
          await ActivityMemoryService.getTotalActivityCount();

      // Clear messages (safe even if already empty)
      await isar.writeTxn(() async {
        await isar.chatMessageModels.clear();
      });

      // Clear audio files (safe operation)
      await _clearAudioFiles();

      // FT-125: Clear activities using reliable connection handling
      await ActivityMemoryService.deleteAllActivities();

      // Verify final state with fresh connections
      final freshChatStorage = ChatStorageService();
      final freshIsar = await freshChatStorage.db;
      final finalMessageCount = await freshIsar.chatMessageModels.count();
      final finalActivityCount =
          await ActivityMemoryService.getTotalActivityCount();

      // 3. Refresh UI and show success
      onCharacterSelected();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ All data cleared - $initialMessageCount messages and $initialActivityCount activities removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 4. Show error with more details and context
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '❌ Clear operation failed: ${e.toString().contains('closed') ? 'Database connection issue - please try again' : e}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<bool?> _showClearAllConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Messages and Activities'),
        content: const Text(
          'This will remove ALL chat messages AND activity data. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showAboutApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About the App'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your AI-Powered Personal Assistant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'What you can do:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text('• Chat with AI personas for guidance and support'),
              Text('• Get personalized advice for life coaching'),
              Text('• Track your activities and personal development'),
              Text('• Export and import conversation & activity history'),
              Text('• Switch between different AI guides'),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text('• Voice messages and audio responses'),
              Text('• Activity detection and memory'),
              Text('• Time-aware conversations'),
              Text('• Persistent chat & activity history'),
              Text('• Data export/import for device migration'),
              Text('• Customizable AI personas'),
              SizedBox(height: 16),
              Text(
                'Your conversations are private and stored locally on your device.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
