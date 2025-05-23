/// Model representing an audio file in the application
class AudioFile {
  /// Local file path to the audio
  final String path;

  /// Duration of the audio file
  final Duration duration;

  /// Size of the file in bytes
  final int? sizeInBytes;

  /// MIME type of the audio file (e.g., "audio/aiff")
  final String? mimeType;

  /// Optional transcription of the audio content
  final String? transcription;

  const AudioFile({
    required this.path,
    required this.duration,
    this.sizeInBytes,
    this.mimeType,
    this.transcription,
  });

  AudioFile copyWith({
    String? path,
    Duration? duration,
    int? sizeInBytes,
    String? mimeType,
    String? transcription,
  }) {
    return AudioFile(
      path: path ?? this.path,
      duration: duration ?? this.duration,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      mimeType: mimeType ?? this.mimeType,
      transcription: transcription ?? this.transcription,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioFile &&
        other.path == path &&
        other.duration == duration &&
        other.sizeInBytes == sizeInBytes &&
        other.mimeType == mimeType &&
        other.transcription == transcription;
  }

  @override
  int get hashCode => Object.hash(
        path,
        duration,
        sizeInBytes,
        mimeType,
        transcription,
      );
}
