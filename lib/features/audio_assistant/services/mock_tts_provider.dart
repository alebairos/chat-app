import 'dart:io';
import 'dart:math';
import '../../../utils/logger.dart';
import 'tts_provider.dart';

/// A mock implementation of [TTSProvider] for testing purposes.
///
/// This provider doesn't actually generate speech but creates mock audio files
/// for testing the audio assistant functionality without external dependencies.
class MockTTSProvider implements TTSProvider {
  final Logger _logger = Logger();
  bool _isInitialized = false;
  final Map<String, dynamic> _configuration = {
    'simulateDelay': true,
    'delayMilliseconds': 500,
    'simulateRandomFailures': false,
    'failureRate': 0.1, // 10% chance of failure
  };

  @override
  String get name => 'MockTTS';

  @override
  Map<String, dynamic> get config => Map.from(_configuration);

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Simulate initialization delay
    if (_configuration['simulateDelay'] == true) {
      await Future.delayed(
          Duration(milliseconds: _configuration['delayMilliseconds']));
    }

    // Simulate potential failures
    if (_configuration['simulateRandomFailures'] == true) {
      final random = Random();
      if (random.nextDouble() < _configuration['failureRate']) {
        _logger.error('Simulated random initialization failure');
        return false;
      }
    }

    _isInitialized = true;
    _logger.debug('Mock TTS Provider initialized successfully');
    return true;
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
      // Simulate processing delay
      if (_configuration['simulateDelay'] == true) {
        // Make longer text take more time to process
        final delayFactor = min(1.0 + (text.length / 100), 5.0);
        final delay =
            (_configuration['delayMilliseconds'] * delayFactor).round();
        await Future.delayed(Duration(milliseconds: delay));
      }

      // Simulate potential failures
      if (_configuration['simulateRandomFailures'] == true) {
        final random = Random();
        if (random.nextDouble() < _configuration['failureRate']) {
          _logger.error('Simulated random generation failure');
          return false;
        }
      }

      // Create an empty file
      final file = File(outputPath);
      await file.create();

      // For tests, we want to actually have some binary data
      // We'll create a simple WAV file with a sine wave
      // This is not necessary for mock purposes but helps verify file handling
      await _writeMockAudioFile(file, text.length);

      _logger.debug('Generated mock audio file at: $outputPath');
      return true;
    } catch (e) {
      _logger.error('Failed to generate mock audio: $e');
      return false;
    }
  }

  @override
  Future<bool> updateConfig(Map<String, dynamic> newConfig) async {
    try {
      _configuration.addAll(newConfig);
      _logger.debug('Updated Mock TTS Provider configuration');
      return true;
    } catch (e) {
      _logger.error('Failed to update Mock TTS Provider configuration: $e');
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    // Nothing to clean up for this provider
    _isInitialized = false;
  }

  /// Generate a simple mock audio file that has some actual content
  Future<void> _writeMockAudioFile(File file, int textLength) async {
    // Create a very basic WAV file with a sine wave
    // The length of the audio depends on the text length
    final duration = max(1, min(textLength ~/ 10, 30)); // 1 to 30 seconds

    // Simple WAV header (44 bytes) + sample data
    const sampleRate = 8000;
    const numChannels = 1;
    const bitsPerSample = 8;
    final dataSize = duration * sampleRate * numChannels * (bitsPerSample ~/ 8);
    final fileSize = 36 + dataSize;

    final header = List<int>.filled(44, 0);

    // "RIFF" chunk descriptor
    header[0] = 0x52; // 'R'
    header[1] = 0x49; // 'I'
    header[2] = 0x46; // 'F'
    header[3] = 0x46; // 'F'

    // Chunk size
    header[4] = (fileSize & 0xFF);
    header[5] = ((fileSize >> 8) & 0xFF);
    header[6] = ((fileSize >> 16) & 0xFF);
    header[7] = ((fileSize >> 24) & 0xFF);

    // "WAVE" format
    header[8] = 0x57; // 'W'
    header[9] = 0x41; // 'A'
    header[10] = 0x56; // 'V'
    header[11] = 0x45; // 'E'

    // "fmt " sub-chunk
    header[12] = 0x66; // 'f'
    header[13] = 0x6D; // 'm'
    header[14] = 0x74; // 't'
    header[15] = 0x20; // ' '

    // Sub-chunk size
    header[16] = 16; // 16 for PCM
    header[17] = 0;
    header[18] = 0;
    header[19] = 0;

    // Audio format (1 = PCM)
    header[20] = 1;
    header[21] = 0;

    // Number of channels
    header[22] = numChannels;
    header[23] = 0;

    // Sample rate
    header[24] = (sampleRate & 0xFF);
    header[25] = ((sampleRate >> 8) & 0xFF);
    header[26] = ((sampleRate >> 16) & 0xFF);
    header[27] = ((sampleRate >> 24) & 0xFF);

    // Byte rate
    const byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    header[28] = (byteRate & 0xFF);
    header[29] = ((byteRate >> 8) & 0xFF);
    header[30] = ((byteRate >> 16) & 0xFF);
    header[31] = ((byteRate >> 24) & 0xFF);

    // Block align
    const blockAlign = numChannels * (bitsPerSample ~/ 8);
    header[32] = blockAlign;
    header[33] = 0;

    // Bits per sample
    header[34] = bitsPerSample;
    header[35] = 0;

    // "data" sub-chunk
    header[36] = 0x64; // 'd'
    header[37] = 0x61; // 'a'
    header[38] = 0x74; // 't'
    header[39] = 0x61; // 'a'

    // Data size
    header[40] = (dataSize & 0xFF);
    header[41] = ((dataSize >> 8) & 0xFF);
    header[42] = ((dataSize >> 16) & 0xFF);
    header[43] = ((dataSize >> 24) & 0xFF);

    // Write header to file
    final sink = file.openWrite();
    sink.add(header);

    // Generate sample data (simple sine wave)
    final sampleData = List<int>.filled(dataSize, 0);
    for (int i = 0; i < dataSize; i++) {
      // Generate a simple sine wave
      final time = i / sampleRate;
      const amplitude = 127;
      const frequency = 440; // A4 note
      sampleData[i] =
          (amplitude * sin(2 * pi * frequency * time) + 128).toInt() & 0xFF;
    }

    // Write sample data to file
    sink.add(sampleData);
    await sink.close();
  }
}
