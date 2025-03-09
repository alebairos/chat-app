import '../models/audio_file.dart';

/// Interface for services that generate audio from text.
///
/// This interface defines the contract for any service that converts
/// text to speech, allowing for different implementations (e.g., local TTS,
/// cloud-based TTS, or mock implementations for testing).
abstract class AudioGeneration {
  /// Initializes the audio generation service.
  ///
  /// This method should be called before any other methods to ensure
  /// the service is properly set up. It returns a boolean indicating
  /// whether initialization was successful.
  Future<bool> initialize();

  /// Generates an audio file from the given text.
  ///
  /// Takes a [text] string and converts it to speech, returning an [AudioFile]
  /// object that contains the path to the generated audio file and its metadata.
  ///
  /// Throws an exception if the service is not initialized or if there's an error
  /// during audio generation.
  Future<AudioFile> generate(String text);

  /// Cleans up resources used by the audio generation service.
  ///
  /// This method should be called when the service is no longer needed
  /// to free up resources and delete temporary files.
  Future<void> cleanup();

  /// Checks if the service is initialized and ready to generate audio.
  bool get isInitialized;
}
