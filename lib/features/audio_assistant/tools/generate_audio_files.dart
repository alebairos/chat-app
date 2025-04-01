import 'dart:io';

/// A simple script to generate audio files for testing purposes.
///
/// This script uses the system's 'say' command (on macOS) to generate
/// audio files from text. It saves the files to the assets/audio directory.
void main() async {
  print('Generating audio files...');

  // Create assets/audio directory if it doesn't exist
  final assetDir = Directory('assets/audio');
  if (!await assetDir.exists()) {
    await assetDir.create(recursive: true);
    print('Created assets/audio directory');
  }

  // Generate welcome message
  print('Generating welcome message...');
  const welcomeMessage =
      'Welcome to the chat app! I can now respond with voice messages.';
  final welcomeFilePath = '${assetDir.path}/welcome_message.aiff';

  try {
    final welcomeResult = await Process.run('say', [
      '-v', 'Samantha', // Use Samantha voice (change as needed)
      '-o', welcomeFilePath,
      welcomeMessage,
    ]);

    if (welcomeResult.exitCode == 0) {
      print('Welcome message saved to: $welcomeFilePath');
    } else {
      print('Error generating welcome message: ${welcomeResult.stderr}');
    }
  } catch (e) {
    print('Error generating welcome message: $e');
  }

  // Generate assistant response
  print('Generating assistant response...');
  const assistantResponse = 'I\'ve analyzed your code and found a few issues. '
      'First, there\'s a missing semicolon on line 42. '
      'Second, the function on line 78 could be optimized by using a more efficient algorithm. '
      'Would you like me to fix these issues for you?';
  final assistantFilePath = '${assetDir.path}/assistant_response.aiff';

  try {
    final assistantResult = await Process.run('say', [
      '-v', 'Samantha', // Use Samantha voice (change as needed)
      '-o', assistantFilePath,
      assistantResponse,
    ]);

    if (assistantResult.exitCode == 0) {
      print('Assistant response saved to: $assistantFilePath');
    } else {
      print('Error generating assistant response: ${assistantResult.stderr}');
    }
  } catch (e) {
    print('Error generating assistant response: $e');
  }

  print('\nNext steps:');
  print('1. Add the following to your pubspec.yaml assets section:');
  print('  - assets/audio/welcome_message.aiff');
  print('  - assets/audio/assistant_response.aiff');
  print('2. Run "flutter pub get" to update dependencies');
}
