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
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ClaudeService _claudeService = ClaudeService();
  final ChatStorageService _storageService = ChatStorageService();
  bool _isTyping = false;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  DateTime? _lastMessageTimestamp;
  static const int _pageSize = 20;
  final OpenAITranscriptionService _transcriptionService =
      OpenAITranscriptionService();

  @override
  void initState() {
    super.initState();
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

  ChatMessage _createChatMessage(ChatMessageModel model) {
    return ChatMessage(
      key: ValueKey(model.id),
      text: model.text,
      isUser: model.isUser,
      audioPath: model.mediaPath,
      duration: model.duration,
      onDelete: () => _deleteMessage(model.id),
    );
  }

  Future<void> _deleteMessage(int id) async {
    try {
      await _storageService.deleteMessage(id);
      setState(() {
        _messages.removeWhere((m) => m.key == ValueKey(id));
      });
      if (!mounted) return;
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
    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
    );

    setState(() {
      _messages.insert(0, userChatMessage);
      _isTyping = true;
    });
    _messageController.clear();

    try {
      // Save user message
      await _storageService.saveMessage(
        text: userMessage,
        isUser: true,
        type: MessageType.text,
      );

      // Get AI response
      final response = await _claudeService.sendMessage(userMessage);
      final aiChatMessage = ChatMessage(
        text: response,
        isUser: false,
      );

      // Save AI response
      await _storageService.saveMessage(
        text: response,
        isUser: false,
        type: MessageType.text,
      );

      setState(() {
        _messages.insert(0, aiChatMessage);
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            text: 'Error: Unable to send message: $e',
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

    try {
      final transcription =
          await _transcriptionService.transcribeAudio(audioPath);

      // Update UI with transcription
      final userAudioMessage = ChatMessage(
        text: transcription,
        isUser: true,
        audioPath: audioPath,
        duration: duration,
      );

      setState(() {
        _messages[0] = userAudioMessage;
      });

      // Save audio message
      await _storageService.saveMessage(
        text: transcription,
        isUser: true,
        type: MessageType.audio,
        mediaPath: audioPath,
        duration: duration,
      );

      // Send transcription to Claude
      final response = await _claudeService.sendMessage(transcription);
      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
      );

      // Save AI response
      await _storageService.saveMessage(
        text: response,
        isUser: false,
        type: MessageType.text,
      );

      setState(() {
        _messages.insert(0, aiMessage);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing audio message: $e'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error processing audio message: $e');
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
                    backgroundImage: AssetImage('assets/images/avatar.png'),
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
