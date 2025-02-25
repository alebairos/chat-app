import 'package:flutter/material.dart';
import '../widgets/chat_message.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_app_bar.dart';
import '../services/claude_service.dart';
import '../services/chat_storage_service.dart';
import '../models/message_type.dart';
import '../models/chat_message_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/transcription_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatStorageService? storageService;
  final ClaudeService? claudeService;

  const ChatScreen({
    this.storageService,
    this.claudeService,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late final ClaudeService _claudeService;
  late final ChatStorageService _storageService;
  bool _isTyping = false;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  DateTime? _lastMessageTimestamp;
  static const int _pageSize = 10000;
  final OpenAITranscriptionService _transcriptionService =
      OpenAITranscriptionService();

  @override
  void initState() {
    super.initState();
    _claudeService = widget.claudeService ?? ClaudeService();
    _storageService = widget.storageService ?? ChatStorageService();
    _checkEnvironment();
    _loadMessages();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoadingMore) {
        _loadMoreMessages();
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      final storedMessages =
          await _storageService.getMessages(limit: _pageSize);
      if (storedMessages.isNotEmpty) {
        _lastMessageTimestamp = storedMessages.last.timestamp;
      }
      setState(() {
        _messages.addAll(storedMessages.map(_createChatMessage));
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading messages: $e';
        _isInitialLoading = false;
      });
      debugPrint('Error loading messages: $e');
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_lastMessageTimestamp == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final olderMessages = await _storageService.getMessages(
        limit: _pageSize,
        before: _lastMessageTimestamp,
      );

      if (olderMessages.isNotEmpty) {
        _lastMessageTimestamp = olderMessages.last.timestamp;
        setState(() {
          _messages.addAll(olderMessages.map(_createChatMessage));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading more messages: $e'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error loading more messages: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _deleteMessage(int id) async {
    try {
      await _storageService.deleteMessage(id);
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.key == ValueKey(id));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showEditDialog(String messageId, String currentText) async {
    print('=== EDIT FLOW START ===');
    print('1. _showEditDialog called with:');
    print('   - Message ID: $messageId');
    print('   - Current text: $currentText');

    print('2. Creating edit dialog with TextField controller');
    final controller = TextEditingController(text: currentText);

    print('3. Building edit dialog');
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          key: const Key('edit-message-field'),
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new message"),
          keyboardType: TextInputType.multiline,
          maxLines: null,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('4a. Cancel button pressed');
              Navigator.pop(context);
              print('4b. Dialog dismissed via cancel');
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newText = controller.text;
              print('5a. Save button pressed');
              print('   - New text: $newText');

              if (newText.trim().isEmpty) {
                print('5b. Empty text detected - not saving');
                return;
              }

              print('5c. Closing dialog before edit');
              Navigator.pop(context);
              print('5d. Calling _editMessage');
              _editMessage(messageId, newText);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editMessage(String id, String newText) async {
    print('\n=== EDIT MESSAGE START ===');
    print('1. _editMessage called with:');
    print('   - Message ID: $id');
    print('   - New text: $newText');

    if (newText.trim().isEmpty) {
      print('2a. Empty text validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('3. Saving edit to storage');
      await _storageService.editMessage(int.parse(id), newText);

      if (!mounted) {
        print('4a. Widget not mounted after storage save');
        return;
      }

      print('4b. Fetching updated message from storage');
      final isar = await _storageService.db;
      final updatedModel = await isar.chatMessageModels.get(int.parse(id));

      if (updatedModel != null) {
        print('5a. Updated message retrieved:');
        print('   - ID: ${updatedModel.id}');
        print('   - Text: ${updatedModel.text}');

        setState(() {
          final index =
              _messages.indexWhere((m) => m.key == ValueKey(int.parse(id)));
          print('5b. Found message at index: $index');

          if (index != -1) {
            _messages[index] = _createChatMessage(updatedModel);
            print('5c. Message updated in UI');
          } else {
            print('5d. ERROR: Message not found in UI list');
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message edited'),
            backgroundColor: Colors.green,
          ),
        );
        print('6. Success snackbar shown');
      } else {
        print('5x. ERROR: Updated message not found in storage');
      }
    } catch (e) {
      print('ERROR in _editMessage:');
      print(e.toString());

      if (!mounted) {
        print('Widget not mounted after error');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error editing message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    print('=== EDIT MESSAGE END ===\n');
  }

  ChatMessage _createChatMessage(ChatMessageModel model) {
    print('\n=== CREATE CHAT MESSAGE ===');
    print('Creating ChatMessage widget:');
    print('- ID: ${model.id}');
    print('- Text: ${model.text}');
    print('- Is user: ${model.isUser}');

    return ChatMessage(
      key: ValueKey(model.id),
      text: model.text,
      isUser: model.isUser,
      audioPath: model.mediaPath,
      duration: model.duration,
      onDelete: () => _deleteMessage(model.id),
      onEdit: model.isUser
          ? (text) {
              print('\n=== EDIT CALLBACK TRIGGERED ===');
              print('Edit callback for message:');
              print('- ID: ${model.id}');
              print('- Current text: $text');
              _showEditDialog(model.id.toString(), text);
            }
          : null,
    );
  }

  void _checkEnvironment() {
    if (dotenv.env['ANTHROPIC_API_KEY']?.isEmpty ?? true) {
      setState(() {
        _error = 'API Key not found. Please check your .env file.';
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;
    final userMessageModel = ChatMessageModel(
      text: userMessage,
      isUser: true,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );

    try {
      // Save user message and get ID
      final isar = await _storageService.db;
      late final int messageId;
      await isar.writeTxn(() async {
        messageId = await isar.chatMessageModels.put(userMessageModel);
      });
      userMessageModel.id = messageId;

      setState(() {
        _messages.insert(0, _createChatMessage(userMessageModel));
        _isTyping = true;
      });
      _messageController.clear();
      _scrollToBottom();

      // Get AI response
      final response = await _claudeService.sendMessage(userMessage);

      // Check if the response is an error message
      final bool isErrorResponse = response.startsWith('Error:') ||
          response.contains('Unable to connect') ||
          response.contains('experiencing high demand') ||
          response.contains('temporarily unavailable') ||
          response.contains('rate limit') ||
          response.contains('Authentication failed');

      if (isErrorResponse) {
        // Display error message to user
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              text: response,
              isUser: false,
            ),
          );
          _isTyping = false;
        });

        // Show error in snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Process normal response
      final aiMessageModel = ChatMessageModel(
        text: response,
        isUser: false,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      // Save AI response and get ID
      await isar.writeTxn(() async {
        final aiMessageId = await isar.chatMessageModels.put(aiMessageModel);
        aiMessageModel.id = aiMessageId;
      });

      setState(() {
        _messages.insert(0, _createChatMessage(aiMessageModel));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            text: 'Error: Unable to send message. Please try again later.',
            isUser: false,
          ),
        );
        _isTyping = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleAudioMessage(String audioPath, Duration duration) async {
    final transcribingMessage = ChatMessage(
      text: 'Transcribing...',
      isUser: true,
      audioPath: audioPath,
      duration: duration,
    );

    setState(() {
      _messages.insert(0, transcribingMessage);
    });
    _scrollToBottom();

    try {
      final transcription =
          await _transcriptionService.transcribeAudio(audioPath);

      // Save audio message first
      await _storageService.saveMessage(
        text: transcription,
        isUser: true,
        type: MessageType.audio,
        mediaPath: audioPath,
        duration: duration,
      );

      // Get the saved message ID from storage
      final messages = await _storageService.getMessages(limit: 1);
      final messageId = messages.first.id;

      // Update UI with transcription
      final userAudioMessage = ChatMessage(
        key: ValueKey(messageId),
        text: transcription,
        isUser: true,
        audioPath: audioPath,
        duration: duration,
        onDelete: () => _deleteMessage(messageId),
        onEdit: (text) => _showEditDialog(messageId.toString(), text),
      );

      setState(() {
        _messages[0] = userAudioMessage;
      });
      _scrollToBottom();

      // Send transcription to Claude
      final response = await _claudeService.sendMessage(transcription);

      // Check if the response is an error message
      final bool isErrorResponse = response.startsWith('Error:') ||
          response.contains('Unable to connect') ||
          response.contains('experiencing high demand') ||
          response.contains('temporarily unavailable') ||
          response.contains('rate limit') ||
          response.contains('Authentication failed');

      if (isErrorResponse) {
        // Display error message to user
        final aiMessage = ChatMessage(
          text: response,
          isUser: false,
        );

        setState(() {
          _messages.insert(0, aiMessage);
        });

        // Show error in snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Save AI response
      await _storageService.saveMessage(
        text: response,
        isUser: false,
        type: MessageType.text,
      );

      // Get the saved AI message ID
      final aiMessages = await _storageService.getMessages(limit: 1);
      final aiMessageId = aiMessages.first.id;

      final aiMessage = ChatMessage(
        key: ValueKey(aiMessageId),
        text: response,
        isUser: false,
        onDelete: () => _deleteMessage(aiMessageId),
      );

      setState(() {
        _messages.insert(0, aiMessage);
      });
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing audio message: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error processing audio message: $e');

      // Update the transcribing message to show the error
      setState(() {
        _messages[0] = ChatMessage(
          text:
              'Error: Unable to process audio message. Please try again later.',
          isUser: false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: const CustomChatAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_isInitialLoading) {
      return Scaffold(
        appBar: const CustomChatAppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomChatAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet.\nStart a conversation!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _messages[index];
                    },
                  ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.military_tech, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Text('Claude is typing...'),
                ],
              ),
            ),
          ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
            onSendAudio: _handleAudioMessage,
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: const Text(
              'This is A.I. and not a real person. Treat everything it says as fiction',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _storageService.close();
    super.dispose();
  }
}
