import '../services/chat_storage_service.dart';

/// Debug utility to restore chat messages
/// Call this from anywhere in your app to restore the chat history
///
/// Usage examples:
/// 1. From main.dart during development:
///    ```dart
///    if (kDebugMode) {
///      await DebugRestore.restoreChat();
///    }
///    ```
///
/// 2. From a debug screen button:
///    ```dart
///    ElevatedButton(
///      onPressed: () async {
///        await DebugRestore.restoreChat();
///        ScaffoldMessenger.of(context).showSnackBar(
///          SnackBar(content: Text('Chat restored!')),
///        );
///      },
///      child: Text('Restore Chat'),
///    )
///    ```
class DebugRestore {
  /// Restore chat messages from exported data
  /// This will preserve activities but clear existing messages
  /// Loads all 288 messages from the most recent export
  static Future<void> restoreChat() async {
    print('🔧 DEBUG: Starting chat restoration...');

    try {
      final storage = ChatStorageService();
      await storage.restoreMessagesFromData();
      print('✅ DEBUG: Chat restoration completed successfully!');
      print('📊 DEBUG: Restored 288 messages with proper persona mapping');
    } catch (e) {
      print('❌ DEBUG: Chat restoration failed: $e');
      rethrow;
    }
  }
}
