import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../utils/logger.dart';
import '../../utils/path_utils.dart';
import 'services/tts_provider.dart';
import 'services/eleven_labs_provider.dart';
import 'services/mock_tts_provider.dart';

/// Service responsible for converting text to speech.
///
/// This class provides text-to-speech functionality for the assistant,
/// allowing it to generate audio responses that can be played back to the user.
class AudioAssistantTTSService {
  final Logger _logger = Logger();
  bool _isInitialized = false;
  bool _isTestMode = false;
  static const String _audioDir = 'audio_assistant';

  /// Flag to enable/disable the audio assistant feature
  static bool featureEnabled = true;

  /// Currently active TTS provider
  late TTSProvider _provider;

  /// List of available TTS providers
  final Map<String, TTSProvider> _availableProviders = {};

  /// Creates a new [AudioAssistantTTSService] instance.
  AudioAssistantTTSService() {
    // Register available providers
    _registerProviders();

    // Default to Eleven Labs if not in test mode
    _provider = _isTestMode
        ? _availableProviders['MockTTS']!
        : _availableProviders['ElevenLabs']!;
  }

  /// Register available TTS providers
  void _registerProviders() {
    _availableProviders['ElevenLabs'] = ElevenLabsProvider();
    _availableProviders['MockTTS'] = MockTTSProvider();
  }

  /// Get the list of available provider names
  List<String> get availableProviders => _availableProviders.keys.toList();

  /// Get the name of the current provider
  String get currentProviderName => _provider.name;

  /// Switch to a different TTS provider
  ///
  /// [providerName] The name of the provider to switch to
  /// Returns true if the switch was successful, false otherwise
  Future<bool> switchProvider(String providerName) async {
    if (!_availableProviders.containsKey(providerName)) {
      _logger.error('TTS provider "$providerName" not found');
      return false;
    }

    _provider = _availableProviders[providerName]!;
    _isInitialized = false; // Reset initialization

    _logger.debug('Switched to TTS provider: $providerName');
    return true;
  }

  /// Get the configuration of the current provider
  Map<String, dynamic> get providerConfig => _provider.config;

  /// Update the configuration of the current provider
  ///
  /// [newConfig] The new configuration options to apply
  /// Returns true if the configuration was updated successfully, false otherwise
  Future<bool> updateProviderConfig(Map<String, dynamic> newConfig) async {
    return _provider.updateConfig(newConfig);
  }

  /// Initialize the TTS service
  Future<bool> initialize() async {
    if (!_isInitialized) {
      try {
        // Initialize the provider
        final providerInitialized = await _provider.initialize();
        if (!providerInitialized) {
          _logger.error('Failed to initialize TTS provider: ${_provider.name}');
          return false;
        }

        if (!_isTestMode && featureEnabled) {
          // Create the audio directory if it doesn't exist
          final dir = await getApplicationDocumentsDirectory();
          final audioDir = Directory('${dir.path}/$_audioDir');
          if (!await audioDir.exists()) {
            await audioDir.create(recursive: true);
          }
        }

        _isInitialized = true;
        _logger.debug('Audio Assistant TTS Service initialized successfully');
        return true;
      } catch (e) {
        _logger.error('Failed to initialize Audio Assistant TTS Service: $e');
        return false;
      }
    }
    return true;
  }

  /// Convert text to speech and return the path to the audio file
  ///
  /// [text] The text to convert to speech
  /// Returns a relative path to the generated audio file
  Future<String?> generateAudio(String text) async {
    // Return null if feature is disabled (but allow in test mode)
    if (!featureEnabled && !_isTestMode) {
      _logger.debug('Audio Assistant feature is disabled');
      return null;
    }

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        _logger
            .error('Failed to initialize TTS service before generating audio');
        return null;
      }
    }

    try {
      if (_isTestMode) {
        return '$_audioDir/test_audio_assistant_${DateTime.now().millisecondsSinceEpoch}.mp3';
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'audio_assistant_$timestamp.mp3';
      final relativePath = '$_audioDir/$fileName';
      final absolutePath = '${dir.path}/$relativePath';

      // Generate the audio file using the current provider
      final success = await _provider.generateSpeech(text, absolutePath);

      if (!success) {
        _logger
            .error('Failed to generate audio with provider: ${_provider.name}');
        return null;
      }

      _logger.debug('Generated audio assistant audio file at: $absolutePath');
      // Return the relative path for storage
      return relativePath;
    } catch (e) {
      _logger.error('Failed to generate audio assistant audio: $e');
      return null;
    }
  }

  /// Clean up any temporary audio files
  Future<void> cleanup() async {
    if (!featureEnabled && !_isTestMode) {
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${dir.path}/$_audioDir');
      if (await audioDir.exists()) {
        final files = audioDir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.mp3'));

        for (final file in files) {
          await file.delete();
        }
      }

      _logger.debug('Cleaned up audio assistant temporary audio files');
    } catch (e) {
      _logger.error('Failed to cleanup audio assistant audio files: $e');
    }
  }

  /// Delete a specific audio file
  ///
  /// [relativePath] The relative path to the audio file to delete
  Future<bool> deleteAudio(String relativePath) async {
    if (!featureEnabled && !_isTestMode) {
      return false;
    }

    try {
      final absolutePath = await PathUtils.relativeToAbsolute(relativePath);
      if (absolutePath == null) {
        _logger.error(
            'Failed to convert relative path to absolute path: $relativePath');
        return false;
      }

      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
        _logger.debug('Deleted audio file at: $absolutePath');
        return true;
      } else {
        _logger.debug('Audio file not found at: $absolutePath');
        return false;
      }
    } catch (e) {
      _logger.error('Failed to delete audio file: $e');
      return false;
    }
  }

  /// Enable test mode for testing
  void enableTestMode() {
    _isTestMode = true;
    switchProvider('MockTTS');
  }

  /// Disable test mode
  void disableTestMode() {
    _isTestMode = false;
    switchProvider('ElevenLabs');
  }

  /// Dispose of resources used by the service
  Future<void> dispose() async {
    for (final provider in _availableProviders.values) {
      await provider.dispose();
    }
  }
}
