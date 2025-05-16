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
import '../utils/logger.dart';
import '../config/config_loader.dart';

class ChatScreen extends StatefulWidget {
  final ChatStorageService? storageService;
  final ClaudeService? claudeService;
  final bool testMode;

  const ChatScreen({
    this.storageService,
    this.claudeService,
    this.testMode = false,
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
  final Logger _logger = Logger();
  final ConfigLoader _configLoader = ConfigLoader();
  late String _currentPersona;

  @override
  void initState() {
    super.initState();
    _claudeService = widget.claudeService ?? ClaudeService();
    _storageService = widget.storageService ?? ChatStorageService();
    _currentPersona = _configLoader.activePersonaDisplayName;
    _checkEnvironment();
    _initializeStorage();
    _setupScrollListener();
  }

  Future<void> _initializeStorage() async {
    try {
      // Migrate any existing absolute paths to relative paths
      await _storageService.migratePathsToRelative();

      // Then load messages
      await _loadMessages();
    } catch (e) {
      setState(() {
        _error = 'Error initializing storage: $e';
        _isInitialLoading = false;
      });
      _logger.error('Error initializing storage: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if the character has changed
    if (_currentPersona != _configLoader.activePersonaDisplayName) {
      _currentPersona = _configLoader.activePersonaDisplayName;
      _resetChat();
    }
  }

  void _resetChat() {
    setState(() {
      _messages.clear();
      _isInitialLoading = true;
      _error = null;
    });
    _loadMessages();
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
      _logger.error('Error loading messages: $e');
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
    _logger.debug('=== EDIT FLOW START ===');
    _logger.debug('1. _showEditDialog called with:');
    _logger.debug('   - Message ID: $messageId');
    _logger.debug('   - Current text: $currentText');

    _logger.debug('2. Creating edit dialog with TextField controller');
    final controller = TextEditingController(text: currentText);

    _logger.debug('3. Building edit dialog');
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
              _logger.debug('4a. Cancel button pressed');
              Navigator.pop(context);
              _logger.debug('4b. Dialog dismissed via cancel');
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newText = controller.text;
              _logger.debug('5a. Save button pressed');
              _logger.debug('   - New text: $newText');

              if (newText.trim().isEmpty) {
                _logger.debug('5b. Empty text detected - not saving');
                return;
              }

              _logger.debug('5c. Closing dialog before edit');
              Navigator.pop(context);
              _logger.debug('5d. Calling _editMessage');
              _editMessage(messageId, newText);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editMessage(String id, String newText) async {
    _logger.debug('=== EDIT MESSAGE START ===');
    _logger.debug('1. _editMessage called with:');
    _logger.debug('   - Message ID: $id');
    _logger.debug('   - New text: $newText');

    if (newText.trim().isEmpty) {
      _logger.debug('2a. Empty text validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      _logger.debug('3. Saving edit to storage');
      await _storageService.editMessage(int.parse(id), newText);

      if (!mounted) {
        _logger.debug('4a. Widget not mounted after storage save');
        return;
      }

      _logger.debug('4b. Fetching updated message from storage');
      final isar = await _storageService.db;
      final updatedModel = await isar.chatMessageModels.get(int.parse(id));

      if (updatedModel != null) {
        _logger.debug('5a. Updated message retrieved:');
        _logger.debug('   - ID: ${updatedModel.id}');
        _logger.debug('   - Text: ${updatedModel.text}');

        setState(() {
          final index =
              _messages.indexWhere((m) => m.key == ValueKey(int.parse(id)));
          _logger.debug('5b. Found message at index: $index');

          if (index != -1) {
            _messages[index] = _createChatMessage(updatedModel);
            _logger.debug('5c. Message updated in UI');
          } else {
            _logger.debug('5d. ERROR: Message not found in UI list');
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message edited'),
            backgroundColor: Colors.green,
          ),
        );
        _logger.debug('6. Success snackbar shown');
      } else {
        _logger.debug('5x. ERROR: Updated message not found in storage');
      }
    } catch (e) {
      _logger.error('ERROR in _editMessage: ${e.toString()}');

      if (!mounted) {
        _logger.debug('Widget not mounted after error');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error editing message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _logger.debug('=== EDIT MESSAGE END ===');
  }

  ChatMessage _createChatMessage(ChatMessageModel model) {
    // Only log if startup logging is enabled
    if (_logger.isStartupLoggingEnabled()) {
      _logger.logStartup('Creating ChatMessage widget:');
      _logger.logStartup('- ID: ${model.id}');
      _logger.logStartup('- Text: ${model.text}');
      _logger.logStartup('- Is user: ${model.isUser}');
    }

    return ChatMessage(
      key: ValueKey(model.id),
      text: model.text,
      isUser: model.isUser,
      audioPath: model.mediaPath,
      duration: model.duration,
      onDelete: () => _deleteMessage(model.id),
      onEdit: model.isUser
          ? (text) {
              _logger.debug('Edit callback for message:');
              _logger.debug('- ID: ${model.id}');
              _logger.debug('- Current text: $text');
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
    print("TEST DEBUG: User message: $userMessage");

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
        print("TEST DEBUG: User message saved with ID: $messageId");
      });
      userMessageModel.id = messageId;

      setState(() {
        _messages.insert(0, _createChatMessage(userMessageModel));
        _isTyping = true;
        print(
            "TEST DEBUG: User message added to UI. Messages count: ${_messages.length}");
      });
      _messageController.clear();
      _scrollToBottom();

      // In test mode, add the AI response immediately without async delays
      if (widget.testMode) {
        print(
            "TEST DEBUG: Test mode active, getting AI response synchronously");
        // Get AI response synchronously in test mode
        String response;
        try {
          response = await _claudeService.sendMessage(userMessage);
          print("TEST DEBUG: AI response in test mode: $response");
        } catch (e) {
          response = "Error: Test mode exception: $e";
          print("TEST DEBUG: AI response error in test mode: $response");
        }

        // Process response immediately in test mode
        final bool isErrorResponse = response.startsWith('Error:') ||
            response.contains('Unable to connect') ||
            response.contains('experiencing high demand') ||
            response.contains('temporarily unavailable') ||
            response.contains('rate limit') ||
            response.contains('Authentication failed');

        final aiMessageModel = ChatMessageModel(
          text: response,
          isUser: false,
          type: MessageType.text,
          timestamp: DateTime.now(),
        );

        // Save to storage
        await isar.writeTxn(() async {
          final aiMessageId = await isar.chatMessageModels.put(aiMessageModel);
          aiMessageModel.id = aiMessageId;
          print("TEST DEBUG: AI message saved with ID: $aiMessageId");
        });

        // Update UI
        setState(() {
          _messages.insert(0, _createChatMessage(aiMessageModel));
          _isTyping = false;
          print(
              "TEST DEBUG: AI message added to UI in test mode. Messages count: ${_messages.length}");
        });
        return;
      }

      // Regular flow for non-test mode
      // Get AI response
      final response = await _claudeService.sendMessage(userMessage);
      print("TEST DEBUG: AI response: $response");

      // Check if the response is an error message
      final bool isErrorResponse = response.startsWith('Error:') ||
          response.contains('Unable to connect') ||
          response.contains('experiencing high demand') ||
          response.contains('temporarily unavailable') ||
          response.contains('rate limit') ||
          response.contains('Authentication failed');

      if (isErrorResponse) {
        print("TEST DEBUG: Error response detected");
        // Create a model for the error message
        final errorMessageModel = ChatMessageModel(
          text: response, // The error string from Claude
          isUser: false,
          type: MessageType.text, // Using MessageType.text for errors
          timestamp: DateTime.now(),
        );

        // Save error message to storage and get ID
        await isar.writeTxn(() async {
          final errorMessageId =
              await isar.chatMessageModels.put(errorMessageModel);
          errorMessageModel.id = errorMessageId;
          print("TEST DEBUG: Error message saved with ID: $errorMessageId");
        });

        // Display error message to user using the standard method
        setState(() {
          _messages.insert(0, _createChatMessage(errorMessageModel));
          _isTyping = false;
          print(
              "TEST DEBUG: Error message added to UI. Messages count: ${_messages.length}");
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
      print("TEST DEBUG: Normal response processing");
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
        print("TEST DEBUG: AI message saved with ID: $aiMessageId");
      });

      setState(() {
        _messages.insert(0, _createChatMessage(aiMessageModel));
        _isTyping = false;
        print(
            "TEST DEBUG: AI message added to UI. Messages count: ${_messages.length}");
      });
      _scrollToBottom();
    } catch (e) {
      // Create a model for the generic error message
      final genericErrorMessageModel = ChatMessageModel(
        text: 'Error: Unable to send message. Please try again later.',
        isUser: false,
        type: MessageType.text, // Using MessageType.text for errors
        timestamp: DateTime.now(),
      );

      // Save generic error message to storage and get ID
      // This requires access to _storageService and its db, which might be an issue if storage itself failed.
      // However, for testing with mocks, this path should be controllable.
      try {
        final isarInstance = await _storageService
            .db; // Renamed to avoid conflict with isar in outer scope if any
        await isarInstance.writeTxn(() async {
          final genericErrorMessageId = await isarInstance.chatMessageModels
              .put(genericErrorMessageModel);
          genericErrorMessageModel.id = genericErrorMessageId;
        });

        // Display generic error message to user using the standard method
        setState(() {
          _messages.insert(0, _createChatMessage(genericErrorMessageModel));
          _isTyping = false;
        });
      } catch (storageError) {
        // If saving the generic error itself fails, fallback to a non-persistent display or log heavily
        // For now, just ensure _isTyping is reset and perhaps log, but don't try to save again.
        _logger.error(
            'CRITICAL: Failed to save generic error message to storage: $storageError. Original error: $e');
        setState(() {
          // Fallback: Add a non-persistent ChatMessage if _createChatMessage fails due to no ID.
          // Or, ideally, _createChatMessage should handle a null ID gracefully for display-only errors.
          // For now, we stick to the pattern. If ID is not set, ValueKey will be ValueKey(null).
          _messages.insert(
            0,
            const ChatMessage(
              // Fallback if saving generic error fails
              text:
                  'Error: Unable to send message. Please try again later. (Display only)',
              isUser: false,
            ),
          );
          _isTyping = false;
        });
      }

      if (mounted) {
        // Ensure mounted check for ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        // Create a model for the error message
        final errorMessageModel = ChatMessageModel(
          text: response,
          isUser: false,
          type: MessageType.text,
          timestamp: DateTime.now(),
        );

        // Save error message to storage and get ID
        final isar = await _storageService.db;
        await isar.writeTxn(() async {
          final errorMessageId =
              await isar.chatMessageModels.put(errorMessageModel);
          errorMessageModel.id = errorMessageId;
        });

        // Display error message using _createChatMessage
        setState(() {
          _messages.insert(0, _createChatMessage(errorMessageModel));
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

      // Save AI response using ChatMessageModel
      final aiMessageModel = ChatMessageModel(
        text: response,
        isUser: false,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      // Save to storage and get ID
      final isar = await _storageService.db;
      await isar.writeTxn(() async {
        final aiMessageId = await isar.chatMessageModels.put(aiMessageModel);
        aiMessageModel.id = aiMessageId;
      });

      // Add to UI using _createChatMessage
      setState(() {
        _messages.insert(0, _createChatMessage(aiMessageModel));
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

      // Create error model for the error message
      final errorModel = ChatMessageModel(
        text: 'Error: Unable to process audio message. Please try again later.',
        isUser: false,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      try {
        // Save error to storage
        final isar = await _storageService.db;
        await isar.writeTxn(() async {
          final errorId = await isar.chatMessageModels.put(errorModel);
          errorModel.id = errorId;
        });

        // Update UI with _createChatMessage
        setState(() {
          _messages[0] = _createChatMessage(errorModel);
        });
      } catch (storageError) {
        // Fallback if storage fails
        setState(() {
          _messages[0] = const ChatMessage(
            text:
                'Error: Unable to process audio message. Please try again later.',
            isUser: false,
          );
        });
      }
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
      return const Scaffold(
        appBar: CustomChatAppBar(),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
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

  // Expose messages for testing
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  // Method to get message count for testing
  int get messageCount => _messages.length;

  // Method to get message text at index for testing
  String? getMessageTextAt(int index) {
    if (index >= 0 && index < _messages.length) {
      return _messages[index].text;
    }
    return null;
  }
}
