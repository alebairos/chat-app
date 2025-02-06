import 'package:flutter/material.dart';
import '../widgets/chat_message.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_app_bar.dart';
import '../services/claude_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ClaudeService _claudeService = ClaudeService();
  bool _isTyping = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkEnvironment();
  }

  void _checkEnvironment() {
    if (dotenv.env['ANTHROPIC_API_KEY']?.isEmpty ?? true) {
      setState(() {
        _error = 'API Key not found. Please check your .env file.';
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final userMessage = _messageController.text;
      setState(() {
        _messages.add(
          ChatMessage(
            text: userMessage,
            isUser: true,
          ),
        );
        _isTyping = true;
      });
      _messageController.clear();

      try {
        final response = await _claudeService.sendMessage(userMessage);
        setState(() {
          _messages.add(
            ChatMessage(
              text: response,
              isUser: false,
            ),
          );
          _isTyping = false;
        });
      } catch (e) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Error: Unable to connect to Claude: $e',
              isUser: false,
            ),
          );
          _isTyping = false;
        });
      }
    }
  }

  void _handleAudioMessage(String audioPath) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: '', // Empty for audio messages
          isUser: true,
          audioPath: audioPath,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomChatAppBar(),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
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
                          backgroundImage: NetworkImage(
                            'https://api.dicebear.com/7.x/bottts/png?seed=sergeant-oracle',
                          ),
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
    super.dispose();
  }
}
