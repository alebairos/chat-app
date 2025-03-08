import 'dart:convert';

/// Represents an audio file with its metadata.
///
/// This class encapsulates all the information related to an audio file,
/// including its path, duration, waveform data for visualization, and
/// optional transcription.
class AudioFile {
  /// The file path to the audio file.
  final String path;

  /// The duration of the audio file.
  final Duration duration;

  /// Optional waveform data for visualization.
  ///
  /// This is a list of double values between 0.0 and 1.0 representing
  /// the amplitude of the audio at different points in time.
  final List<double>? waveformData;

  /// Optional transcription of the audio content.
  final String? transcription;

  /// Creates a new [AudioFile] instance.
  ///
  /// [path] and [duration] are required parameters.
  /// [waveformData] and [transcription] are optional.
  const AudioFile({
    required this.path,
    required this.duration,
    this.waveformData,
    this.transcription,
  });

  /// Creates a copy of this [AudioFile] with the given fields replaced with new values.
  AudioFile copyWith({
    String? path,
    Duration? duration,
    List<double>? waveformData,
    String? transcription,
  }) {
    return AudioFile(
      path: path ?? this.path,
      duration: duration ?? this.duration,
      waveformData: waveformData ?? this.waveformData,
      transcription: transcription ?? this.transcription,
    );
  }

  /// Converts this [AudioFile] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'duration': duration.inMilliseconds,
      if (waveformData != null) 'waveformData': waveformData,
      if (transcription != null) 'transcription': transcription,
    };
  }

  /// Creates an [AudioFile] from a JSON map.
  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      path: json['path'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      waveformData: json['waveformData'] != null
          ? (json['waveformData'] as List).cast<double>()
          : null,
      transcription: json['transcription'] as String?,
    );
  }

  /// Encodes this [AudioFile] to a JSON string.
  String encode() => jsonEncode(toJson());

  /// Creates an [AudioFile] from a JSON string.
  factory AudioFile.decode(String source) =>
      AudioFile.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AudioFile &&
        other.path == path &&
        other.duration == duration &&
        _listEquals(other.waveformData, waveformData) &&
        other.transcription == transcription;
  }

  @override
  int get hashCode {
    return path.hashCode ^
        duration.hashCode ^
        (waveformData != null ? _listHashCode(waveformData!) : 0) ^
        (transcription != null ? transcription.hashCode : 0);
  }

  @override
  String toString() {
    return 'AudioFile(path: $path, duration: $duration, '
        'waveformData: ${waveformData != null ? '${waveformData!.length} points' : 'null'}, '
        'transcription: ${transcription != null ? '${transcription!.substring(0, transcription!.length > 20 ? 20 : transcription!.length)}...' : 'null'})';
  }

  /// Helper method to compare two lists for equality.
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }

  /// Helper method to calculate a hash code for a list.
  int _listHashCode<T>(List<T> list) {
    return list.fold(0, (hash, item) => hash ^ item.hashCode);
  }
}
