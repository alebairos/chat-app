import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../utils/logger.dart';
import '../../../utils/language_utils.dart';
import 'tts_provider.dart';
import 'tts_text_processor.dart';
import 'emotional_tone_mapper.dart';

/// Implementation of [TTSProvider] using Eleven Labs Text-to-Speech API.
class ElevenLabsProvider implements TTSProvider {
  final Logger _logger = Logger();
  final String _baseUrl = 'https://api.elevenlabs.io/v1';
  late String _apiKey;
  late Map<String, dynamic> _configuration;
  bool _isInitialized = false;

  /// Creates a new [ElevenLabsProvider] instance.
  ElevenLabsProvider() {
    _configuration = {
      'voiceId': 'pNInz6obpgDQGcFmaJgB', // Default voice ID
      'modelId': 'eleven_monolingual_v1', // Default model ID
      'stability': 0.5,
      'similarityBoost': 0.75,
      'style': 0.0,
      'speakerBoost': true,
      'useAuthFromEnv': true,
      'apply_text_normalization':
          'auto', // Default to auto mode for optimal balance
    };
  }

  @override
  String get name => 'ElevenLabs';

  @override
  Map<String, dynamic> get config => Map.from(_configuration);

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (_configuration['useAuthFromEnv'] == true) {
        // Try both formats of environment variable names
        _apiKey = dotenv.env['ELEVEN_LABS_API_KEY'] ??
            dotenv.env['ELEVENLABS_API_KEY'] ??
            '';

        if (_apiKey.isEmpty) {
          _logger.error('ElevenLabs API key not found in .env file');
          return false;
        }

        // Also check for voice ID in environment
        final envVoiceId = dotenv.env['ELEVEN_LABS_VOICE_ID'] ??
            dotenv.env['ELEVENLABS_VOICE_ID'];
        if (envVoiceId != null && envVoiceId.isNotEmpty) {
          _configuration['voiceId'] = envVoiceId;
        }
      } else {
        _apiKey = _configuration['apiKey'] ?? '';
        if (_apiKey.isEmpty) {
          _logger.error('ElevenLabs API key not provided in configuration');
          return false;
        }
      }

      // Verify the API key with a simple request to the voices endpoint
      final response = await http.get(
        Uri.parse('$_baseUrl/voices'),
        headers: {
          'Accept': 'application/json',
          'xi-api-key': _apiKey,
        },
      );

      if (response.statusCode != 200) {
        _logger.error('Failed to verify ElevenLabs API key: ${response.body}');
        return false;
      }

      _isInitialized = true;
      _logger.debug('ElevenLabs TTS Provider initialized successfully');
      return true;
    } catch (e) {
      _logger.error('Failed to initialize ElevenLabs TTS Provider: $e');
      return false;
    }
  }

  @override
  Future<bool> generateSpeech(String text, String outputPath) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return false;
      }
    }

    try {
      // Extract emotional context before processing text
      final emotionalTone = EmotionalToneMapper.extractEmotionalTone(text);

      // Standard preprocessing to remove narrative elements and formatting
      final processedText = TTSTextProcessor.processForTTS(text);

      // Log the standard processing for debugging (only if text was changed)
      if (TTSTextProcessor.containsFormattingElements(text)) {
        _logger.debug(
            'TTS Text Processing - Original length: ${text.length}, Processed length: ${processedText.length}');
        _logger.debug(
            'TTS Text Processing - Removed formatting elements from text');
      }

      // Log emotional tone adjustments
      if (EmotionalToneMapper.hasEmotionalContext(text)) {
        _logger.debug(
            'TTS Emotional Tone - ${EmotionalToneMapper.getEmotionalDescription(text)}');
        _logger.debug('TTS Emotional Tone - Voice adjustments: $emotionalTone');
      }

      final voiceId = _configuration['voiceId'];
      final modelId = _configuration['modelId'];

      // Apply emotional tone adjustments to voice settings
      final voiceSettings = {
        'stability': emotionalTone['stability'] ?? _configuration['stability'],
        'similarity_boost': emotionalTone['similarity_boost'] ??
            _configuration['similarityBoost'],
        'style': emotionalTone['style'] ?? _configuration['style'],
        'speaker_boost':
            emotionalTone['speaker_boost'] ?? _configuration['speakerBoost'],
      };

      final requestBody = {
        'text': processedText, // Use processed text instead of original
        'model_id': modelId,
        'voice_settings': voiceSettings,
        'apply_text_normalization':
            _getTextNormalizationMode(), // FT-120: Text normalization
      };

      // FT-132: Add language_code parameter for optimal TTS processing
      final languageCode = _getLanguageCode();
      if (languageCode != null) {
        requestBody['language_code'] = languageCode;
        _logger.debug('ElevenLabs: Using language_code: $languageCode');
      }

      _logger.debug(
          'Generating speech with ElevenLabs: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/text-to-speech/$voiceId'),
        headers: {
          'Accept': 'audio/mpeg',
          'xi-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        _logger.error('Failed to generate speech: ${response.body}');
        return false;
      }

      // Save the audio data to the specified file
      final file = File(outputPath);
      await file.writeAsBytes(response.bodyBytes);

      _logger.debug('Generated audio file saved to: $outputPath');
      return true;
    } catch (e) {
      _logger.error('Failed to generate speech: $e');
      return false;
    }
  }

  @override
  Future<bool> updateConfig(Map<String, dynamic> newConfig) async {
    try {
      _configuration.addAll(newConfig);

      // If API key is updated, reset initialization
      if (newConfig.containsKey('apiKey') ||
          newConfig.containsKey('useAuthFromEnv')) {
        _isInitialized = false;
      }

      _logger.debug('Updated ElevenLabs TTS Provider configuration');
      return true;
    } catch (e) {
      _logger
          .error('Failed to update ElevenLabs TTS Provider configuration: $e');
      return false;
    }
  }

  /// Get text normalization mode based on configuration and model compatibility
  String _getTextNormalizationMode() {
    final configuredMode = _configuration['apply_text_normalization'] ?? 'auto';
    final modelId = _configuration['modelId'] ?? '';

    // Flash v2.5 and Turbo v2.5 only support 'off' or 'auto'
    if (modelId.contains('flash_v2_5') || modelId.contains('turbo_v2_5')) {
      if (configuredMode == 'on') {
        _logger
            .debug('Text normalization: Fallback to "auto" for model $modelId');
        return 'auto';
      }
    }

    _logger.debug(
        'Text normalization: Using mode "$configuredMode" for model $modelId');
    return configuredMode;
  }

  /// Get language code for ElevenLabs API based on detected language
  ///
  /// Uses centralized language mapping for consistency across services.
  String? _getLanguageCode() {
    final detectedLanguage = _configuration['detectedLanguage'] as String?;
    // FT-132: Use centralized language code mapping
    return LanguageUtils.normalizeToLanguageCode(detectedLanguage);
  }

  @override
  Future<void> dispose() async {
    // Nothing to clean up for this provider
    _isInitialized = false;
  }
}
