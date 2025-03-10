import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'audio_message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/widgets/assistant_audio_message.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? audioPath;
  final Duration? duration;
  final bool isTest;
  final VoidCallback? onDelete;
  final Function(String)? onEdit;
  final AudioPlayback? audioPlayback;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.audioPath,
    this.duration,
    this.isTest = false,
    this.onDelete,
    this.onEdit,
    this.audioPlayback,
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
    AudioPlayback? audioPlayback,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      audioPath: audioPath ?? this.audioPath,
      duration: duration ?? this.duration,
      isTest: isTest ?? this.isTest,
      onDelete: onDelete ?? this.onDelete,
      onEdit: onEdit ?? this.onEdit,
      audioPlayback: audioPlayback ?? this.audioPlayback,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.military_tech, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: audioPath != null
                ? isUser
                    ? AudioMessage(
                        audioPath: audioPath!,
                        isUser: isUser,
                        transcription: text,
                        duration: duration ?? Duration.zero,
                      )
                    : (audioPlayback != null
                        ? AssistantAudioMessage(
                            audioFile: AudioFile(
                              path: audioPath!,
                              duration: duration ?? Duration.zero,
                            ),
                            transcription: text,
                            audioPlayback: audioPlayback!,
                          )
                        : AudioMessage(
                            audioPath: audioPath!,
                            isUser: isUser,
                            transcription: text,
                            duration: duration ?? Duration.zero,
                          ))
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue[300],
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
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
