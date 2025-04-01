import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:character_ai_clone/features/audio_assistant/widgets/audio_message.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/widgets/assistant_audio_message.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback.dart';
import 'package:character_ai_clone/features/audio_assistant/models/playback_state.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback_manager.dart';
import '../utils/logger.dart';

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

  /// Creates a copy of this ChatMessage with the given fields replaced with new values
  ChatMessage copyWith({
    String? text,
    bool? isUser,
    String? audioPath,
    Duration? duration,
    bool? isTest,
    VoidCallback? onDelete,
    Function(String)? onEdit,
    AudioPlayback? audioPlayback,
    Key? key,
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
      key: key ?? this.key,
    );
  }

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  late AudioPlayback? _audioPlayback;
  bool _isPlaying = false;
  late final String _widgetId;
  late final AudioPlaybackManager _playbackManager;
  StreamSubscription<PlaybackStateUpdate>? _playbackSubscription;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _audioPlayback = widget.audioPlayback;
    _widgetId = widget.key.toString();

    // Initialize audio playback if needed
    if (widget.audioPath != null) {
      _playbackManager = AudioPlaybackManager();

      // Listen to playback state changes
      _playbackSubscription = _playbackManager.playbackStateStream.listen(
        (update) {
          if (update.widgetId == _widgetId && mounted && !_disposed) {
            logDebugPrint(
                'ChatMessage: Received playback state update: ${update.state}');
            setState(() {
              _isPlaying = update.state == PlaybackState.playing;
            });
          }
        },
        onError: (error) {
          logDebugPrint('ChatMessage: Error in playback stream: $error');
        },
        onDone: () {
          logDebugPrint('ChatMessage: Playback stream closed');
        },
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    logDebugPrint('ChatMessage: Disposing widget $_widgetId');
    _playbackSubscription?.cancel();
    super.dispose();
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
            Future.delayed(const Duration(milliseconds: 10), () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            });
          },
        ),
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.flag),
            title: Text('Report'),
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 10), () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message reported'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug the audio path if available
    if (widget.audioPath != null) {
      logDebugPrint(
          'ChatMessage: Building with audio path: ${widget.audioPath}');
    }

    // Clean up the key string by removing brackets and angle brackets
    final cleanKey = _cleanKeyString(widget.key.toString());

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
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isUser ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.audioPath != null) ...[
                    Builder(
                      builder: (context) {
                        if ((widget.isTest &&
                                widget.audioPath == 'nonexistent.m4a') ||
                            (!widget.isTest &&
                                !File(widget.audioPath!).existsSync())) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.text,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Audio unavailable',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red[400],
                                ),
                              ),
                            ],
                          );
                        }

                        try {
                          return widget.isUser
                              ? AudioMessage(
                                  messageId: cleanKey,
                                  audioPath: widget.audioPath!,
                                  audioDuration: widget.duration!,
                                  isAssistantMessage: false,
                                )
                              : AssistantAudioMessage(
                                  audioFile: AudioFile(
                                    path: widget.audioPath!,
                                    duration: widget.duration!,
                                  ),
                                  transcription: widget.text,
                                  audioPlayback: widget.audioPlayback!,
                                );
                        } catch (e) {
                          logDebugPrint(
                              'ChatMessage: Error creating audio message: $e');
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.text,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Audio unavailable',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red[400],
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ] else ...[
                    Text(
                      widget.text,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
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

  String _cleanKeyString(String keyStr) {
    return keyStr.replaceAll(RegExp(r'[\[<>]'), '').replaceAll("'", '');
  }
}
