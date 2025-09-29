import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'audio_message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../features/audio_assistant/widgets/assistant_audio_message.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? audioPath;
  final Duration? duration;
  final bool isTest;
  final VoidCallback? onDelete;
  final Function(String)? onEdit;
  final String? personaKey;
  final String? personaDisplayName;
  final DateTime? timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.audioPath,
    this.duration,
    this.isTest = false,
    this.onDelete,
    this.onEdit,
    this.personaKey,
    this.personaDisplayName,
    this.timestamp,
    super.key,
  });

  Color _getPersonaColor(String? personaKey) {
    if (personaKey == null) return Colors.deepPurple; // default to Sergeant

    final Map<String, Color> colorMap = {
      'ariLifeCoach': Colors.teal,
      'sergeantOracle': Colors.deepPurple,
      'iThereClone': Colors.blue,
    };

    return colorMap[personaKey] ?? Colors.grey;
  }

  IconData _getPersonaIcon(String? personaKey) {
    if (personaKey == null) return Icons.military_tech; // default to Sergeant

    final Map<String, IconData> iconMap = {
      'ariLifeCoach': Icons.psychology,
      'sergeantOracle': Icons.military_tech,
      'iThereClone': Icons.face,
      'ariWithOracle21': Icons.psychology,
      'iThereWithOracle21': Icons.face,
    };

    return iconMap[personaKey] ?? Icons.smart_toy;
  }

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
    String? personaKey,
    String? personaDisplayName,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      audioPath: audioPath ?? this.audioPath,
      duration: duration ?? this.duration,
      isTest: isTest ?? this.isTest,
      onDelete: onDelete ?? this.onDelete,
      onEdit: onEdit ?? this.onEdit,
      personaKey: personaKey ?? this.personaKey,
      personaDisplayName: personaDisplayName ?? this.personaDisplayName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
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
                : CircleAvatar(
                    backgroundColor: _getPersonaColor(personaKey),
                    child: Icon(
                      _getPersonaIcon(personaKey),
                      color: Colors.white,
                    ),
                  ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                audioPath != null
                    ? isUser
                        ? AudioMessage(
                            audioPath: audioPath!,
                            isUser: isUser,
                            transcription: text,
                            duration: duration ?? Duration.zero,
                          )
                        : AssistantAudioMessage(
                            audioPath: audioPath!,
                            transcription: text,
                            duration: duration ?? Duration.zero,
                            messageId: key.toString(),
                          )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: MarkdownBody(
                          data: text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: isUser ? Colors.white : Colors.black,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                // FT-160: Add timestamp display
                if (timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('yyyy/MM/dd, HH:mm').format(timestamp!),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
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
