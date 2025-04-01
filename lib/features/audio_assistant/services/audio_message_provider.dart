import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/audio_file.dart';
import '../../../services/chat_storage_service.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/message_type.dart';
import '../../../utils/logger.dart';
import 'audio_generation.dart';
import 'audio_playback.dart';
import 'audio_playback_controller.dart';
import 'audio_playback_manager.dart';
import 'tts_service_factory.dart';

/// A provider that manages audio messages for the assistant.
///
/// This class coordinates between the text-to-speech service and audio playback,
/// handling the conversion of text responses to audio and managing the audio files.
class AudioMessageProvider extends ChangeNotifier {
  /// The service used to generate audio from text.
  final AudioGeneration _audioGeneration;

  /// The service used to play audio files.
  AudioPlayback? _audioPlayback;

  /// Whether the provider has been initialized.
  bool _initialized = false;

  /// A map of message IDs to their corresponding audio files.
  final Map<String, AudioFile> _audioFiles = {};

  /// Map of message IDs to timestamps
  final Map<String, int> _messageTimestamps = {};

  /// Creates a new [AudioMessageProvider] instance.
  ///
  /// [audioGeneration] is the service used to generate audio from text.
  /// If not provided, it will be created using the TTSServiceFactory.
  /// [audioPlayback] is the service used to play audio files.
  AudioMessageProvider({
    AudioGeneration? audioGeneration,
    AudioPlayback? audioPlayback,
  })  : _audioGeneration =
            audioGeneration ?? TTSServiceFactory.createTTSService(),
        _audioPlayback = audioPlayback;

  /// Whether the provider has been initialized.
  bool get isInitialized => _initialized;

  /// Get the current TTS service type
  TTSServiceType get ttsServiceType => TTSServiceFactory.activeServiceType;

  /// Get the current audio generation service
  AudioGeneration getAudioGenerationService() {
    return _audioGeneration;
  }

  /// Change the TTS service type
  ///
  /// This will reinitialize the provider with the new service type.
  /// Returns true if the change was successful, false otherwise.
  Future<bool> changeTTSServiceType(TTSServiceType serviceType) async {
    if (serviceType == TTSServiceFactory.activeServiceType) {
      return true; // Already using this service type
    }

    // Set the new service type
    TTSServiceFactory.setActiveServiceType(serviceType);

    // Reset initialization flag
    _initialized = false;

    // Reinitialize with the new service
    return initialize();
  }

  /// Initializes the provider.
  ///
  /// This method initializes the audio generation and playback services.
  /// Returns true if initialization was successful, false otherwise.
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      final generationInitialized = await _audioGeneration.initialize();
      await _initializeAudioPlayback();

      // Load existing audio files from storage
      await _loadAudioFilesFromStorage();

      _initialized = generationInitialized;
      return _initialized;
    } catch (e) {
      logDebugPrint('Failed to initialize AudioMessageProvider: $e');
      return false;
    }
  }

  /// Initialize the audio playback controller
  Future<void> _initializeAudioPlayback() async {
    try {
      // We'll use the AudioPlaybackManager for all audio playback
      // but keep the _audioPlayback field for backward compatibility
      if (_audioPlayback == null) {
        // Create a new AudioPlaybackController for backward compatibility
        _audioPlayback = AudioPlaybackController();
        await _audioPlayback!.initialize();
      }

      // The actual playback will be handled by the AudioPlaybackManager
      logDebugPrint(
          'AudioMessageProvider: Using AudioPlaybackManager for playback');
    } catch (e) {
      logDebugPrint('Failed to initialize audio playback: $e');
    }
  }

  /// Load existing audio files from storage
  Future<void> _loadAudioFilesFromStorage() async {
    try {
      logDebugPrint(
          '🔍 [AUDIO DEBUG] Loading existing audio files from storage');

      // Get the application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDocDir.path}/eleven_labs_audio');

      // Check if the directory exists
      if (await audioDir.exists()) {
        logDebugPrint(
            '🔍 [AUDIO DEBUG] Audio directory exists: ${audioDir.path}');

        // Get all files in the directory
        final files = await audioDir.list().toList();
        logDebugPrint(
            '🔍 [AUDIO DEBUG] Found ${files.length} files in audio directory');

        // Process audio files
        for (final entity in files) {
          if (entity is File && entity.path.endsWith('.mp3')) {
            try {
              final fileName = path.basename(entity.path);
              logDebugPrint(
                  '🔍 [AUDIO DEBUG] Processing audio file: $fileName');

              // Check if the file exists
              final exists = await entity.exists();
              if (!exists) {
                logDebugPrint(
                    '🔍 [AUDIO DEBUG] File does not exist: ${entity.path}');
                continue;
              }

              // Extract message ID and timestamp from filename
              String messageId;
              int? timestamp;

              if (fileName.startsWith('eleven_labs_')) {
                final parts = fileName.split('_');
                if (parts.length >= 3) {
                  // Format: eleven_labs_TIMESTAMP_ID.mp3
                  final timestampStr = parts[2];
                  try {
                    timestamp = int.parse(timestampStr);
                    messageId =
                        parts.sublist(3).join('_').replaceAll('.mp3', '');

                    // Also store with the full ID (including timestamp)
                    final fullId = fileName.replaceAll('.mp3', '');

                    // Create an audio file with estimated duration (we don't know the actual duration)
                    final audioFile = AudioFile(
                      path: entity.path,
                      duration: const Duration(seconds: 30), // Default duration
                    );

                    // Store in cache with both IDs
                    _audioFiles[messageId] = audioFile;
                    _audioFiles[fullId] = audioFile;

                    // Store timestamp for sorting
                    if (timestamp != null) {
                      _messageTimestamps[fullId] = timestamp;
                      _messageTimestamps[messageId] = timestamp;
                    }

                    logDebugPrint(
                        '🔍 [AUDIO DEBUG] Added to cache with ID: $messageId and fullId: $fullId');
                  } catch (e) {
                    logDebugPrint(
                        '🔍 [AUDIO DEBUG] Error parsing timestamp: $e');
                    // If we can't parse the timestamp, just use the filename without extension
                    messageId = fileName.replaceAll('.mp3', '');

                    // Create an audio file with estimated duration
                    final audioFile = AudioFile(
                      path: entity.path,
                      duration: const Duration(seconds: 30), // Default duration
                    );

                    // Store in cache
                    _audioFiles[messageId] = audioFile;
                    logDebugPrint(
                        '🔍 [AUDIO DEBUG] Added to cache with ID: $messageId');
                  }
                } else {
                  // Format: eleven_labs_ID.mp3
                  messageId = fileName.replaceAll('.mp3', '');

                  // Create an audio file with estimated duration
                  final audioFile = AudioFile(
                    path: entity.path,
                    duration: const Duration(seconds: 30), // Default duration
                  );

                  // Store in cache
                  _audioFiles[messageId] = audioFile;
                  logDebugPrint(
                      '🔍 [AUDIO DEBUG] Added to cache with ID: $messageId');
                }
              } else {
                // Other format, just use the filename without extension
                messageId = fileName.replaceAll('.mp3', '');

                // Create an audio file with estimated duration
                final audioFile = AudioFile(
                  path: entity.path,
                  duration: const Duration(seconds: 30), // Default duration
                );

                // Store in cache
                _audioFiles[messageId] = audioFile;
                logDebugPrint(
                    '🔍 [AUDIO DEBUG] Added to cache with ID: $messageId');
              }
            } catch (e) {
              logDebugPrint('🔍 [AUDIO DEBUG] Error processing audio file: $e');
            }
          }
        }

        logDebugPrint(
            '🔍 [AUDIO DEBUG] Finished loading audio files. Cache size: ${_audioFiles.length}');
        logDebugPrint(
            '🔍 [AUDIO DEBUG] Cache keys: ${_audioFiles.keys.toList()}');
      } else {
        logDebugPrint(
            '🔍 [AUDIO DEBUG] Audio directory does not exist: ${audioDir.path}');
      }

      _initialized = true;
    } catch (e) {
      logDebugPrint(
          'AudioMessageProvider: Error loading audio files from storage: $e');
      _initialized = true; // Mark as initialized even if there was an error
    }
  }

  /// Generates an audio file for the given text and associates it with the message ID.
  ///
  /// [messageId] is a unique identifier for the message.
  /// [text] is the text to convert to audio.
  /// Returns the generated audio file, or null if generation failed.
  Future<AudioFile?> generateAudioForMessage(
      String messageId, String text) async {
    if (!_initialized) {
      logDebugPrint('AudioMessageProvider not initialized');
      throw Exception('AudioMessageProvider not initialized');
    }

    // Generate a unique ID for this request to track it through logs
    final requestId =
        DateTime.now().millisecondsSinceEpoch.toString().substring(6);

    logDebugPrint(
        '[$requestId] Generating audio for message $messageId with text: "${text.substring(0, min(50, text.length))}..."');

    try {
      final audioFile = await _audioGeneration.generate(text);
      logDebugPrint(
          '[$requestId] Audio generation successful for message $messageId: ${audioFile.path}, duration: ${audioFile.duration}');

      // Store the audio file with the message ID
      _audioFiles[messageId] = audioFile;

      // Log the current state of the audio files map
      logDebugPrint(
          '[$requestId] Current audio files map: ${_audioFiles.keys.join(', ')}');

      return audioFile;
    } catch (e) {
      logDebugPrint(
          '[$requestId] Failed to generate audio for message $messageId: $e');
      return null;
    }
  }

  /// Gets the audio file associated with the given message ID.
  ///
  /// [messageId] is the unique identifier for the message.
  /// Returns the audio file, or null if no audio file is associated with the message ID.
  Future<AudioFile?> getAudioForMessage(String messageId) async {
    // Wait for initialization to complete
    if (!_initialized) {
      await _waitForInitialization();
    }

    logDebugPrint('🔍 [AUDIO DEBUG] Getting audio for message: $messageId');
    logDebugPrint(
        '🔍 [AUDIO DEBUG] Current cache keys: ${_audioFiles.keys.toList()}');

    // Check if we have a direct match in the cache
    if (_audioFiles.containsKey(messageId)) {
      final audioFile = _audioFiles[messageId];

      // Verify the file still exists
      if (audioFile != null) {
        final file = File(audioFile.path);
        final exists = await file.exists();
        if (exists) {
          logDebugPrint(
              '🔍 [AUDIO DEBUG] Found exact match in cache for: $messageId');
          return audioFile;
        } else {
          logDebugPrint(
              '🔍 [AUDIO DEBUG] File in cache no longer exists: ${audioFile.path}');
          _audioFiles.remove(messageId);
        }
      }
    }

    // Check if we have a timestamped version of this message ID
    if (messageId.contains('_')) {
      final parts = messageId.split('_');
      if (parts.length >= 3) {
        // Try to extract the base ID (without timestamp)
        final baseId = parts.last;
        logDebugPrint('🔍 [AUDIO DEBUG] Checking for base ID: $baseId');

        if (_audioFiles.containsKey(baseId)) {
          final audioFile = _audioFiles[baseId];
          if (audioFile != null) {
            final file = File(audioFile.path);
            final exists = await file.exists();
            if (exists) {
              logDebugPrint(
                  '🔍 [AUDIO DEBUG] Found match for base ID: $baseId');
              // Also cache with the original ID for future lookups
              _audioFiles[messageId] = audioFile;
              return audioFile;
            }
          }
        }
      }
    }

    // Try to find a prefix match (for eleven_labs_TIMESTAMP_ID format)
    List<String> prefixMatches = [];
    for (final key in _audioFiles.keys) {
      if (messageId.startsWith('eleven_labs_') &&
          key.startsWith('eleven_labs_')) {
        final messageParts = messageId.split('_');
        final keyParts = key.split('_');

        if (messageParts.length >= 3 && keyParts.length >= 3) {
          // Check if the IDs match (last part)
          if (messageParts.last == keyParts.last) {
            prefixMatches.add(key);
            logDebugPrint(
                '🔍 [AUDIO DEBUG] Found prefix match: $key for $messageId');
          }
        }
      }
    }

    if (prefixMatches.isNotEmpty) {
      // Sort by timestamp (newest first) if available
      prefixMatches.sort((a, b) {
        final timestampA = _messageTimestamps[a] ?? 0;
        final timestampB = _messageTimestamps[b] ?? 0;
        return timestampB.compareTo(timestampA);
      });

      final matchKey = prefixMatches.first;
      final audioFile = _audioFiles[matchKey];
      if (audioFile != null) {
        final file = File(audioFile.path);
        final exists = await file.exists();
        if (exists) {
          logDebugPrint(
              '🔍 [AUDIO DEBUG] Using newest prefix match: $matchKey');
          // Cache with the original ID for future lookups
          _audioFiles[messageId] = audioFile;
          return audioFile;
        }
      }
    }

    // Try to find an exact pattern match (for eleven_labs_ID format)
    if (messageId.contains('eleven_labs_')) {
      final pattern = messageId.split('_').last;
      logDebugPrint(
          '🔍 [AUDIO DEBUG] Looking for pattern match with ID: $pattern');

      List<String> exactPatternMatches = [];
      for (final key in _audioFiles.keys) {
        if (key.contains('eleven_labs_')) {
          final keyPattern = key.split('_').last;
          if (keyPattern == pattern) {
            exactPatternMatches.add(key);
            logDebugPrint('🔍 [AUDIO DEBUG] Found exact pattern match: $key');
          }
        }
      }

      if (exactPatternMatches.isNotEmpty) {
        // Sort by timestamp (newest first) if available
        exactPatternMatches.sort((a, b) {
          final timestampA = _messageTimestamps[a] ?? 0;
          final timestampB = _messageTimestamps[b] ?? 0;
          return timestampB.compareTo(timestampA);
        });

        final matchKey = exactPatternMatches.first;
        final audioFile = _audioFiles[matchKey];
        if (audioFile != null) {
          final file = File(audioFile.path);
          final exists = await file.exists();
          if (exists) {
            logDebugPrint(
                '🔍 [AUDIO DEBUG] Using newest exact pattern match: $matchKey');
            // Cache with the original ID for future lookups
            _audioFiles[messageId] = audioFile;
            return audioFile;
          }
        }
      }
    }

    // Try to find a partial match
    List<String> partialMatches = [];
    for (final key in _audioFiles.keys) {
      if (key.contains(messageId) || messageId.contains(key)) {
        partialMatches.add(key);
        logDebugPrint(
            '🔍 [AUDIO DEBUG] Found partial match: $key for $messageId');
      }
    }

    if (partialMatches.isNotEmpty) {
      // Sort by timestamp (newest first) if available
      partialMatches.sort((a, b) {
        final timestampA = _messageTimestamps[a] ?? 0;
        final timestampB = _messageTimestamps[b] ?? 0;
        return timestampB.compareTo(timestampA);
      });

      final matchKey = partialMatches.first;
      final audioFile = _audioFiles[matchKey];
      if (audioFile != null) {
        final file = File(audioFile.path);
        final exists = await file.exists();
        if (exists) {
          logDebugPrint(
              '🔍 [AUDIO DEBUG] Using newest partial match: $matchKey');
          // Cache with the original ID for future lookups
          _audioFiles[messageId] = audioFile;
          return audioFile;
        }
      }
    }

    // If we still don't have a match, try to load from storage
    logDebugPrint(
        '🔍 [AUDIO DEBUG] No match found in cache, trying to load from storage');
    final audioFile = await _loadAudioFileFromStorage(messageId);
    if (audioFile != null) {
      _audioFiles[messageId] = audioFile;
      return audioFile;
    }

    logDebugPrint('🔍 [AUDIO DEBUG] No audio found for message: $messageId');
    return null;
  }

  /// Plays the audio file associated with the given message ID.
  ///
  /// [messageId] is the unique identifier for the message.
  /// Returns true if playback started successfully, false otherwise.
  Future<bool> playAudioForMessage(String messageId) async {
    if (!_initialized) {
      logDebugPrint('AudioMessageProvider not initialized');
      throw Exception('AudioMessageProvider not initialized');
    }

    // Get the audio file, which now checks storage if not in cache
    final audioFile = await getAudioForMessage(messageId);
    if (audioFile == null) {
      logDebugPrint('No audio file found for message $messageId');
      return false;
    }

    // Verify file exists
    final file = File(audioFile.path);
    final exists = await file.exists();
    logDebugPrint(
        'File exists check for playback: $exists for path: ${audioFile.path}');

    if (!exists) {
      logDebugPrint(
          'Audio file does not exist for playback: ${audioFile.path}');
      return false;
    }

    try {
      logDebugPrint('Playing audio for message $messageId: ${audioFile.path}');
      await _audioPlayback!.load(audioFile);
      await _audioPlayback!.play();
      return true;
    } catch (e) {
      logDebugPrint('Failed to play audio for message $messageId: $e');
      return false;
    }
  }

  /// Pauses the currently playing audio.
  ///
  /// Returns true if the audio was paused successfully, false otherwise.
  Future<bool> pauseAudio() async {
    if (!_initialized) {
      throw Exception('AudioMessageProvider not initialized');
    }

    try {
      await _audioPlayback!.pause();
      return true;
    } catch (e) {
      logDebugPrint('Failed to pause audio: $e');
      return false;
    }
  }

  /// Stops the currently playing audio.
  ///
  /// Returns true if the audio was stopped successfully, false otherwise.
  Future<bool> stopAudio() async {
    if (!_initialized) {
      throw Exception('AudioMessageProvider not initialized');
    }

    try {
      await _audioPlayback!.stop();
      return true;
    } catch (e) {
      logDebugPrint('Failed to stop audio: $e');
      return false;
    }
  }

  /// Loads an audio file from the assets directory.
  ///
  /// [messageId] is the unique identifier for the message.
  /// [assetPath] is the path to the audio file in the assets directory.
  /// [duration] is the duration of the audio file.
  /// Returns the loaded audio file, or null if loading failed.
  Future<AudioFile?> loadAudioFromAsset(
    String messageId,
    String assetPath,
    Duration duration,
  ) async {
    if (!_initialized) {
      throw Exception('AudioMessageProvider not initialized');
    }

    try {
      final audioFile = AudioFile(
        path: assetPath,
        duration: duration,
      );
      _audioFiles[messageId] = audioFile;
      return audioFile;
    } catch (e) {
      logDebugPrint(
          'Failed to load audio from asset for message $messageId: $e');
      return null;
    }
  }

  /// Cleans up resources used by the provider.
  ///
  /// This method should be called when the provider is no longer needed.
  Future<void> dispose() async {
    if (_initialized) {
      await _audioGeneration.cleanup();
      await _audioPlayback!.dispose();
      _audioFiles.clear();
      _initialized = false;
    }
  }

  /// Clears the audio cache.
  ///
  /// This method can be called to force reloading of audio files.
  void clearAudioCache() {
    logDebugPrint(
        'Clearing audio cache. Current cache size: ${_audioFiles.length}');
    _audioFiles.clear();
    logDebugPrint('Audio cache cleared');
  }

  /// Load audio file from storage based on message ID
  Future<AudioFile?> _loadAudioFileFromStorage(String messageId) async {
    try {
      logDebugPrint(
          '🔍 [AUDIO DEBUG] Loading audio file from storage for message: $messageId');

      // Try to parse the numeric ID from the message ID
      int? numericId;
      if (messageId.contains('_')) {
        final parts = messageId.split('_');
        if (parts.isNotEmpty) {
          numericId = int.tryParse(parts.last);
          logDebugPrint('🔍 [AUDIO DEBUG] Extracted numeric ID: $numericId');
        }
      } else {
        numericId = int.tryParse(messageId);
      }

      if (numericId == null) {
        logDebugPrint(
            '🔍 [AUDIO DEBUG] Could not parse numeric ID from messageId: $messageId');
        return null;
      }

      // Try to get the message from storage
      final chatStorage = ChatStorageService();
      final isar = await chatStorage.db;
      final message = await isar.chatMessageModels.get(numericId);

      if (message == null) {
        logDebugPrint(
            '🔍 [AUDIO DEBUG] Message not found in storage: $numericId');
        return null;
      }

      // Check if the message is an audio message
      if (message.type == MessageType.audio &&
          message.mediaPath != null &&
          message.duration != null) {
        logDebugPrint(
            '🔍 [AUDIO DEBUG] Found audio message in storage: ${message.mediaPath}');

        // Check if the file exists
        final file = File(message.mediaPath!);
        final exists = await file.exists();

        if (exists) {
          logDebugPrint(
              '🔍 [AUDIO DEBUG] Found audio file in storage: ${message.mediaPath}');

          // Create an audio file
          final audioFile = AudioFile(
            path: message.mediaPath!,
            duration: message.duration!,
          );

          // Cache for future lookups
          _audioFiles[messageId] = audioFile;

          // Also cache with the numeric ID
          if (numericId.toString() != messageId) {
            _audioFiles[numericId.toString()] = audioFile;
          }

          return audioFile;
        } else {
          logDebugPrint(
              '🔍 [AUDIO DEBUG] Audio file not found at path: ${message.mediaPath}');

          // Try to find the file in the audio directory
          try {
            final appDocDir = await getApplicationDocumentsDirectory();
            final audioDir = Directory('${appDocDir.path}/eleven_labs_audio');

            if (await audioDir.exists()) {
              final files = await audioDir.list().toList();

              // Try to find a file with the message ID in its name
              for (final entity in files) {
                if (entity is File &&
                    entity.path.endsWith('.mp3') &&
                    path.basename(entity.path).contains(numericId.toString())) {
                  logDebugPrint(
                      '🔍 [AUDIO DEBUG] Found matching file in audio directory: ${entity.path}');

                  // Create an audio file
                  final audioFile = AudioFile(
                    path: entity.path,
                    duration: message.duration!,
                  );

                  // Cache for future lookups
                  _audioFiles[messageId] = audioFile;

                  // Also cache with the numeric ID
                  if (numericId.toString() != messageId) {
                    _audioFiles[numericId.toString()] = audioFile;
                  }

                  return audioFile;
                }
              }

              logDebugPrint(
                  '🔍 [AUDIO DEBUG] Could not find matching file in audio directory');
            } else {
              logDebugPrint('🔍 [AUDIO DEBUG] Audio directory does not exist');
            }
          } catch (e) {
            logDebugPrint(
                '🔍 [AUDIO DEBUG] Error searching for audio file: $e');
          }
        }
      } else {
        logDebugPrint(
            '🔍 [AUDIO DEBUG] Message is not an audio message or missing required fields');
      }

      return null;
    } catch (e) {
      logDebugPrint(
          '🔍 [AUDIO DEBUG] Error loading audio file from storage: $e');
      return null;
    }
  }

  /// Wait for initialization to complete
  Future<void> _waitForInitialization() async {
    int attempts = 0;
    while (!_initialized && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!_initialized) {
      logDebugPrint(
          'AudioMessageProvider: Failed to initialize after $attempts attempts');
      // Try to initialize again
      _loadAudioFilesFromStorage();
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
