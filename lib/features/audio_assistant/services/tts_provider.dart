/// An interface that defines the contract for text-to-speech providers.
///
/// This abstraction allows easy switching between different TTS services
/// (Eleven Labs, Google, Amazon Polly, etc.) without changing the core application logic.
abstract class TTSProvider {
  /// The name of the provider (e.g., "ElevenLabs", "Google")
  String get name;

  /// Initialize the TTS provider with necessary configurations
  Future<bool> initialize();

  /// Convert text to speech and save it to a file
  ///
  /// [text] The text to convert to speech
  /// [outputPath] The absolute path where the audio file should be saved
  /// Returns true if the audio was successfully generated, false otherwise
  Future<bool> generateSpeech(String text, String outputPath);

  /// Get any provider-specific configuration options
  Map<String, dynamic> get config;

  /// Update provider-specific configuration options
  ///
  /// [newConfig] The new configuration options to apply
  /// Returns true if the configuration was updated successfully, false otherwise
  Future<bool> updateConfig(Map<String, dynamic> newConfig);

  /// Clean up resources used by the provider
  Future<void> dispose();
}
