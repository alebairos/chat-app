class ClaudeAudioResponse {
  final String text;
  final String? audioPath;
  final Duration? audioDuration;
  final String? error;

  ClaudeAudioResponse({
    required this.text,
    this.audioPath,
    this.audioDuration,
    this.error,
  });

  @override
  String toString() {
    return 'ClaudeAudioResponse(text: ${text.length > 20 ? '${text.substring(0, 20)}...' : text}, '
        'audioPath: $audioPath, audioDuration: $audioDuration, error: $error)';
  }
}
