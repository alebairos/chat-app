import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../services/chat_storage_service.dart';
import '../../models/chat_message_model.dart';
import '../../models/activity_model.dart';
import '../../models/message_type.dart';
import '../../widgets/chat_app_bar.dart';

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
      final messageType = MessageType.text;
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
              Text('• Export and import your conversation history'),
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
              Text('• Persistent chat history'),
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
