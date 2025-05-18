# Task 1: Setup for Audio Assistant Implementation

## Overview

This document provides the practical steps to set up the development environment for implementing the audio assistant feature. These steps align with Phase 1 from our implementation plan.

## Steps to Complete

### 1. Create Feature Branch

```bash
# Ensure you're on the main branch
git checkout main

# Create and switch to a new feature branch
git checkout -b audio-assistant-implementation
```

### 2. Create Test Directory Structure

```bash
# Create the required test directories
mkdir -p test/features/audio_assistant/integration
mkdir -p test/features/audio_assistant/performance
mkdir -p test/services
```

### 3. Run Baseline Tests

```bash
# Run all existing tests to establish a baseline
flutter test
```

Record any failing tests before beginning implementation. These should be addressed before proceeding.

### 4. Create MockAudioAssistantTTSService

Create a new file at `test/mocks/mock_audio_assistant_tts_service.dart`:

```dart
import 'package:mocktail/mocktail.dart';
import 'package:character_ai_clone/features/audio_assistant/tts_service.dart';

class MockAudioAssistantTTSService extends Mock implements AudioAssistantTTSService {
  @override
  Future<bool> initialize() async => true;
  
  @override
  Future<String?> generateAudio(String text) async => 'test_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
}
```

### 5. Create Test Files

Create the unit test file at `test/services/claude_service_tts_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/features/audio_assistant/tts_service.dart';
import '../mocks/mock_audio_assistant_tts_service.dart';

class MockHttpClient extends Mock implements http.Client {}
class MockResponse extends Mock implements http.Response {}

void main() {
  late MockAudioAssistantTTSService mockTTSService;
  late MockHttpClient mockClient;
  late ClaudeService claudeService;

  setUp(() {
    mockTTSService = MockAudioAssistantTTSService();
    mockClient = MockHttpClient();
    claudeService = ClaudeService(
      client: mockClient,
      ttsService: mockTTSService,
    );
    
    // Register fallback values for any
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue({});
  });

  test('Confirm test setup works', () {
    expect(claudeService, isNotNull);
  });
}
```

Create the integration test file at `test/features/audio_assistant/integration/claude_tts_integration_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/features/audio_assistant/tts_service.dart';

class MockHttpClient extends Mock implements http.Client {}
class MockResponse extends Mock implements http.Response {}

void main() {
  late AudioAssistantTTSService ttsService;
  late MockHttpClient mockClient;
  late ClaudeService claudeService;

  setUp(() {
    ttsService = AudioAssistantTTSService();
    ttsService.enableTestMode();
    
    mockClient = MockHttpClient();
    claudeService = ClaudeService(
      client: mockClient,
      ttsService: ttsService,
    );
    
    // Register fallback values for any
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue({});
  });

  test('Confirm integration test setup works', () {
    expect(claudeService, isNotNull);
    expect(ttsService, isNotNull);
  });
}
```

### 6. Verify App Runs

```bash
flutter run
```

Verify the app launches and functions correctly before beginning implementation.

## Completion Checklist

- [ ] Feature branch created
- [ ] Test directory structure created
- [ ] Baseline tests run
- [ ] Mock TTS service created
- [ ] Unit test files created
- [ ] Integration test files created
- [ ] App verified to run correctly

## Next Task

Once this setup is complete, proceed to Task 2.1: Extend ClaudeService to Support TTS. 