import 'package:flutter/material.dart';
import 'audio_message.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? audioPath;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.audioPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundImage: NetworkImage(
                'https://api.dicebear.com/7.x/bottts/png?seed=sergeant-oracle',
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: audioPath != null
                ? AudioMessage(
                    audioPath: audioPath!,
                    isUser: isUser,
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
