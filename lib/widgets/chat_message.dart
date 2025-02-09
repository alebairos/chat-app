import 'package:flutter/material.dart';
import 'audio_message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? audioPath;
  final Duration? duration;
  final bool isTest;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.audioPath,
    this.duration,
    this.isTest = false,
    super.key,
  });

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    String? audioPath,
    Duration? duration,
    bool? isTest,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      audioPath: audioPath ?? this.audioPath,
      duration: duration ?? this.duration,
      isTest: isTest ?? this.isTest,
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
                    backgroundImage: AssetImage('assets/images/avatar.png'),
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
        ],
      ),
    );
  }
}
