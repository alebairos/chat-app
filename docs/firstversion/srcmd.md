# Chat App Source Code

This document contains the complete source code for the Chat App project.

## Table of Contents
1. [Main Application](#main-application)
2. [Screens](#screens)
3. [Config](#config)
4. [Utils](#utils)
5. [Models](#models)
6. [Widgets](#widgets)
7. [Services](#services)
8. [Life Plan](#life-plan)
9. [Tests](#tests)

## Main Application

### main.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'services/claude_service.dart';
import 'services/storage_service.dart';
import 'services/transcription_service.dart';
import 'config/app_config.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize services
  final storageService = StorageService();
  final claudeService = ClaudeService();
  final transcriptionService = TranscriptionService();
  
  // Initialize app configuration
  final appConfig = AppConfig();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<ClaudeService>.value(value: claudeService),
        Provider<TranscriptionService>.value(value: transcriptionService),
        Provider<AppConfig>.value(value: appConfig),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
```

## Screens

### chat_screen.dart
```dart
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

  @override
  void initState() {
    super.initState();
    _claudeService = widget.claudeService ?? ClaudeService();
    _storageService = widget.storageService ?? ChatStorageService();
    _currentPersona = _configLoader.activePersonaDisplayName;
    _checkEnvironment();
    _loadMessages();
    _setupScrollListener();
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

      _logger.debug('4b. Updating UI with edited message');
      setState(() {
        final index = _messages.indexWhere((m) => m.key == ValueKey(int.parse(id)));
        if (index != -1) {
          _messages[index] = _createChatMessage(
            ChatMessageModel(
              id: int.parse(id),
              text: newText,
              type: MessageType.text,
              timestamp: DateTime.now(),
              isUser: true,
            ),
          );
        }
      });

      _logger.debug('5. Showing success message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message edited'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _logger.debug('6. Error during edit: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error editing message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkEnvironment() async {
    final anthropicKey = dotenv.env['ANTHROPIC_API_KEY'];
    final openaiKey = dotenv.env['OPENAI_API_KEY'];

    if (anthropicKey == null || anthropicKey.isEmpty) {
      setState(() {
        _error = 'ANTHROPIC_API_KEY not found in .env file';
      });
      return;
    }

    if (openaiKey == null || openaiKey.isEmpty) {
      setState(() {
        _error = 'OPENAI_API_KEY not found in .env file';
      });
      return;
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      text: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isUser: true,
    );

    setState(() {
      _messages.insert(0, _createChatMessage(userMessage));
    });

    try {
      await _storageService.saveMessage(userMessage);
      setState(() {
        _isTyping = true;
      });

      final response = await _claudeService.sendMessage(text);
      final assistantMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch,
        text: response,
        type: MessageType.text,
        timestamp: DateTime.now(),
        isUser: false,
      );

      await _storageService.saveMessage(assistantMessage);
      setState(() {
        _messages.insert(0, _createChatMessage(assistantMessage));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
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

  Future<void> _handleAudioMessage(String audioPath) async {
    try {
      setState(() {
        _isTyping = true;
      });

      final transcription = await _transcriptionService.transcribeAudio(audioPath);
      final userMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch,
        text: transcription,
        type: MessageType.audio,
        timestamp: DateTime.now(),
        isUser: true,
        audioPath: audioPath,
      );

      await _storageService.saveMessage(userMessage);
      setState(() {
        _messages.insert(0, _createChatMessage(userMessage));
      });

      final response = await _claudeService.sendMessage(transcription);
      final assistantMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch,
        text: response,
        type: MessageType.text,
        timestamp: DateTime.now(),
        isUser: false,
      );

      await _storageService.saveMessage(assistantMessage);
      setState(() {
        _messages.insert(0, _createChatMessage(assistantMessage));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing audio message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ChatMessage _createChatMessage(ChatMessageModel model) {
    return ChatMessage(
      key: ValueKey(model.id),
      message: model,
      onDelete: () => _deleteMessage(model.id),
      onEdit: () => _showEditDialog(model.id.toString(), model.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        title: _currentPersona,
        onReset: _resetChat,
      ),
      body: Column(
        children: [
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              backgroundColor: Colors.red,
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                  },
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          Expanded(
            child: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
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
              child: LinearProgressIndicator(),
            ),
          ChatInput(
            onSend: _sendMessage,
            onAudioMessage: _handleAudioMessage,
            controller: _messageController,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
```

## Config

### config_loader.dart
```dart
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'character_config_manager.dart';

class ConfigLoader {
  Future<String> Function() _loadSystemPromptImpl = _defaultLoadSystemPrompt;
  Future<Map<String, String>> Function() _loadExplorationPromptsImpl =
      _defaultLoadExplorationPrompts;

  final CharacterConfigManager _characterManager = CharacterConfigManager();

  Future<String> loadSystemPrompt() async {
    return _loadSystemPromptImpl();
  }

  Future<Map<String, String>> loadExplorationPrompts() async {
    return _loadExplorationPromptsImpl();
  }

  static Future<String> _defaultLoadSystemPrompt() async {
    try {
      final characterManager = CharacterConfigManager();
      return await characterManager.loadSystemPrompt();
    } catch (e) {
      print('Error loading system prompt: $e');
      throw Exception('Failed to load system prompt');
    }
  }

  static Future<Map<String, String>> _defaultLoadExplorationPrompts() async {
    try {
      final characterManager = CharacterConfigManager();
      return await characterManager.loadExplorationPrompts();
    } catch (e) {
      print('Error loading exploration prompts: $e');
      throw Exception('Failed to load exploration prompts');
    }
  }

  @visibleForTesting
  void setLoadSystemPromptImpl(Future<String> Function() impl) {
    _loadSystemPromptImpl = impl;
  }

  @visibleForTesting
  void setLoadExplorationPromptsImpl(
      Future<Map<String, String>> Function() impl) {
    _loadExplorationPromptsImpl = impl;
  }

  /// Get the currently active character persona
  CharacterPersona get activePersona => _characterManager.activePersona;

  /// Set the active character persona
  void setActivePersona(CharacterPersona persona) {
    _characterManager.setActivePersona(persona);
  }

  /// Get the display name for the active persona
  String get activePersonaDisplayName => _characterManager.personaDisplayName;

  /// Get a list of all available personas
  List<Map<String, dynamic>> get availablePersonas =>
      _characterManager.availablePersonas;
}
```

### character_config_manager.dart
```dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Enum representing the available character personas
enum CharacterPersona { personalDevelopmentAssistant, sergeantOracle, zenGuide }

/// Class to manage character configurations and allow switching between personas
class CharacterConfigManager {
  static final CharacterConfigManager _instance =
      CharacterConfigManager._internal();
  factory CharacterConfigManager() => _instance;
  CharacterConfigManager._internal();

  /// The currently active character persona
  CharacterPersona _activePersona =
      CharacterPersona.personalDevelopmentAssistant;

  /// Get the currently active character persona
  CharacterPersona get activePersona => _activePersona;

  /// Set the active character persona
  void setActivePersona(CharacterPersona persona) {
    _activePersona = persona;
  }

  /// Get the configuration file path for the active persona
  String get configFilePath {
    switch (_activePersona) {
      case CharacterPersona.personalDevelopmentAssistant:
        return 'lib/config/claude_config.json';
      case CharacterPersona.sergeantOracle:
        return 'lib/config/sergeant_oracle_config.json';
      case CharacterPersona.zenGuide:
        return 'lib/config/zen_guide_config.json';
    }
  }

  /// Get the display name for the active persona
  String get personaDisplayName {
    switch (_activePersona) {
      case CharacterPersona.personalDevelopmentAssistant:
        return 'Personal Development Assistant';
      case CharacterPersona.sergeantOracle:
        return 'Sergeant Oracle';
      case CharacterPersona.zenGuide:
        return 'The Zen Guide';
    }
  }

  /// Load the system prompt for the active persona
  Future<String> loadSystemPrompt() async {
    try {
      final String jsonString = await rootBundle.loadString(configFilePath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return jsonMap['system_prompt']['content'] as String;
    } catch (e) {
      print('Error loading system prompt: $e');
      throw Exception('Failed to load system prompt for $personaDisplayName');
    }
  }

  /// Load the exploration prompts for the active persona
  Future<Map<String, String>> loadExplorationPrompts() async {
    try {
      final String jsonString = await rootBundle.loadString(configFilePath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      if (jsonMap['exploration_prompts'] == null) {
        throw Exception('Exploration prompts not found in config');
      }

      final Map<String, dynamic> promptsMap =
          jsonMap['exploration_prompts'] as Map<String, dynamic>;
      return promptsMap.map((key, value) => MapEntry(key, value as String));
    } catch (e) {
      print('Error loading exploration prompts: $e');
      throw Exception(
          'Failed to load exploration prompts for $personaDisplayName');
    }
  }

  /// Get a list of all available personas with their display names and descriptions
  List<Map<String, dynamic>> get availablePersonas {
    return [
      {
        'displayName': 'Personal Development Assistant',
        'description':
            'Empathetic and encouraging guide focused on practical solutions for achieving goals through positive habits.'
      },
      {
        'displayName': 'Sergeant Oracle',
        'description':
            'Roman time-traveler with military precision and ancient wisdom, combining historical insights with futuristic perspective.'
      },
      {
        'displayName': 'The Zen Guide',
        'description':
            'Calm and mindful mentor with Eastern wisdom traditions, focusing on balance, mindfulness, and inner peace.'
      }
    ];
  }
}
```

## Utils

### logger.dart
```dart
import 'package:flutter/foundation.dart';

/// A utility class for controlling logging throughout the app.
class Logger {
  /// Singleton instance
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  /// Whether logging is enabled
  bool _isEnabled = false;

  /// Whether to log startup events (data loading, initialization)
  bool _logStartupEvents = false;

  /// Enable or disable all logging
  void setLogging(bool enabled) {
    _isEnabled = enabled;
  }

  /// Enable or disable logging of startup events specifically
  void setStartupLogging(bool enabled) {
    _logStartupEvents = enabled;
  }

  /// Check if startup logging is enabled
  bool isStartupLoggingEnabled() {
    return _isEnabled && _logStartupEvents;
  }

  /// Log a message if logging is enabled
  void log(String message) {
    if (_isEnabled) {
      print(message);
    }
  }

  /// Log a startup-related message if startup logging is enabled
  void logStartup(String message) {
    if (_isEnabled && _logStartupEvents) {
      print('🚀 [STARTUP] $message');
    }
  }

  /// Log an error message if logging is enabled
  void error(String message) {
    if (_isEnabled) {
      print('❌ [ERROR] $message');
    }
  }

  /// Log a warning message if logging is enabled
  void warning(String message) {
    if (_isEnabled) {
      print('⚠️ [WARNING] $message');
    }
  }

  /// Log an info message if logging is enabled
  void info(String message) {
    if (_isEnabled) {
      print('ℹ️ [INFO] $message');
    }
  }

  /// Log a debug message if logging is enabled and in debug mode
  void debug(String message) {
    if (_isEnabled && kDebugMode) {
      print('🔍 [DEBUG] $message');
    }
  }
}
```

## Models

### message_type.dart
```dart
enum MessageType {
  text,
  audio,
  image,
}
```

### chat_message_model.dart
```dart
import 'package:isar/isar.dart';
import 'message_type.dart';

part 'chat_message_model.g.dart';

@collection
class ChatMessageModel {
  Id id = Isar.autoIncrement;

  @Index()
  DateTime timestamp;

  @Index()
  String text;

  bool isUser;

  @enumerated
  MessageType type;

  List<byte>? mediaData;

  String? mediaPath;

  @Index()
  int? durationInMillis;

  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.type,
    required this.timestamp,
    this.mediaData,
    this.mediaPath,
    Duration? duration,
  }) : durationInMillis = duration?.inMilliseconds;

  @ignore
  Duration? get duration => durationInMillis != null
      ? Duration(milliseconds: durationInMillis!)
      : null;

  @ignore
  set duration(Duration? value) {
    durationInMillis = value?.inMilliseconds;
  }

  ChatMessageModel copyWith({
    Id? id,
    DateTime? timestamp,
    String? text,
    bool? isUser,
    MessageType? type,
    List<byte>? mediaData,
    String? mediaPath,
    Duration? duration,
  }) {
    final model = ChatMessageModel(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      mediaData: mediaData ?? this.mediaData,
      mediaPath: mediaPath ?? this.mediaPath,
      duration: duration ?? this.duration,
    );
    model.id = id ?? this.id;
    return model;
  }
}
```

## Widgets

### chat_message.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'audio_message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? audioPath;
  final Duration? duration;
  final bool isTest;
  final VoidCallback? onDelete;
  final Function(String)? onEdit;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.audioPath,
    this.duration,
    this.isTest = false,
    this.onDelete,
    this.onEdit,
    super.key,
  });

  void _showMessageMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + button.size.width,
        offset.dy + button.size.height,
      ),
      items: [
        if (isUser) ...[
          PopupMenuItem(
            child: const ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
            ),
            onTap: () {
              if (onEdit != null) {
                // Delay to allow menu to close
                Future.delayed(const Duration(milliseconds: 10), () {
                  onEdit!(text);
                });
              }
            },
          ),
          PopupMenuItem(
            child: const ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
            ),
            onTap: () {
              if (onDelete != null) {
                onDelete!();
              }
            },
          ),
        ],
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.copy),
            title: Text('Copy'),
          ),
          onTap: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Message copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.flag),
            title: Text('Report'),
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Message reported'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    String? audioPath,
    Duration? duration,
    bool? isTest,
    VoidCallback? onDelete,
    Function(String)? onEdit,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      audioPath: audioPath ?? this.audioPath,
      duration: duration ?? this.duration,
      isTest: isTest ?? this.isTest,
      onDelete: onDelete ?? this.onDelete,
      onEdit: onEdit ?? this.onEdit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            isTest
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Placeholder(),
                  )
                : const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.military_tech, color: Colors.white),
                  ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: audioPath != null
                ? AudioMessage(
                    audioPath: audioPath!,
                    isUser: isUser,
                    transcription: text,
                    duration: duration ?? Duration.zero,
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: MarkdownBody(
                      data: text,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: isUser ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: isUser ? Colors.blue[700] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: () => _showMessageMenu(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: isUser ? Colors.white : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
```

### chat_input.dart
```dart
import 'package:flutter/material.dart';
import 'audio_recorder.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String path, Duration duration) onSendAudio;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onSendAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Send a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onSend();
                  controller.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          AudioRecorder(
            onSendAudio: onSendAudio,
          ),
        ],
      ),
    );
  }
}
```

### chat_app_bar.dart
```dart
import 'package:flutter/material.dart';

class CustomChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomChatAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.military_tech, color: Colors.white),
          ),
          SizedBox(width: 8),
          Text('Sergeant Oracle'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'Information',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('About Sergeant Oracle'),
                content: const SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Sergeant Oracle is an AI assistant powered by Claude.'),
                      SizedBox(height: 16),
                      Text('You can:'),
                      SizedBox(height: 8),
                      Text('• Send text messages'),
                      Text('• Record audio messages'),
                      Text('• Long press your messages to delete them'),
                      Text('• Scroll up to load older messages'),
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
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```

## Services

### claude_service.dart
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/config_loader.dart';
import 'life_plan_mcp_service.dart';
import '../models/life_plan/dimensions.dart';
import '../utils/logger.dart';

// Helper class for validation results
class ValidationResult {
  final bool isValid;
  final String reason;

  ValidationResult(this.isValid, this.reason);
}

class ClaudeService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  late final String _apiKey;
  final List<Map<String, String>> _conversationHistory = [];
  String? _systemPrompt;
  bool _isInitialized = false;
  final _logger = Logger();
  final http.Client _client;
  final LifePlanMCPService? _lifePlanMCP;
  final ConfigLoader _configLoader;

  ClaudeService({
    http.Client? client,
    LifePlanMCPService? lifePlanMCP,
    ConfigLoader? configLoader,
  })  : _client = client ?? http.Client(),
        _lifePlanMCP = lifePlanMCP,
        _configLoader = configLoader ?? ConfigLoader() {
    _apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  }

  // Method to enable or disable logging
  void setLogging(bool enable) {
    _logger.setLogging(enable);
    // Also set logging for MCP service if available
    _lifePlanMCP?.setLogging(enable);
  }

  Future<bool> initialize() async {
    if (!_isInitialized) {
      try {
        _systemPrompt = await _configLoader.loadSystemPrompt();
        _isInitialized = true;
      } catch (e) {
        _logger.error('Error initializing Claude service: $e');
        return false;
      }
    }
    return _isInitialized;
  }

  // Helper method to extract user-friendly error messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    try {
      // Check if the error is a string that contains JSON
      if (error is String && error.contains('{') && error.contains('}')) {
        // Try to extract the error message from the JSON
        final errorJson = json.decode(
            error.substring(error.indexOf('{'), error.lastIndexOf('}') + 1));

        // Handle specific error types
        if (errorJson['error'] != null && errorJson['error']['type'] != null) {
          final errorType = errorJson['error']['type'];

          switch (errorType) {
            case 'overloaded_error':
              return 'Claude is currently experiencing high demand. Please try again in a moment.';
            case 'rate_limit_error':
              return 'You\'ve reached the rate limit. Please wait a moment before sending more messages.';
            case 'authentication_error':
              return 'Authentication failed. Please check your API key.';
            case 'invalid_request_error':
              return 'There was an issue with the request. Please try again with a different message.';
            default:
              // If we have a message in the error, use it
              if (errorJson['error']['message'] != null) {
                return 'Claude error: ${errorJson['error']['message']}';
              }
          }
        }
      }

      // If we couldn't parse the error or it's not a recognized type
      if (error.toString().contains('SocketException') ||
          error.toString().contains('Connection refused') ||
          error.toString().contains('Network is unreachable')) {
        return 'Unable to connect to Claude. Please check your internet connection.';
      }

      // Default error message
      return 'Unable to get a response from Claude. Please try again later.';
    } catch (e) {
      // If we fail to parse the error, return a generic message
      return 'An error occurred while communicating with Claude. Please try again.';
    }
  }

  // Helper method to process MCP commands and get data
  Future<Map<String, dynamic>> _processMCPCommand(String command) async {
    if (_lifePlanMCP == null) {
      return {'error': 'MCP service not available'};
    }

    try {
      final response = _lifePlanMCP!.processCommand(command);
      final decoded = json.decode(response);
      return decoded;
    } catch (e) {
      _logger.error('Error processing MCP command: $e');
      return {'error': e.toString()};
    }
  }

  // Helper method to detect dimensions in user message
  List<String> _detectDimensions(String message) {
    // Instead of hard-coded keyword matching, we'll fetch all dimensions
    // and let Claude's system prompt handle the detection
    return Dimensions.codes; // Return all dimension codes
  }

  // Helper method to fetch relevant MCP data based on user message
  Future<String> _fetchRelevantMCPData(String message) async {
    if (_lifePlanMCP == null) {
      return '';
    }

    final dimensions = _detectDimensions(message);
    final buffer = StringBuffer();

    // If no dimensions detected, fetch data for all dimensions
    if (dimensions.isEmpty) {
      dimensions.addAll(['SF', 'SM', 'R']);
    }

    // Fetch goals for each detected dimension
    for (final dimension in dimensions) {
      final command = json
          .encode({'action': 'get_goals_by_dimension', 'dimension': dimension});

      final result = await _processMCPCommand(command);
      if (result['status'] == 'success' && result['data'] != null) {
        buffer.writeln('\nMCP DATA - Goals for dimension $dimension:');
        buffer.writeln(json.encode(result['data']));

        // For each goal, try to fetch the associated track
        for (final goal in result['data']) {
          if (goal['trackId'] != null) {
            final trackCommand = json.encode(
                {'action': 'get_track_by_id', 'trackId': goal['trackId']});

            final trackResult = await _processMCPCommand(trackCommand);
            if (trackResult['status'] == 'success' &&
                trackResult['data'] != null) {
              buffer.writeln('\nMCP DATA - Track for goal ${goal['id']}:');
              buffer.writeln(json.encode(trackResult['data']));

              // For each challenge in the track, fetch habits
              if (trackResult['data']['challenges'] != null) {
                for (final challenge in trackResult['data']['challenges']) {
                  final habitsCommand = json.encode({
                    'action': 'get_habits_for_challenge',
                    'trackId': goal['trackId'],
                    'challengeCode': challenge['code']
                  });

                  final habitsResult = await _processMCPCommand(habitsCommand);
                  if (habitsResult['status'] == 'success' &&
                      habitsResult['data'] != null) {
                    buffer.writeln(
                        '\nMCP DATA - Habits for challenge ${challenge['code']}:');
                    buffer.writeln(json.encode(habitsResult['data']));
                  }
                }
              }
            }
          }
        }
      }
    }

    // Fetch recommended habits for each dimension
    for (final dimension in dimensions) {
      final command = json.encode({
        'action': 'get_recommended_habits',
        'dimension': dimension,
        'minImpact': 3
      });

      final result = await _processMCPCommand(command);
      if (result['status'] == 'success' && result['data'] != null) {
        buffer.writeln(
            '\nMCP DATA - Recommended habits for dimension $dimension:');
        buffer.writeln(json.encode(result['data']));
      }
    }

    return buffer.toString();
  }

  Future<String> sendMessage(String message) async {
    try {
      await initialize();

      // Check if message contains a life plan command
      if (_lifePlanMCP != null && message.startsWith('{')) {
        try {
          final Map<String, dynamic> command = json.decode(message);
          final action = command['action'] as String?;

          if (action == null) {
            return 'Missing required parameter: action';
          }

          try {
            return _lifePlanMCP!.processCommand(message);
          } catch (e) {
            return 'Missing required parameter: ${e.toString()}';
          }
        } catch (e) {
          return 'Invalid command format';
        }
      }

      // Add user message to history
      _conversationHistory.add({
        'role': 'user',
        'content': message,
      });

      // Fetch relevant MCP data based on user message
      final mcpData = await _fetchRelevantMCPData(message);
      Map<String, dynamic>? mcpDataMap;

      // Parse MCP data for validation
      if (mcpData.isNotEmpty) {
        mcpDataMap = _parseMCPDataForValidation(mcpData);
      }

      // Prepare messages array with history
      final messages = <Map<String, String>>[];

      // Add conversation history
      messages.addAll(_conversationHistory);

      // Prepare the request body
      final requestBody = {
        'model': 'claude-3-opus-20240229',
        'max_tokens': 4096,
        'messages': messages,
        'system': _systemPrompt,
      };

      // Make the API request
      final response = await _client.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: json.encode(requestBody),
      );

      // Handle the response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final assistantMessage = responseData['content'][0]['text'];
        _conversationHistory.add({
          'role': 'assistant',
          'content': assistantMessage,
        });
        return assistantMessage;
      } else {
        throw _getUserFriendlyErrorMessage(response.body);
      }
    } catch (e) {
      _logger.error('Error in sendMessage: $e');
      throw _getUserFriendlyErrorMessage(e);
    }
  }

  // Helper method to parse MCP data for validation
  Map<String, dynamic>? _parseMCPDataForValidation(String mcpData) {
    try {
      final lines = mcpData.split('\n');
      final Map<String, dynamic> result = {};

      for (final line in lines) {
        if (line.startsWith('MCP DATA - ')) {
          final parts = line.split(':');
          if (parts.length == 2) {
            final key = parts[0].replaceAll('MCP DATA - ', '').trim();
            try {
              result[key] = json.decode(parts[1].trim());
            } catch (e) {
              result[key] = parts[1].trim();
            }
          }
        }
      }

      return result;
    } catch (e) {
      _logger.error('Error parsing MCP data: $e');
      return null;
    }
  }
}
```

### chat_storage_service.dart
```dart
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/chat_message_model.dart';
import '../models/message_type.dart';
import 'dart:typed_data';

class ChatStorageService {
  late Future<Isar> db;

  ChatStorageService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [ChatMessageModelSchema],
        directory: dir.path,
      );
    }

    return Future.value(Isar.getInstance());
  }

  Future<void> saveMessage({
    required String text,
    required bool isUser,
    required MessageType type,
    Uint8List? mediaData,
    String? mediaPath,
    Duration? duration,
  }) async {
    final isar = await db;

    // Verify audio file exists if it's an audio message
    if (type == MessageType.audio && mediaPath != null) {
      final file = File(mediaPath);
      if (!await file.exists()) {
        throw Exception('Audio file not found at $mediaPath');
      }
    }

    final message = ChatMessageModel(
      text: text,
      isUser: isUser,
      type: type,
      timestamp: DateTime.now(),
      mediaData: mediaData?.toList(),
      mediaPath: mediaPath,
      duration: duration,
    );

    await isar.writeTxn(() async {
      await isar.chatMessageModels.put(message);
    });
  }

  Future<List<ChatMessageModel>> getMessages({
    int? limit,
    DateTime? before,
  }) async {
    final isar = await db;
    final query = isar.chatMessageModels.where();

    if (before != null) {
      return query
          .filter()
          .timestampLessThan(before)
          .sortByTimestampDesc()
          .limit(limit ?? 50)
          .findAll();
    }

    return query.sortByTimestampDesc().limit(limit ?? 50).findAll();
  }

  Future<void> deleteMessage(Id id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final message = await isar.chatMessageModels.get(id);
      if (message != null && message.isUser) {
        // Delete the audio file if it exists
        if (message.type == MessageType.audio && message.mediaPath != null) {
          final file = File(message.mediaPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        // Delete the message from the database
        await isar.chatMessageModels.delete(id);
      }
    });
  }

  Future<void> editMessage(Id id, String newText) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final message = await isar.chatMessageModels.get(id);
      if (message != null && message.isUser) {
        // Only allow editing user messages
        message.text = newText;
        message.timestamp =
            DateTime.now(); // Update timestamp to mark as edited
        await isar.chatMessageModels.put(message);
      }
    });
  }

  Future<void> deleteAllMessages() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.chatMessageModels.clear();
    });
  }

  Future<List<ChatMessageModel>> searchMessages(String query) async {
    final isar = await db;
    return await isar.chatMessageModels
        .where()
        .filter()
        .textContains(query, caseSensitive: false)
        .sortByTimestampDesc()
        .findAll();
  }

  Future<void> close() async {
    final isar = await db;
    await isar.close();
  }
}
```

### transcription_service.dart
```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAITranscriptionService {
  static const String _baseUrl =
      'https://api.openai.com/v1/audio/transcriptions';
  final String _apiKey;
  final http.Client _client;
  bool _initialized = false;

  OpenAITranscriptionService({http.Client? client})
      : _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '',
        _client = client ?? http.Client() {
    _initialized = _apiKey.isNotEmpty;
  }

  bool get isInitialized => _initialized;

  Future<String> transcribeAudio(String audioPath) async {
    if (!isInitialized) {
      return 'Transcription unavailable: Service not initialized';
    }

    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        return 'Transcription unavailable';
      }

      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl))
        ..headers['Authorization'] = 'Bearer $_apiKey'
        ..headers['Accept'] = 'application/json; charset=utf-8'
        ..headers['Content-Type'] = 'multipart/form-data; charset=utf-8'
        ..files.add(await http.MultipartFile.fromPath('file', audioPath))
        ..fields['model'] = 'whisper-1';

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return jsonResponse['text'] ?? 'No transcription available';
      }
      return 'Transcription failed: ${response.statusCode}';
    } catch (e) {
      // Just return the error message without printing during tests
      return 'Transcription unavailable';
    }
  }
}
```

Let me continue by checking the life plan directory: