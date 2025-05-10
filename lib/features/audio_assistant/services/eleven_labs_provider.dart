import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../utils/logger.dart';
import 'tts_provider.dart';

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
        _apiKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
        if (_apiKey.isEmpty) {
          _logger.error('ElevenLabs API key not found in .env file');
          return false;
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
      final voiceId = _configuration['voiceId'];
      final modelId = _configuration['modelId'];

      final voiceSettings = {
        'stability': _configuration['stability'],
        'similarity_boost': _configuration['similarityBoost'],
        'style': _configuration['style'],
        'speaker_boost': _configuration['speakerBoost'],
      };

      final requestBody = {
        'text': text,
        'model_id': modelId,
        'voice_settings': voiceSettings,
      };

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

  @override
  Future<void> dispose() async {
    // Nothing to clean up for this provider
    _isInitialized = false;
  }
}
