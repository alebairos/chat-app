import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/audio_file.dart';
import 'audio_generation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../utils/logger.dart';

/// Class to hold API status information
class APIStatus {
  final bool isValid;
  final String message;
  final bool shouldUseFallback;

  APIStatus(
      {required this.isValid,
      required this.message,
      required this.shouldUseFallback});
}

/// A service that converts text to speech using ElevenLabs' cloud API.
///
/// This service implements the [AudioGeneration] interface and uses
/// ElevenLabs' API to generate high-quality, natural-sounding voices.
class ElevenLabsTTSService implements AudioGeneration {
  /// The base URL for the ElevenLabs API
  static const String _baseUrl = 'https://api.elevenlabs.io/v1';

  /// The API key for accessing ElevenLabs
  late final String _apiKey;

  /// The voice ID to use for text-to-speech
  late final String _voiceId;

  /// Flag indicating whether the service has been initialized
  bool _initialized = false;

  /// Directory where generated audio files are stored
  late final Directory _audioDirectory;

  /// Flag indicating whether we're running in a test environment
  bool _isTestMode = false;

  /// Creates a new [ElevenLabsTTSService] instance.
  ElevenLabsTTSService();

  @override
  bool get isInitialized => _initialized;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      logDebugPrint('Initializing ElevenLabsTTSService');

      // Load API key from environment variables
      _apiKey = dotenv.env['ELEVEN_LABS_API_KEY'] ?? '';

      // Log API key status (safely)
      if (_apiKey.isNotEmpty) {
        final maskedKey =
            "${_apiKey.substring(0, 5)}...${_apiKey.substring(_apiKey.length - 4)}";
        logDebugPrint('ElevenLabs API key loaded: Key found ($maskedKey)');
      } else {
        logDebugPrint('ElevenLabs API key not found in environment variables');
        if (!_isTestMode) {
          logDebugPrint(
              'WARNING: No API key found and not in test mode. Audio generation will use fallback audio.');
        }
      }

      // Validate API key format (should start with "sk_")
      if (!_apiKey.startsWith('sk_') && !_isTestMode && _apiKey.isNotEmpty) {
        logDebugPrint(
            'WARNING: ElevenLabs API key appears to be invalid (should start with "sk_")');
        // We'll continue anyway, but log the warning
      }

      // Use a default voice ID or load from environment
      _voiceId = dotenv.env['ELEVEN_LABS_VOICE_ID'] ?? 'EXAVITQu4vr4xnSDxMaL';
      logDebugPrint('ElevenLabs Voice ID: $_voiceId');

      // Create directory for storing audio files
      final appDir = await getApplicationDocumentsDirectory();
      _audioDirectory = Directory(path.join(appDir.path, 'eleven_labs_audio'));
      logDebugPrint('Audio directory path: ${_audioDirectory.path}');

      if (!await _audioDirectory.exists()) {
        await _audioDirectory.create(recursive: true);
        logDebugPrint('Created audio directory');
      } else {
        logDebugPrint('Audio directory already exists');
      }

      // Check API status and credit balance if not in test mode
      if (!_isTestMode && _apiKey.isNotEmpty) {
        final apiStatus = await _checkAPIStatus();
        if (!apiStatus.isValid) {
          logDebugPrint(
              'WARNING: ElevenLabs API issues detected: ${apiStatus.message}');
          if (apiStatus.shouldUseFallback) {
            logDebugPrint('Will use fallback audio due to API issues');
            _isTestMode = true; // Force test mode to use fallback
          }
        } else {
          logDebugPrint('ElevenLabs API status: ${apiStatus.message}');
        }
      }

      _initialized = true;
      logDebugPrint('ElevenLabsTTSService initialized successfully');
      return true;
    } catch (e) {
      logDebugPrint('Failed to initialize ElevenLabsTTSService: $e');
      return false;
    }
  }

  /// Checks the API status and credit balance
  /// Returns a status object with information about the API
  Future<APIStatus> _checkAPIStatus() async {
    try {
      logDebugPrint('Checking ElevenLabs API status and credit balance...');

      // First check if the API key is valid by making a request to the voices endpoint
      final voicesResponse = await http.get(
        Uri.parse('$_baseUrl/voices'),
        headers: {
          'xi-api-key': _apiKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (voicesResponse.statusCode != 200) {
        return APIStatus(
            isValid: false,
            message: 'API key validation failed: ${voicesResponse.statusCode}',
            shouldUseFallback: true);
      }

      // Check if we have access to the voice ID
      try {
        final voicesData = jsonDecode(voicesResponse.body);
        final voices = voicesData['voices'] as List<dynamic>?;

        if (voices != null) {
          final voiceExists =
              voices.any((voice) => voice['voice_id'] == _voiceId);
          if (!voiceExists) {
            return APIStatus(
                isValid: true,
                message: 'API key valid but voice ID $_voiceId not found',
                shouldUseFallback: false);
          }
        }
      } catch (e) {
        logDebugPrint('Error parsing voices response: $e');
      }

      // Check user subscription and credit balance
      final userResponse = await http.get(
        Uri.parse('$_baseUrl/user/subscription'),
        headers: {
          'xi-api-key': _apiKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (userResponse.statusCode != 200) {
        return APIStatus(
            isValid: true,
            message:
                'Could not check subscription status: ${userResponse.statusCode}',
            shouldUseFallback: false);
      }

      try {
        final userData = jsonDecode(userResponse.body);
        final tier = userData['tier'] as String?;
        final characterCount = userData['character_count'] as int?;
        final characterLimit = userData['character_limit'] as int?;

        if (characterCount != null && characterLimit != null) {
          final percentUsed = (characterCount / characterLimit) * 100;

          if (percentUsed >= 90) {
            return APIStatus(
                isValid: true,
                message:
                    'API credits low: $percentUsed% used ($characterCount/$characterLimit characters)',
                shouldUseFallback: percentUsed >= 99);
          }

          return APIStatus(
              isValid: true,
              message:
                  'API status good: $tier tier, $percentUsed% used ($characterCount/$characterLimit characters)',
              shouldUseFallback: false);
        }

        return APIStatus(
            isValid: true,
            message: 'API key valid, subscription tier: $tier',
            shouldUseFallback: false);
      } catch (e) {
        logDebugPrint('Error parsing user subscription data: $e');
        return APIStatus(
            isValid: true,
            message: 'API key valid but could not parse subscription data',
            shouldUseFallback: false);
      }
    } catch (e) {
      logDebugPrint('Error checking API status: $e');
      return APIStatus(
          isValid: false,
          message: 'Error checking API status: $e',
          shouldUseFallback: true);
    }
  }

  @override
  Future<AudioFile> generate(String text) async {
    if (!_initialized) {
      logDebugPrint('ElevenLabsTTSService not initialized');
      throw Exception('ElevenLabsTTSService not initialized');
    }

    // Generate a unique ID for this request to track it through logs
    final requestId =
        DateTime.now().millisecondsSinceEpoch.toString().substring(6);

    logDebugPrint(
        '[$requestId] Generating audio for text: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');

    try {
      // Generate a unique filename that includes a hash of the text to ensure uniqueness
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final textHash = text.hashCode.abs().toString().substring(0, 4);
      final filename = 'eleven_labs_${timestamp}_${textHash}.mp3';
      final filePath = path.join(_audioDirectory.path, filename);
      logDebugPrint('[$requestId] Generated file path: $filePath');

      // If in test mode or API key is empty, return a mock audio file
      if (_isTestMode || _apiKey.isEmpty) {
        logDebugPrint(
            '[$requestId] ${_isTestMode ? "Test mode enabled" : "No API key"}, returning mock audio file');
        return await _useMockAudio(filePath, text, requestId);
      }

      // Check API status before making the request
      final apiStatus = await _checkAPIStatus();
      if (!apiStatus.isValid || apiStatus.shouldUseFallback) {
        logDebugPrint(
            '[$requestId] API issues detected: ${apiStatus.message}, using fallback audio');
        return await _useMockAudio(filePath, text, requestId);
      }

      // Use the current voice ID
      String voiceId = _voiceId;
      logDebugPrint('[$requestId] Using voice ID: $voiceId');

      // Try up to 3 times to generate audio
      int retryCount = 0;
      const maxRetries = 2; // Total of 3 attempts (initial + 2 retries)

      // Calculate exponential backoff delays
      final retryDelays = [
        const Duration(seconds: 1),
        const Duration(seconds: 3),
        const Duration(seconds: 7),
      ];

      while (retryCount <= maxRetries) {
        try {
          logDebugPrint(
              '[$requestId] Making API request to ElevenLabs with voice ID: $voiceId (attempt ${retryCount + 1}/${maxRetries + 1})');

          // Make API request to ElevenLabs
          final url = '$_baseUrl/text-to-speech/$voiceId/stream';
          logDebugPrint('[$requestId] API URL: $url');

          final client = http.Client();
          try {
            final response = await client
                .post(
                  Uri.parse(url),
                  headers: {
                    'Accept': 'audio/mpeg',
                    'Content-Type': 'application/json',
                    'xi-api-key': _apiKey,
                  },
                  body: jsonEncode({
                    'text': text,
                    'model_id': 'eleven_monolingual_v1',
                    'voice_settings': {
                      'stability': 0.5,
                      'similarity_boost': 0.75,
                    },
                  }),
                )
                .timeout(const Duration(seconds: 30));

            logDebugPrint(
                '[$requestId] ElevenLabs API response status code: ${response.statusCode}');

            if (response.statusCode != 200) {
              logDebugPrint(
                  '[$requestId] ElevenLabs API error: ${response.statusCode} ${response.body}');

              // Handle specific error codes
              if (response.statusCode == 401) {
                logDebugPrint('[$requestId] API key is invalid or expired');
                return await _useMockAudio(filePath, text, requestId);
              } else if (response.statusCode == 429) {
                logDebugPrint(
                    '[$requestId] Rate limit exceeded or out of credits');
                return await _useMockAudio(filePath, text, requestId);
              }

              // If we've exhausted retries, throw an exception
              if (retryCount == maxRetries) {
                throw Exception(
                    'Failed to generate audio after ${retryCount + 1} attempts: ${response.statusCode} - ${response.body}');
              }

              // Otherwise, retry with exponential backoff
              retryCount++;
              final delay = retryDelays[retryCount - 1];
              logDebugPrint(
                  '[$requestId] Retrying in ${delay.inSeconds} seconds...');
              await Future.delayed(delay);
              continue;
            }

            logDebugPrint(
                '[$requestId] ElevenLabs API request successful, saving audio file');
            // Save the audio data to a file
            final file = File(filePath);
            await file.writeAsBytes(response.bodyBytes);

            // Verify the file exists and has content
            final exists = await file.exists();
            final fileSize = await file.length();

            logDebugPrint(
                '[$requestId] File exists: $exists, size: $fileSize bytes');

            if (!exists || fileSize == 0) {
              logDebugPrint(
                  '[$requestId] Failed to save audio file or file is empty');

              // If we've exhausted retries, fall back to mock audio
              if (retryCount == maxRetries) {
                return await _useMockAudio(filePath, text, requestId);
              }

              // Otherwise, retry with exponential backoff
              retryCount++;
              final delay = retryDelays[retryCount - 1];
              logDebugPrint(
                  '[$requestId] Retrying in ${delay.inSeconds} seconds...');
              await Future.delayed(delay);
              continue;
            }

            // Calculate a more accurate duration based on file size and average bitrate
            // MP3 files from ElevenLabs are typically around 32kbps
            // This gives a more accurate estimate than word count
            const averageBitrateKbps = 32;
            final estimatedDurationMs =
                (fileSize * 8 / (averageBitrateKbps * 1000) * 1000).round();

            // Add a small buffer to account for any silence at the beginning/end
            final adjustedDurationMs = (estimatedDurationMs * 1.05).round();

            logDebugPrint(
                '[$requestId] Estimated duration based on file size: ${Duration(milliseconds: adjustedDurationMs)}');

            final audioFile = AudioFile(
              path: filePath,
              duration: Duration(milliseconds: adjustedDurationMs),
            );

            logDebugPrint(
                '[$requestId] ElevenLabs audio generated successfully: ${audioFile.path}');
            return audioFile;
          } finally {
            client.close();
          }
        } catch (e) {
          logDebugPrint(
              '[$requestId] Error during attempt ${retryCount + 1}: $e');

          // If we've exhausted retries, fall back to mock audio
          if (retryCount == maxRetries) {
            logDebugPrint(
                '[$requestId] Failed to generate audio after ${retryCount + 1} attempts, falling back to mock audio');
            break;
          }

          // Otherwise, retry with exponential backoff
          retryCount++;
          final delay = retryDelays[retryCount - 1];
          logDebugPrint(
              '[$requestId] Retrying in ${delay.inSeconds} seconds...');
          await Future.delayed(delay);
        }
      }

      // If we get here, all attempts failed, so fall back to mock audio
      logDebugPrint(
          '[$requestId] All attempts to generate audio failed, using mock audio');
      final fallbackFilename =
          'eleven_labs_fallback_${DateTime.now().millisecondsSinceEpoch}_${textHash}.aiff';
      final fallbackFilePath =
          path.join(_audioDirectory.path, fallbackFilename);
      return await _useMockAudio(fallbackFilePath, text, requestId);
    } catch (e) {
      logDebugPrint(
          '[$requestId] Failed to generate audio with ElevenLabs: $e');

      // Fall back to mock audio in case of error
      final textHash = text.hashCode.abs().toString().substring(0, 4);
      final filename =
          'eleven_labs_fallback_${DateTime.now().millisecondsSinceEpoch}_${textHash}.aiff';
      final filePath = path.join(_audioDirectory.path, filename);
      return await _useMockAudio(filePath, text, requestId);
    }
  }

  /// Uses a mock audio file for testing or fallback purposes.
  Future<AudioFile> _useMockAudio(
      String targetPath, String text, String requestId) async {
    logDebugPrint(
        '[$requestId] Using mock audio file as fallback or for testing');
    try {
      // Determine which sample to use based on text length
      final assetPath = text.length > 100
          ? 'assets/audio/assistant_response.aiff'
          : 'assets/audio/welcome_message.aiff';
      logDebugPrint(
          '[$requestId] Selected mock audio asset: $assetPath based on text length: ${text.length}');

      // For test mode, return the asset path directly
      if (_isTestMode) {
        logDebugPrint(
            '[$requestId] Using mock audio directly from assets: $assetPath (test mode)');

        final duration = assetPath.contains('welcome_message')
            ? const Duration(seconds: 3)
            : const Duration(seconds: 14);

        return AudioFile(
          path: assetPath,
          duration: duration,
        );
      }

      // For real devices, copy the asset to a file
      String correctedTargetPath = targetPath;
      if (!correctedTargetPath.endsWith('.aiff')) {
        correctedTargetPath =
            targetPath.replaceAll(RegExp(r'\.[^.]*$'), '.aiff');
        logDebugPrint(
            '[$requestId] Corrected target path to use .aiff extension: $correctedTargetPath');
      }

      final file = File(correctedTargetPath);
      logDebugPrint('[$requestId] Creating mock audio file at: ${file.path}');

      // Read the asset file
      final byteData = await rootBundle.load(assetPath);
      final buffer = byteData.buffer;
      logDebugPrint(
          '[$requestId] Loaded asset file with size: ${byteData.lengthInBytes} bytes');

      // Write to the target path
      await file.writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      logDebugPrint('[$requestId] Written mock audio file to disk');

      // Get the actual file size to calculate a more accurate duration
      final fileSize = await file.length();

      // For AIFF files, calculate duration based on file size
      // AIFF files are typically uncompressed PCM at 16-bit, 44.1kHz, mono
      // This gives a more accurate duration than the hardcoded values
      final bitRate = 705600; // 44100 * 16 * 1 / 8 bytes per second
      final calculatedDurationMs = (fileSize / bitRate * 1000).round();

      // Use the calculated duration, but with a minimum based on the asset type
      final minDuration = assetPath.contains('welcome_message')
          ? const Duration(seconds: 3)
          : const Duration(seconds: 10);

      final duration = calculatedDurationMs > minDuration.inMilliseconds
          ? Duration(milliseconds: calculatedDurationMs)
          : minDuration;

      logDebugPrint(
          '[$requestId] Calculated mock audio duration: $duration (file size: $fileSize bytes)');

      logDebugPrint(
          '[$requestId] Returning mock AudioFile with path: ${file.path} and duration: $duration');
      return AudioFile(
        path: correctedTargetPath,
        duration: duration,
      );
    } catch (e) {
      logDebugPrint('[$requestId] Error using mock audio: $e');
      throw Exception('Failed to use mock audio: $e');
    }
  }

  @override
  Future<void> cleanup() async {
    if (!_initialized) return;

    try {
      // Delete files older than 24 hours
      final now = DateTime.now();
      final files = await _audioDirectory.list().toList();

      for (var entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          final fileAge = now.difference(stat.modified);

          if (fileAge.inHours > 24) {
            await entity.delete();
          }
        }
      }

      logDebugPrint('ElevenLabsTTSService cleanup completed');
    } catch (e) {
      logDebugPrint('Error during ElevenLabsTTSService cleanup: $e');
    }
  }

  /// Enable test mode for testing
  void enableTestMode() {
    _isTestMode = true;
    logDebugPrint('ElevenLabsTTSService test mode enabled');
  }

  /// Disable test mode to use the real API
  void disableTestMode() {
    _isTestMode = false;
    logDebugPrint('ElevenLabsTTSService test mode disabled');
  }

  /// Set a custom voice ID
  void setVoiceId(String voiceId) {
    if (voiceId.isNotEmpty) {
      _voiceId = voiceId;
      logDebugPrint('ElevenLabs voice ID set to: $_voiceId');
    }
  }
}
