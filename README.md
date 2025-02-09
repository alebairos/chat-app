# Chat App

A Flutter-based chat application that implements an AI-powered chat interface.

## Version
Current version: v1.0.9

## Features

- Real-time chat interface
- AI-powered responses using Claude API
- Audio messages with OpenAI Whisper transcription
- Clean and intuitive UI

## Setup

1. Clone the repository
2. Create a `.env` file in the root directory
3. Run `flutter pub get` to install dependencies
4. Run the app using `flutter run`

## Environment Variables

Create a `.env` file in the root directory with the following variables:
- `ANTHROPIC_API_KEY`: Your API key for the Claude AI service
- `OPENAI_API_KEY`: Your API key for OpenAI Whisper transcription

## Development

This project is built with Flutter. For help getting started with Flutter development:

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)

## Changelog

### v1.0.9
- Improved documentation clarity
- Consolidated test coverage changelog entries
- Removed redundant version information

### v1.0.8
- Fixed accessibility test implementation
- Improved test cleanup with proper semantics handling
- All tests passing successfully

### v1.0.7
- Added comprehensive test coverage for ChatMessage widget:
  - Text color tests for user/non-user messages
  - Long message wrapping tests
  - Accessibility tests
  - Invalid audio path handling tests
  - Audio player controls tests
  - Test mode to avoid asset loading issues
  - Tests for user messages, audio messages, and layout
  - Tests for copyWith functionality and edge cases

### v1.0.5
- Fixed auto-stop recording when sending audio message
- Added OpenAI API key to environment variables
- Improved error handling in audio recording

### v1.0.4
- Improved audio message UI with duration display
- Switched from Vosk to OpenAI Whisper for transcription
- Unified message styling with grey background
- Enhanced audio controls UI
- Fixed UTF-8 encoding in responses

### v1.0.3
- Audio Message implementation
- Added volume control functionality
- Known issue: Default volume is too low

### v1.0.2
- Basic audio notes implementation
- Added initial voice recording functionality
- Known limitations in audio processing

### v1.0.1
- Updated environment configuration
- Improved documentation
- Security enhancements

### v1.0.0
- Initial release
- Implemented chat interface
- Added Claude AI integration
- Basic UI components
