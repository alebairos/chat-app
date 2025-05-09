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
import 'package:isar/isar.dart';

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

  /// Generates audio for a given message ID and text.
  ///
  /// [messageId] is the unique identifier for the message.
  /// [messageText] is the text content of the message to be converted to speech.
  /// Returns the [AudioFile] if generation was successful, null otherwise.
  Future<AudioFile?> generateAudioForMessage(
    String messageId,
    String messageText,
  ) async {
    if (!_initialized) {
      logDebugPrint(
          'AudioMessageProvider not initialized. Call initialize() first.');
      return null;
    }

    logDebugPrint(
        'Generating audio for message $messageId: "${messageText.length > 50 ? "${messageText.substring(0, 50)}..." : messageText}"');

    try {
      // The AudioGeneration service (e.g., ElevenLabsTTSService)
      // is responsible for its own file path management.
      final AudioFile generatedFile =
          await _audioGeneration.generate(messageText);

      // The path in generatedFile is absolute, as determined by the generation service.
      logDebugPrint(
          'Successfully generated audio for message $messageId at ${generatedFile.path}');
      _audioFiles[messageId] = generatedFile; // Cache it with the absolute path

      // Attempt to update this in ChatStorageService as well
      try {
        final ChatStorageService storage = ChatStorageService();
        final Directory appDocDir = await getApplicationDocumentsDirectory();

        // We need the relative path for storage
        final relativePath =
            path.relative(generatedFile.path, from: appDocDir.path);
        logDebugPrint(
            'Updating storage for message $messageId with relative path: $relativePath and duration ${generatedFile.duration}');

        // Assuming messageId can be parsed to int for the DB ID.
        // This might need adjustment if messageId is not purely numeric.
        await storage.updateMessage(
          int.parse(messageId),
          type: MessageType.audio,
          mediaPath: relativePath,
          duration: generatedFile.duration,
        );
        logDebugPrint('Successfully updated storage for $messageId.');
      } catch (e) {
        logDebugPrint(
            'Error updating message $messageId in storage after audio generation: $e. Audio file is generated but not linked in DB via this flow.');
      }
      return generatedFile;
    } catch (e) {
      logDebugPrint(
          'Error during _audioGeneration.generate for message $messageId: $e');
    }
    return null;
  }

  /// Retrieves the audio file for a given message ID.
  ///
  /// If the audio file is not already cached, it will be loaded from storage or generated.
  /// Returns the [AudioFile] if found or generated, null otherwise.
  Future<AudioFile?> getAudioForMessage(
    String messageId,
    String messageText,
  ) async {
    if (!_initialized) {
      logDebugPrint(
          'AudioMessageProvider not initialized. Call initialize() first.');
      return null;
    }

    // Check if the audio file is already cached
    if (_audioFiles.containsKey(messageId)) {
      // Verify file existence before returning from cache
      final cachedFile = _audioFiles[messageId]!;
      final file = File(cachedFile.path);
      if (await file.exists()) {
        logDebugPrint(
            'Found audio file in cache for message $messageId: ${cachedFile.path}');
        return cachedFile;
      } else {
        logDebugPrint(
            'Cached audio file for message $messageId not found on disk: ${cachedFile.path}. Removing from cache.');
        _audioFiles.remove(messageId);
      }
    }

    // If not cached, try to load from storage (this now expects messageText)
    final audioFileFromStorage =
        await _loadAudioFileFromStorage(messageId, messageText);
    if (audioFileFromStorage != null) {
      logDebugPrint(
          'Loaded audio file from storage for message $messageId: ${audioFileFromStorage.path}');
      return audioFileFromStorage;
    }

    // If not in storage and not cached, generate audio (if it's an assistant message)
    // This part might need re-evaluation: should we auto-generate here if not found?
    // For now, assume if it's not in cache/storage, it needs generation if it's an assistant response.
    // This logic primarily applies if we're trying to get audio for an assistant message that hasn't had audio generated yet.
    // If ChatScreen ensures audio is generated and its path (relative) stored,
    // then _loadAudioFileFromStorage should typically find it.

    // logDebugPrint(
    //     'Audio file not found in cache or storage for message $messageId. Considering generation.');
    // // Potentially, one could try to generate it here if it's an assistant message
    // // final isAssistantMessage = !messageId.startsWith('user_'); // Example check
    // // if (isAssistantMessage) {
    // //   return generateAudioForMessage(messageId, messageText);
    // // }

    logDebugPrint(
        'Audio file not found for message $messageId after checking cache and storage.');
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
    final audioFile = await getAudioForMessage(messageId, '');
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

  /// Load a specific audio file from storage by message ID
  Future<AudioFile?> _loadAudioFileFromStorage(
      String messageId, String messageText) async {
    try {
      final ChatStorageService chatStorage = ChatStorageService();
      final Isar isar = await chatStorage.db;
      final int? numericId = int.tryParse(messageId);

      if (numericId == null) {
        logDebugPrint('Could not parse numeric ID from messageId: $messageId');
        return null;
      }

      final ChatMessageModel? chatMessage =
          await isar.chatMessageModels.get(numericId);

      if (chatMessage != null &&
          chatMessage.type == MessageType.audio &&
          chatMessage.mediaPath != null) {
        // Assume chatMessage.mediaPath is a RELATIVE path from the database
        final String relativeMediaPath = chatMessage.mediaPath!;
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String absoluteMediaPath =
            path.join(appDocDir.path, relativeMediaPath);

        logDebugPrint(
            'Constructed absolute path: $absoluteMediaPath from relative: $relativeMediaPath');

        final audioFileOnDisk = File(absoluteMediaPath);
        if (await audioFileOnDisk.exists()) {
          logDebugPrint(
              'Audio file exists at reconstructed path: $absoluteMediaPath');
          // Use the message's duration if available, otherwise a default
          final duration = chatMessage.duration ?? const Duration(seconds: 30);
          final audioFile = AudioFile(
            path: absoluteMediaPath, // Use reconstructed ABSOLUTE path
            duration: duration,
          );
          _audioFiles[messageId] =
              audioFile; // Cache with original string messageId
          return audioFile;
        } else {
          logDebugPrint(
              'Audio file does NOT exist at reconstructed path: $absoluteMediaPath');
        }
      }
    } catch (e) {
      logDebugPrint(
          'Error loading specific audio file for message $messageId: $e');
    }
    return null;
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
