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
import '../config/character_config_manager.dart';
import '../features/audio_assistant/tts_service.dart';
import '../models/claude_audio_response.dart';
import '../features/audio_assistant/widgets/assistant_audio_message.dart';

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
  late final AudioAssistantTTSService _ttsService;
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
    _ttsService = AudioAssistantTTSService();
    _claudeService = widget.claudeService ??
        ClaudeService(ttsService: _ttsService, audioEnabled: true);
    _storageService = widget.storageService ?? ChatStorageService();
    _currentPersona = _configLoader.activePersonaDisplayName;
    _checkEnvironment();
    _initializeServices();
    _setupScrollListener();
  }

  Future<void> _initializeServices() async {
    try {
      await _claudeService.initialize();
      await _ttsService.initialize();

      // Ensure audio is enabled in Claude service
      if (_claudeService is ClaudeService && !widget.testMode) {
        (_claudeService as ClaudeService).audioEnabled = true;
      }

      // Migrate any existing absolute paths to relative paths
      await _storageService.migratePathsToRelative();

      // Then load messages
      await _loadMessages();
    } catch (e) {
      setState(() {
        _error = 'Error initializing services: $e';
        _isInitialLoading = false;
      });
      _logger.error('Error initializing services: $e');
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

  /// Get the appropriate color for the current persona
  Color _getPersonaColor() {
    switch (_configLoader.activePersona) {
      case CharacterPersona.ariLifeCoach:
        return Colors.teal;
      case CharacterPersona.sergeantOracle:
        return Colors.deepPurple;
      case CharacterPersona.zenGuide:
        return Colors.green;
      case CharacterPersona.personalDevelopmentAssistant:
        return Colors.blue;
    }
  }

  /// Get the appropriate icon for the current persona
  IconData _getPersonaIcon() {
    switch (_configLoader.activePersona) {
      case CharacterPersona.ariLifeCoach:
        return Icons.psychology;
      case CharacterPersona.sergeantOracle:
        return Icons.military_tech;
      case CharacterPersona.zenGuide:
        return Icons.self_improvement;
      case CharacterPersona.personalDevelopmentAssistant:
        return Icons.person;
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

      // Get AI response with audio
      final response = await _claudeService.sendMessageWithAudio(userMessage);

      // Check if the response contains an error message
      final bool isErrorResponse = response.text.startsWith('Error:') ||
          response.text.contains('Unable to connect') ||
          response.text.contains('experiencing high demand') ||
          response.text.contains('temporarily unavailable') ||
          response.text.contains('rate limit') ||
          response.text.contains('Authentication failed');

      if (isErrorResponse) {
        // Display error message to user
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              text: response.text,
              isUser: false,
            ),
          );
          _isTyping = false;
        });

        // Show error in snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.text),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Process normal response
      final messageType =
          response.audioPath != null ? MessageType.audio : MessageType.text;

      final aiMessageModel = ChatMessageModel(
        text: response.text,
        isUser: false,
        type: messageType,
        timestamp: DateTime.now(),
        mediaPath: response.audioPath,
        duration: response.audioDuration,
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
          const ChatMessage(
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

      // Send transcription to Claude WITH AUDIO
      final response = await _claudeService.sendMessageWithAudio(transcription);

      // Check if the response contains an error message
      final bool isErrorResponse = response.text.startsWith('Error:') ||
          response.text.contains('Unable to connect') ||
          response.text.contains('experiencing high demand') ||
          response.text.contains('temporarily unavailable') ||
          response.text.contains('rate limit') ||
          response.text.contains('Authentication failed');

      if (isErrorResponse) {
        // Display error message to user
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              text: response.text,
              isUser: false,
            ),
          );
        });

        // Show error in snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.text),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Process normal response
      final messageType =
          response.audioPath != null ? MessageType.audio : MessageType.text;

      final aiMessageModel = ChatMessageModel(
        text: response.text,
        isUser: false,
        type: messageType,
        timestamp: DateTime.now(),
        mediaPath: response.audioPath,
        duration: response.audioDuration,
      );

      // Save AI response and get ID
      final isar = await _storageService.db;
      await isar.writeTxn(() async {
        final aiMessageId = await isar.chatMessageModels.put(aiMessageModel);
        aiMessageModel.id = aiMessageId;
      });

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

      // Update the transcribing message to show the error
      setState(() {
        _messages[0] = const ChatMessage(
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
      return const Scaffold(
        appBar: CustomChatAppBar(),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomChatAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Dismiss keyboard when tapping on chat area
                  FocusScope.of(context).unfocus();
                },
                behavior: HitTestBehavior.translucent,
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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return _messages[index];
                        },
                      ),
              ),
            ),
            if (_isTyping)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getPersonaColor(),
                      child: Icon(_getPersonaIcon(), color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                        '${_configLoader.activePersonaDisplayName} is typing...'),
                  ],
                ),
              ),
            ChatInput(
              controller: _messageController,
              onSend: _sendMessage,
              onSendAudio: _handleAudioMessage,
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              color: Colors.grey[100],
              child: const Text(
                'This is A.I. and not a real person. Treat everything it says as fiction',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
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
