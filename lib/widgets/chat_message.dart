import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'audio_message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/widgets/assistant_audio_message.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback.dart';
import 'dart:io';
import '../features/audio_assistant/models/playback_state.dart';

class ChatMessage extends StatefulWidget {
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

  @override
  _ChatMessageState createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  late AudioPlayback? _audioPlayback;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _audioPlayback = widget.audioPlayback;
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
        if (widget.isUser) ...[
          PopupMenuItem(
            child: const ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
            ),
            onTap: () {
              if (widget.onEdit != null) {
                // Delay to allow menu to close
                Future.delayed(const Duration(milliseconds: 10), () {
                  widget.onEdit!(widget.text);
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
              if (widget.onDelete != null) {
                widget.onDelete!();
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
            Clipboard.setData(ClipboardData(text: widget.text));
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
      text: text ?? widget.text,
      isUser: isUser ?? widget.isUser,
      audioPath: audioPath ?? widget.audioPath,
      duration: duration ?? widget.duration,
      isTest: isTest ?? widget.isTest,
      onDelete: onDelete ?? widget.onDelete,
      onEdit: onEdit ?? widget.onEdit,
      audioPlayback: audioPlayback ?? widget.audioPlayback,
    );
  }

  void _toggleAudio() async {
    if (_audioPlayback == null || widget.audioPath == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final messageKey = widget.key.toString();
      final messageText = widget.text;
      final shortText = messageText.length > 30
          ? '${messageText.substring(0, 30)}...'
          : messageText;

      debugPrint('=== AUDIO PLAYBACK DEBUG ===');
      debugPrint('Message Key: $messageKey');
      debugPrint('Message Text: $shortText');
      debugPrint('Audio Path: ${widget.audioPath}');

      if (_isPlaying) {
        debugPrint('Action: Pausing audio');
        await _audioPlayback!.pause();
        setState(() {
          _isPlaying = false;
          _isLoading = false;
        });
      } else {
        debugPrint('Action: Playing audio');
        // Load the audio file
        final audioFile = AudioFile(
          path: widget.audioPath!,
          duration: widget.duration ?? const Duration(seconds: 10),
        );

        debugPrint('Loading audio file: ${audioFile.path}');
        debugPrint('Audio duration: ${audioFile.duration}');

        await _audioPlayback!.load(audioFile);

        // Start playback
        final playResult = await _audioPlayback!.play();
        debugPrint('Play result: $playResult');

        if (playResult) {
          setState(() {
            _isPlaying = true;
          });

          // Listen for playback completion
          _audioPlayback!.onStateChanged.listen((state) {
            if (state == PlaybackState.stopped && _isPlaying) {
              debugPrint('Playback completed for: $messageKey');
              if (mounted) {
                setState(() {
                  _isPlaying = false;
                });
              }
            }
          });
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error toggling audio: $e');
      setState(() {
        _isPlaying = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!widget.isUser) ...[
            const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.military_tech, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: widget.audioPath != null
                ? widget.isUser
                    ? AudioMessage(
                        audioPath: widget.audioPath!,
                        isUser: widget.isUser,
                        transcription: widget.text,
                        duration: widget.duration ?? Duration.zero,
                      )
                    : (widget.audioPlayback != null
                        ? Builder(
                            builder: (context) {
                              try {
                                // Verify file exists before creating AssistantAudioMessage
                                final file = File(widget.audioPath!);
                                if (!file.existsSync()) {
                                  debugPrint(
                                      'Audio file not found at ${widget.audioPath}, falling back to text message');
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.text,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Audio unavailable',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red[400],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return AssistantAudioMessage(
                                  audioFile: AudioFile(
                                    path: widget.audioPath!,
                                    duration: widget.duration ?? Duration.zero,
                                  ),
                                  transcription: widget.text,
                                  audioPlayback: widget.audioPlayback!,
                                );
                              } catch (e) {
                                debugPrint(
                                    'Error creating AssistantAudioMessage: $e');
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.text,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Audio error: ${e.toString().split(":").first}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red[400],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          )
                        : AudioMessage(
                            audioPath: widget.audioPath!,
                            isUser: widget.isUser,
                            transcription: widget.text,
                            duration: widget.duration ?? Duration.zero,
                          ))
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          widget.isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.text,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
          ),
          if (widget.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue[300],
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: widget.isUser ? Colors.blue[700] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: () => _showMessageMenu(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: widget.isUser ? Colors.white : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
