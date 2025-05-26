# Claude Integration Tests

## Overview

This codebase contains several integration tests that interact with the Claude API. These tests are tagged with `@Tags(['integration', 'api', 'claude'])` to prevent them from running by default during normal test runs, as they require API keys and consume credits.

## Test Files

The following test files have been tagged as Claude integration tests:

1. `test/persona_alignment_integration_test.dart` - Tests character persona alignment with Claude
2. `test/claude_service_test.dart` - Tests the Claude service functionality
3. `test/character_flow_integration_test.dart` - Tests character switching flow
4. `test/services/claude_service_integration_test.dart` - Tests life plan MCP integration
5. `test/features/audio_assistant/integration/claude_tts_integration_test.dart` - Tests Claude TTS integration

## Running Tests

### Running All Regular Tests (Excluding Claude Integration Tests)

To run all tests except the Claude integration tests:

```bash
flutter test
```

This command will automatically exclude tests tagged with 'integration', 'api', or 'claude'.

### Running Only Claude Integration Tests

To specifically run the Claude integration tests:

```bash
flutter test --tags=claude
```

### Running a Specific Claude Integration Test

To run a specific Claude integration test file:

```bash
flutter test test/claude_service_test.dart
```

Note that running a specific test file will run the tests regardless of tags.

## Prerequisites

Before running Claude integration tests, ensure:

1. Your `.env` file contains a valid API key:
   ```
   ANTHROPIC_API_KEY=your_actual_api_key_here
   ```

2. You have an active internet connection

3. You understand these tests will consume Claude API credits

## Troubleshooting

If Claude integration tests are still running when you execute `flutter test`, check:

1. Ensure the correct import for `package:flutter_test/flutter_test.dart` is included in all test files
2. Make sure the `@Tags` annotation is applied to the `main()` function
3. Consider adding additional configuration to your test runner to exclude these tags 