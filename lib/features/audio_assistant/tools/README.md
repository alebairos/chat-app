# Audio Sample Generator

This tool generates audio samples for the audio assistant feature. It creates MP3 files for common assistant responses and saves them to the `assets/audio` directory.

## Why Use This Tool?

- Generate consistent audio samples for testing and development
- Create audio files that can be bundled with the app
- Test the text-to-speech functionality on a real device

## How to Use

1. Connect a real device or start an emulator (this won't work in a test environment)
2. Run the following command:

```bash
flutter run -t lib/features/audio_assistant/tools/generate_samples_main.dart
```

3. In the app interface, click the "Generate Audio Samples" button
4. Wait for the samples to be generated
5. The app will display logs of the generation process
6. The audio files will be saved to the `assets/audio` directory

## Generated Files

The tool generates the following audio files:

- `welcome_message.mp3`: A welcome message for the app
- `assistant_response.mp3`: A sample assistant response

## Adding to Assets

The audio files need to be added to the `pubspec.yaml` file to be included in the app bundle. The following entries should be added to the `assets` section:

```yaml
  assets:
    # ... other assets
    - assets/audio/welcome_message.mp3
    - assets/audio/assistant_response.mp3
```

## Troubleshooting

If you encounter issues:

1. Make sure you're running on a real device or emulator
2. Check that the Flutter TTS plugin is properly installed
3. Verify that the device has text-to-speech capabilities
4. Check the logs in the app for detailed error messages

## Notes

- The audio files are generated using the device's text-to-speech engine
- The quality and voice may vary depending on the device
- The duration of the audio files is estimated based on word count 