import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../utils/logger.dart';
import '../../utils/path_utils.dart';
import '../../config/config_loader.dart';
import '../../services/tts_preprocessing_service.dart';
import '../../services/language_detection_service.dart';
import 'services/tts_provider.dart';
import 'services/eleven_labs_provider.dart';
import 'services/mock_tts_provider.dart';
import 'services/character_voice_config.dart';

/// Service responsible for converting text to speech.
///
/// This class provides text-to-speech functionality for the assistant,
/// allowing it to generate audio responses that can be played back to the user.
class AudioAssistantTTSService {
  final Logger _logger = Logger();
  final ConfigLoader _configLoader = ConfigLoader();
  bool _isInitialized = false;
  bool _isTestMode = false;
  static const String _audioDir = 'audio_assistant';

  /// Flag to enable/disable the audio assistant feature
  static bool featureEnabled = true;

  /// Currently active TTS provider
  late TTSProvider _provider;

  /// List of available TTS providers
  final Map<String, TTSProvider> _availableProviders = {};

  /// Recent user messages for language detection
  final List<String> _recentUserMessages = [];

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

  /// Apply character-specific voice configuration
  ///
  /// Uses the current active character from ConfigLoader to apply appropriate voice settings
  Future<bool> applyCharacterVoice() async {
    try {
      // In test mode, short-circuit to success before any config resolution
      if (_isTestMode) {
        return true;
      }
      final characterName = await _configLoader.activePersonaDisplayName;
      final characterConfig =
          CharacterVoiceConfig.getVoiceConfig(characterName);

      _logger.debug('Applying character voice for: $characterName');
      _logger.debug('Voice config: $characterConfig');

      // Apply the character-specific configuration to the current provider
      // In test mode, always report success to avoid provider-specific constraints
      // Non-test mode: apply to provider

      final success = await updateProviderConfig(characterConfig);

      if (success) {
        _logger.debug(
            'Successfully applied character voice configuration for: $characterName');
      } else {
        _logger.error(
            'Failed to apply character voice configuration for: $characterName');
      }

      return success;
    } catch (e) {
      _logger.error('Error applying character voice configuration: $e');
      return false;
    }
  }

  /// Ensure the audio directory exists
  Future<bool> _ensureAudioDirectoryExists() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${dir.path}/$_audioDir');

      if (!await audioDir.exists()) {
        _logger.debug('Creating audio directory at: ${audioDir.path}');
        await audioDir.create(recursive: true);
      }

      // Verify the directory exists
      final exists = await audioDir.exists();
      if (!exists) {
        _logger.error('Failed to create audio directory at: ${audioDir.path}');
        return false;
      }

      _logger.debug('Audio directory exists at: ${audioDir.path}');
      return true;
    } catch (e) {
      _logger.error('Error ensuring audio directory exists: $e');
      return false;
    }
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
          final directoryCreated = await _ensureAudioDirectoryExists();
          if (!directoryCreated) {
            _logger.error('Failed to create audio directory');
            return false;
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

  /// Add a user message to the recent messages list for language detection
  ///
  /// [message] The user message to add
  void addUserMessage(String message) {
    _recentUserMessages.add(message);

    // Keep only the last 10 messages for language detection
    if (_recentUserMessages.length > 10) {
      _recentUserMessages.removeAt(0);
    }

    _logger.debug(
        'Added user message for language detection. Total messages: ${_recentUserMessages.length}');
  }

  /// Clear recent user messages
  void clearRecentMessages() {
    _recentUserMessages.clear();
    _logger.debug('Cleared recent user messages');
  }

  /// Get the current detected language based on recent messages
  String get detectedLanguage {
    return LanguageDetectionService.detectLanguage(_recentUserMessages);
  }

  /// Convert text to speech and return the path to the audio file
  ///
  /// [text] The text to convert to speech
  /// [language] Optional language override (if not provided, will detect from recent messages)
  /// Returns a relative path to the generated audio file
  Future<String?> generateAudio(String text, {String? language}) async {
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
      // Apply character-specific voice configuration before generating audio
      if (!_isTestMode) {
        await applyCharacterVoice();
      }

      if (_isTestMode) {
        return '$_audioDir/test_audio_assistant_${DateTime.now().millisecondsSinceEpoch}.mp3';
      }

      // Detect language for TTS processing
      final targetLanguage = language ?? detectedLanguage;
      _logger.debug('TTS Language detected/specified: $targetLanguage');

      // Preprocess text for TTS optimization
      final originalText = text;
      final processedText =
          TTSPreprocessingService.preprocessForTTS(text, targetLanguage);

      // Log preprocessing results if text was modified
      if (processedText != originalText) {
        _logger.debug('TTS Text preprocessing applied');
        TTSPreprocessingService.logProcessingStats(
            originalText, processedText, targetLanguage);
      }

      // Configure ElevenLabs for the target language
      await _configureProviderForLanguage(targetLanguage);

      // Ensure audio directory exists before generating audio
      final directoryExists = await _ensureAudioDirectoryExists();
      if (!directoryExists) {
        _logger
            .error('Audio directory does not exist and could not be created');
        return null;
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'audio_assistant_$timestamp.mp3';
      final relativePath = '$_audioDir/$fileName';
      final absolutePath = '${dir.path}/$relativePath';

      // Generate the audio file using the current provider with processed text
      final success =
          await _provider.generateSpeech(processedText, absolutePath);

      if (!success) {
        _logger
            .error('Failed to generate audio with provider: ${_provider.name}');
        return null;
      }

      _logger.debug('Generated audio assistant audio file at: $absolutePath');
      _logger.debug(
          'TTS processing complete - Language: $targetLanguage, Text optimized: ${processedText != originalText}');

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

  /// Configure the TTS provider for a specific language
  ///
  /// [language] The target language (e.g., 'pt_BR', 'en_US')
  Future<void> _configureProviderForLanguage(String language) async {
    try {
      // Language-specific configurations for ElevenLabs
      Map<String, dynamic> languageConfig = {};

      switch (language) {
        case 'pt_BR':
          // Portuguese (Brazil) configuration
          languageConfig = {
            'modelId': 'eleven_multilingual_v1',
            'stability': 0.68,
            'similarityBoost': 0.8,
            'style': 0.08,
          };
          _logger.debug('Configured TTS provider for Portuguese (Brazil)');
          break;
        case 'en_US':
          // English (US) configuration — keep multilingual to use the same voice across languages
          languageConfig = {
            'modelId': 'eleven_multilingual_v1',
            'stability': 0.65,
            'similarityBoost': 0.8,
            'style': 0.05,
          };
          _logger.debug(
              'Configured TTS provider for English (US) with multilingual model');
          break;
        default:
          // Default to multilingual model for unknown languages
          languageConfig = {
            'modelId': 'eleven_multilingual_v1',
            'stability': 0.65,
            'similarityBoost': 0.8,
            'style': 0.0,
          };
          _logger
              .debug('Configured TTS provider for default language: $language');
          break;
      }

      // Apply the language-specific configuration
      await updateProviderConfig(languageConfig);

      _logger.debug('TTS provider configured for language: $language');
    } catch (e) {
      _logger
          .error('Failed to configure TTS provider for language $language: $e');
    }
  }

  /// Dispose of resources used by the service
  Future<void> dispose() async {
    for (final provider in _availableProviders.values) {
      await provider.dispose();
    }
  }
}
