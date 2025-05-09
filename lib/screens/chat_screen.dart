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
import 'package:character_ai_clone/features/audio_assistant/services/audio_message_provider.dart';
import 'package:character_ai_clone/features/audio_assistant/services/text_to_speech_service.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback_controller.dart';
import 'package:character_ai_clone/features/audio_assistant/services/tts_service_factory.dart';
import 'package:character_ai_clone/features/audio_assistant/services/eleven_labs_tts_service.dart';
import 'dart:io';
import 'package:character_ai_clone/features/audio_assistant/screens/tts_settings_screen.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:math' as math;

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
  final Logger _logger = Logger();
  final ConfigLoader _configLoader = ConfigLoader();
  late String _currentPersona;

  // Audio assistant services
  late TextToSpeechService _ttsService;
  late AudioPlaybackController _audioPlaybackController;
  late AudioMessageProvider _audioMessageProvider;
  bool _audioAssistantInitialized = false;

  @override
  void initState() {
    super.initState();
    _claudeService = widget.claudeService ?? ClaudeService();
    _storageService = widget.storageService ?? ChatStorageService();
    _currentPersona = _configLoader.activePersonaDisplayName;
    _checkEnvironment();
    _loadMessages();
    _setupScrollListener();

    // Initialize audio assistant services
    _initializeAudioAssistant();
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

    // Check if this is an audio message from the assistant
    if (model.type == MessageType.audio &&
        !model.isUser &&
        model.mediaPath != null) {
      // Verify the audio file exists
      final file = File(model.mediaPath!);
      if (!file.existsSync()) {
        debugPrint(
            'Audio file not found when creating message: ${model.mediaPath}');
      } else {
        debugPrint(
            'Audio file exists when creating message: ${model.mediaPath}');
      }
    }

    // We no longer need to pass the AudioPlaybackController directly
    // The ChatMessage widget will use the AudioPlaybackManager singleton
    return ChatMessage(
      key: ValueKey(model.id),
      text: model.text,
      isUser: model.isUser,
      audioPath: model.mediaPath,
      duration: model.duration,
      // We still pass the controller for backward compatibility, but it's not used directly
      audioPlayback: (!model.isUser &&
              model.type == MessageType.audio &&
              model.mediaPath != null)
          ? _audioPlaybackController
          : null,
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

  Future<void> _initializeAudioAssistant() async {
    // Use the singleton AudioPlaybackManager
    final playbackManager = AudioPlaybackManager();
    _audioPlaybackController =
        playbackManager.audioPlayback as AudioPlaybackController;

    // Set ElevenLabs as the active TTS service
    TTSServiceFactory.setActiveServiceType(TTSServiceType.elevenLabs);

    _audioMessageProvider = AudioMessageProvider(
      audioGeneration: TTSServiceFactory.createTTSService(),
      audioPlayback: _audioPlaybackController,
    );

    final initialized = await _audioMessageProvider.initialize();

    // Explicitly disable test mode for ElevenLabs service
    if (initialized &&
        TTSServiceFactory.activeServiceType == TTSServiceType.elevenLabs) {
      final audioGenService = _audioMessageProvider.getAudioGenerationService();
      if (audioGenService is ElevenLabsTTSService) {
        audioGenService.disableTestMode();
        debugPrint('Explicitly disabled test mode for ElevenLabs service');
      }
    }

    setState(() {
      _audioAssistantInitialized = initialized;
    });

    if (!initialized) {
      debugPrint('Failed to initialize audio assistant');
    } else {
      debugPrint(
          'Audio assistant initialized with service type: ${TTSServiceFactory.activeServiceType}');
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

      // Generate audio for assistant response if audio assistant is initialized
      String? audioPath;
      Duration? audioDuration;

      if (_audioAssistantInitialized) {
        try {
          // Save assistant message to storage first to get the message ID
          await _storageService.saveMessage(
            text: response,
            isUser: false,
            type: MessageType.text, // Initially save as text, will update later
          );

          // Get the saved message ID from storage
          final messages = await _storageService.getMessages(limit: 1);
          final savedMessageId = messages.first.id;

          // Use the actual message ID for the audio file
          // Add a timestamp to ensure uniqueness
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final audioMessageId = "${savedMessageId}_$timestamp";
          debugPrint(
              'Generating audio for message ID: $audioMessageId with unique timestamp');

          final audioFile = await _audioMessageProvider.generateAudioForMessage(
            audioMessageId,
            response,
          );

          if (audioFile != null) {
            audioPath = audioFile.path;
            audioDuration = audioFile.duration;
            debugPrint(
                'Generated audio file for message $audioMessageId: $audioPath with duration: $audioDuration');

            // Update the message in storage with the audio path and duration
            await _storageService.updateMessage(
              savedMessageId,
              type: MessageType.audio,
              mediaPath: audioPath,
              duration: audioDuration,
            );
          } else {
            debugPrint(
                'Audio file generation returned null for message $audioMessageId');
          }
        } catch (e) {
          debugPrint('Error generating audio for assistant response: $e');
        }
      } else {
        debugPrint(
            'Audio assistant not initialized, skipping audio generation');

        // Save assistant message to storage without audio
        await _storageService.saveMessage(
          text: response,
          isUser: false,
          type: MessageType.text,
        );
      }

      // Get the saved message ID from storage
      final messages = await _storageService.getMessages(limit: 1);
      final savedMessageId = messages.first.id;
      debugPrint(
          'Retrieved saved message ID: $savedMessageId, audioPath: $audioPath');

      // Add assistant message to UI
      final assistantMessage = ChatMessage(
        key: ValueKey(savedMessageId),
        text: response,
        isUser: false,
        audioPath: audioPath,
        duration: audioDuration,
        audioPlayback: audioPath != null ? _audioPlaybackController : null,
        onDelete: () => _deleteMessage(savedMessageId),
      );

      setState(() {
        _messages.insert(0, assistantMessage);
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

  Future<void> _handleAudioMessage(String audioPath, Duration duration) async {
    _logger.debug('=== HANDLE AUDIO MESSAGE START ===');
    _logger.debug('1. Received audio: path=$audioPath, duration=$duration');

    // Show transcribing message immediately with absolute path
    final tempTranscribingId =
        'transcribing_${DateTime.now().millisecondsSinceEpoch}';
    final transcribingMessage = ChatMessage(
      key: ValueKey(tempTranscribingId),
      text: 'Transcribing...',
      isUser: true,
      audioPath: audioPath, // Absolute path for immediate UI
      duration: duration,
    );

    setState(() {
      _messages.insert(0, transcribingMessage);
    });
    _scrollToBottom();
    _logger.debug('2. Added temporary "Transcribing..." message to UI.');

    try {
      _logger.debug('3. Starting transcription for: $audioPath');
      final transcription =
          await _transcriptionService.transcribeAudio(audioPath);
      _logger.debug('4. Transcription result: "$transcription"');

      // Get relative path for storage
      final Directory documentsDir = await getApplicationDocumentsDirectory();
      final String relativePath =
          path.relative(audioPath, from: documentsDir.path);
      _logger.debug('5. Calculated relative path for storage: $relativePath');

      // Save audio message with RELATIVE path
      await _storageService.saveMessage(
        text: transcription,
        isUser: true,
        type: MessageType.audio,
        mediaPath: relativePath, // <-- Save relative path
        duration: duration,
      );
      _logger.debug(
          '6. Saved transcribed message with relative audio path to storage.');

      // Get the saved message ID from storage
      final messages = await _storageService.getMessages(limit: 1);
      final messageId = messages.first.id;
      _logger.debug('7. Retrieved saved message ID: $messageId');

      // Update UI with final message, still passing ABSOLUTE path for the widget
      final userAudioMessage = ChatMessage(
        key: ValueKey(messageId),
        text: transcription,
        isUser: true,
        audioPath:
            audioPath, // <-- Pass absolute path to widget for immediate use
        duration: duration,
        onDelete: () => _deleteMessage(messageId),
        onEdit: (text) => _showEditDialog(messageId.toString(), text),
      );

      final transcribingIndex = _messages
          .indexWhere((msg) => msg.key == ValueKey(tempTranscribingId));
      if (transcribingIndex != -1) {
        setState(() {
          _messages[transcribingIndex] = userAudioMessage;
        });
        _logger.debug(
            '8. Replaced temporary "Transcribing..." message with final audio message in UI.');
      } else {
        _logger.debug(
            'Temporary transcribing message not found for replacement. Adding new message.');
        setState(() {
          _messages.insert(0, userAudioMessage);
        });
      }
      _scrollToBottom();

      _logger.debug('9. Sending transcription to Claude service.');
      final response = await _claudeService.sendMessage(transcription);
      _logger.debug('10. Received response from Claude. Processing...');
      await _processAssistantResponse(response);
    } catch (e) {
      _logger.error('Error processing audio message: ${e.toString()}');
      if (mounted) {
        final transcribingIndex = _messages
            .indexWhere((msg) => msg.key == ValueKey(tempTranscribingId));
        if (transcribingIndex != -1) {
          setState(() {
            _messages.removeAt(transcribingIndex);
            _logger.debug('Removed "Transcribing..." message due to error.');
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Error processing audio message. See console for details.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    _logger.debug('=== HANDLE AUDIO MESSAGE END ===');
  }

  Future<void> _processAssistantResponse(String response) async {
    _logger.debug('--- Processing Assistant Response Start ---');
    _logger.debug(
        'Response text: ${response.substring(0, math.min(response.length, 100))}...');

    String? uiAudioPath; // Absolute path for immediate UI use
    String? relativeAudioPathForStorage; // Relative path for storage
    Duration? audioDuration;

    final bool isErrorResponse = response.startsWith('Error:') ||
        response.contains('Unable to connect') ||
        response.contains('experiencing high demand') ||
        response.contains('temporarily unavailable') ||
        response.contains('rate limit') ||
        response.contains('Authentication failed');

    if (isErrorResponse) {
      _logger.debug('Received error response from service: $response');
      await _storageService.saveMessage(
        text: response,
        isUser: false,
        type: MessageType.text,
      );
      _logger.debug('Saved error response as text message to storage.');
    } else if (_audioAssistantInitialized) {
      _logger
          .debug('Audio assistant initialized, attempting audio generation.');
      try {
        // Save assistant message with text initially to get an ID
        // This ID will be used to name the audio file consistently
        await _storageService.saveMessage(
            text: response,
            isUser: false,
            type: MessageType.text // Save as text first
            );
        final savedMessages = await _storageService.getMessages(limit: 1);
        final assistantMessageId = savedMessages.first.id;
        _logger.debug(
            'Saved assistant text response to get ID: $assistantMessageId');

        final audioFile = await _audioMessageProvider.generateAudioForMessage(
          assistantMessageId
              .toString(), // Use actual message ID for audio generation
          response,
        );

        if (audioFile != null) {
          uiAudioPath = audioFile.path; // Keep absolute path for UI
          audioDuration = audioFile.duration;
          _logger.debug(
              'Generated audio file: $uiAudioPath, Duration: $audioDuration');

          // Calculate relative path for storage
          final Directory documentsDir =
              await getApplicationDocumentsDirectory();
          relativeAudioPathForStorage =
              path.relative(uiAudioPath, from: documentsDir.path);
          _logger.debug(
              'Calculated relative path for storage: $relativeAudioPathForStorage');

          // Update the message with audio details (using relative path)
          await _storageService.updateMessage(
            assistantMessageId,
            type: MessageType.audio,
            mediaPath: relativeAudioPathForStorage, // <-- Save relative path
            duration: audioDuration,
          );
          _logger.debug(
              'Updated message $assistantMessageId with relative audio path: $relativeAudioPathForStorage');
        } else {
          _logger.debug(
              'Audio file generation returned null for response (ID: $assistantMessageId). Message remains text.');
        }
      } catch (e) {
        _logger.error(
            'Error generating audio for assistant response: ${e.toString()}');
        // Message is already saved as text if audio generation failed here.
      }
    } else {
      _logger
          .debug('Audio assistant not initialized, skipping audio generation.');
      await _storageService.saveMessage(
        text: response,
        isUser: false,
        type: MessageType.text,
      );
      _logger.debug(
          'Saved assistant response as text message (audio assistant not initialized).');
    }

    final messages = await _storageService.getMessages(limit: 1);
    if (messages.isEmpty) {
      _logger.error(
          'Failed to retrieve last saved message from storage after processing assistant response.');
      if (mounted) setState(() => _isTyping = false);
      return;
    }
    final latestMessage = messages.first;
    final messageId = latestMessage.id;

    _logger
        .debug('Adding/updating assistant message in UI with ID: $messageId');
    _logger.debug(
        '  - Text: ${latestMessage.text.substring(0, math.min(latestMessage.text.length, 100))}...');
    _logger.debug('  - Type: ${latestMessage.type}');
    _logger
        .debug('  - Stored Media Path (Relative): ${latestMessage.mediaPath}');
    _logger.debug(
        '  - UI Audio Path (Absolute): $uiAudioPath'); // Will be null if no audio
    _logger.debug('  - Duration: ${latestMessage.duration ?? audioDuration}');

    final assistantMessage = ChatMessage(
      key: ValueKey(messageId),
      text: latestMessage.text, // Use text from storage
      isUser: false,
      audioPath: uiAudioPath, // <-- Pass ABSOLUTE path to widget if available
      duration: latestMessage.duration ?? audioDuration,
      audioPlayback: uiAudioPath != null ? _audioPlaybackController : null,
      onDelete: () => _deleteMessage(messageId),
    );

    if (mounted) {
      // Check if we need to replace a placeholder or insert new
      final existingMessageIndex =
          _messages.indexWhere((msg) => msg.key == ValueKey(messageId));
      if (existingMessageIndex != -1 &&
          _messages[existingMessageIndex].text != latestMessage.text) {
        _logger.debug(
            'Replacing existing message in UI for ID $messageId (likely text updated to audio).');
        setState(() {
          _messages[existingMessageIndex] = assistantMessage;
          _isTyping = false;
        });
      } else if (existingMessageIndex == -1) {
        _logger
            .debug('Inserting new assistant message in UI for ID $messageId.');
        setState(() {
          _messages.insert(0, assistantMessage);
          _isTyping = false;
        });
      } else {
        _logger.debug(
            'Message ID $messageId already exists and matches. No UI update needed here or _isTyping already false.');
        setState(() {
          _isTyping = false;
        }); // Ensure typing indicator is off
      }
      _scrollToBottom();
    }
    _logger.debug('--- Processing Assistant Response End ---');
  }
}
