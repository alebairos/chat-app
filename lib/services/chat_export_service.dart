import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/chat_message_model.dart';
import '../models/message_type.dart';
import '../utils/logger.dart';
import 'chat_storage_service.dart';

/// Service responsible for exporting chat history in WhatsApp-compatible format
class ChatExportService {
  final ChatStorageService _storageService;
  final Logger _logger = Logger();

  ChatExportService({ChatStorageService? storageService})
      : _storageService = storageService ?? ChatStorageService();

  /// Export complete chat history to WhatsApp-compatible format
  ///
  /// Returns the path to the generated file for testing purposes,
  /// or null if the operation was cancelled by the user
  Future<String?> exportChatHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.info('Starting chat export...');

      // Get all messages in chronological order (oldest first)
      final messages = await _getAllMessagesChronological(
        startDate: startDate,
        endDate: endDate,
      );

      if (messages.isEmpty) {
        _logger.info('No messages found for export');
        throw Exception('No chat history to export');
      }

      _logger.info('Found ${messages.length} messages to export');

      // Generate export content
      final exportContent = _generateWhatsAppFormat(messages);

      // Create export file
      final filePath = await _createExportFile(exportContent);

      _logger.info('Export file created at: $filePath');

      // Share the file using platform's native sharing
      await _shareExportFile(filePath);

      return filePath;
    } catch (e) {
      _logger.error('Error during chat export: $e');
      rethrow;
    }
  }

  /// Create export file without sharing (for UI control over sharing)
  Future<String> createExportFile({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.info('Starting chat export file creation...');

      // Get all messages in chronological order (oldest first)
      final messages = await _getAllMessagesChronological(
        startDate: startDate,
        endDate: endDate,
      );

      if (messages.isEmpty) {
        _logger.info('No messages found for export');
        throw Exception('No chat history to export');
      }

      _logger.info('Found ${messages.length} messages to export');

      // Generate export content
      final exportContent = _generateWhatsAppFormat(messages);

      // Create export file
      final filePath = await _createExportFile(exportContent);

      _logger.info('Export file created at: $filePath');

      return filePath;
    } catch (e) {
      _logger.error('Error during chat export file creation: $e');
      rethrow;
    }
  }

  /// Share an existing export file
  Future<void> shareExportFile(String filePath) async {
    await _shareExportFile(filePath);
  }

  /// Get all messages in chronological order (oldest first)
  /// Fixed pagination logic to ensure ALL messages are retrieved
  Future<List<ChatMessageModel>> _getAllMessagesChronological({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final List<ChatMessageModel> allMessages = [];
    DateTime? afterTimestamp;
    const int batchSize = 1000; // Process in batches for memory efficiency

    _logger.info('Starting forward pagination to retrieve all messages...');

    // Use forward pagination to ensure we get ALL messages
    while (true) {
      final batch = await _storageService.getMessagesAfter(
        after: afterTimestamp,
        limit: batchSize,
      );

      if (batch.isEmpty) break;

      _logger.debug('Retrieved batch of ${batch.length} messages');

      // Filter by date range if specified
      final filteredBatch = batch.where((message) {
        if (startDate != null && message.timestamp.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && message.timestamp.isAfter(endDate)) {
          return false;
        }
        return true;
      }).toList();

      allMessages.addAll(filteredBatch);

      // Update timestamp for next batch (get messages after the last one in this batch)
      afterTimestamp = batch.last.timestamp;

      // If we got fewer messages than requested, we've reached the end
      if (batch.length < batchSize) break;
    }

    _logger.info(
        'Forward pagination complete. Retrieved ${allMessages.length} messages total');

    // Messages are already in chronological order from the database query
    return allMessages;
  }

  /// Generate WhatsApp-compatible format from messages
  String _generateWhatsAppFormat(List<ChatMessageModel> messages) {
    final buffer = StringBuffer();

    for (final message in messages) {
      final formattedMessage = _formatMessage(message);
      buffer.writeln(formattedMessage);
    }

    return buffer.toString();
  }

  /// Format a single message in WhatsApp format
  String _formatMessage(ChatMessageModel message) {
    final timestamp = _formatTimestamp(message.timestamp);
    final senderName = _getSenderName(message);

    if (message.type == MessageType.text) {
      return '[$timestamp] $senderName: ${message.text}';
    } else {
      // For audio/media messages, check if there's text content
      if (message.text.isNotEmpty && message.text != 'Transcribing...') {
        // Show both text content and audio attachment
        final attachmentText = _formatMediaAttachment(message);
        return '[$timestamp] $senderName: ${message.text}\n‎[$timestamp] $senderName: ‎$attachmentText';
      } else {
        // Show only attachment format for pure audio messages
        final attachmentText = _formatMediaAttachment(message);
        return '‎[$timestamp] $senderName: ‎$attachmentText';
      }
    }
  }

  /// Format timestamp in WhatsApp format: [MM/DD/YY, HH:MM:SS]
  String _formatTimestamp(DateTime timestamp) {
    final formatter = DateFormat('MM/dd/yy, HH:mm:ss');
    return formatter.format(timestamp);
  }

  /// Get sender name with persona fallback logic
  String _getSenderName(ChatMessageModel message) {
    if (message.isUser) {
      return 'User';
    }

    // For AI messages, use persona information with fallbacks
    if (message.personaDisplayName != null &&
        message.personaDisplayName!.isNotEmpty &&
        message.personaDisplayName != 'unknown') {
      return message.personaDisplayName!;
    }

    // Fallback for legacy messages or unknown personas
    return 'AI Assistant';
  }

  /// Format media attachment in WhatsApp style
  String _formatMediaAttachment(ChatMessageModel message) {
    String filename;

    switch (message.type) {
      case MessageType.audio:
        // Extract filename from path or create generic one
        if (message.mediaPath != null) {
          final pathParts = message.mediaPath!.split('/');
          filename = pathParts.last;
          // Ensure it has an audio extension
          if (!filename.contains('.')) {
            filename += '.opus';
          }
        } else {
          filename = 'audio_${message.timestamp.millisecondsSinceEpoch}.opus';
        }
        break;
      case MessageType.image:
        filename = 'image_${message.timestamp.millisecondsSinceEpoch}.jpg';
        break;
      default:
        filename = 'file_${message.timestamp.millisecondsSinceEpoch}.dat';
    }

    return '<attached: $filename>';
  }

  /// Create the export file in temporary directory
  Future<String> _createExportFile(String content) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final filename = 'chat_export_$timestamp.txt';
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
      text: 'Chat Export - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
      subject: 'Chat Export',
    );
  }

  /// Get export statistics for display purposes
  Future<Map<String, dynamic>> getExportStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final messages = await _getAllMessagesChronological(
        startDate: startDate,
        endDate: endDate,
      );

      final userMessages = messages.where((m) => m.isUser).length;
      final aiMessages = messages.where((m) => !m.isUser).length;
      final audioMessages =
          messages.where((m) => m.type == MessageType.audio).length;

      // Count messages by persona
      final personaCounts = <String, int>{};
      for (final message in messages.where((m) => !m.isUser)) {
        final persona = _getSenderName(message);
        personaCounts[persona] = (personaCounts[persona] ?? 0) + 1;
      }

      final dateRange = messages.isNotEmpty
          ? {
              'earliest': messages.first.timestamp,
              'latest': messages.last.timestamp,
            }
          : null;

      return {
        'totalMessages': messages.length,
        'userMessages': userMessages,
        'aiMessages': aiMessages,
        'audioMessages': audioMessages,
        'personaCounts': personaCounts,
        'dateRange': dateRange,
      };
    } catch (e) {
      _logger.error('Error getting export statistics: $e');
      return {
        'totalMessages': 0,
        'userMessages': 0,
        'aiMessages': 0,
        'audioMessages': 0,
        'personaCounts': <String, int>{},
        'dateRange': null,
      };
    }
  }
}
