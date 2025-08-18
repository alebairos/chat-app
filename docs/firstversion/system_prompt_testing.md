# System Prompt Testing Strategy

## Overview

This document outlines the testing strategy for the system prompt functionality in the Chat App. The system prompt is a critical component that defines the AI assistant's character, behavior, and capabilities. These tests ensure that the system prompt functions correctly and maintains its integrity across application updates.

## Testing Principles

Our system prompt tests follow these key principles:

1. **Very Focused**: Each test targets a specific aspect of the system prompt's functionality.
2. **Simple**: Tests are straightforward, using real components without complex mocks.
3. **No Mocks Needed**: Tests utilize the actual system prompt and UI components.
4. **Tests UI Consistency**: Verifies that the UI displays natural language responses without exposing technical details.
5. **Easy to Understand and Maintain**: Well-structured tests with clear assertions and comments.
6. **One Test at a Time**: Each test focuses on a single functionality aspect.

## Test Suite Structure

The system prompt test suite consists of three focused tests:

### 1. Character Identity Test (`system_prompt_character_test.dart`)

This test verifies that the system prompt maintains the correct character identity in the UI:

- Checks for character identity elements (e.g., "Sergeant Oracle")
- Verifies instructions to hide commands are present
- Ensures character-specific formatting is preserved
- Confirms no command references appear in the UI

### 2. Life Planning Test (`system_prompt_life_planning_test.dart`)

This test ensures that the life planning functionality works correctly:

- Verifies the inclusion of required life planning commands
- Checks instructions for mapping goals and habits
- Ensures natural language presentation of advice
- Confirms no command references appear in the UI

### 3. Formatting Test (`system_prompt_formatting_test.dart`)

This test validates that formatting instructions are properly applied:

- Checks for formatting instructions (gestures, emojis, bold, italics)
- Verifies examples of formatted responses
- Ensures all formatting elements appear correctly in the UI
- Confirms no raw formatting syntax is visible

## Benefits of This Approach

1. **Reliability**: Using real components leads to more accurate tests.
2. **Simplicity**: Clear steps and assertions make tests easy to follow.
3. **Focus**: Each test has a defined purpose, aiding in troubleshooting.
4. **Maintainability**: Structured tests are easy to update with system changes.
5. **Documentation**: Tests serve as a functional guide for the system prompt.

## Running the Tests

To run all system prompt tests:

```bash
flutter test test/system_prompt_character_test.dart test/system_prompt_life_planning_test.dart test/system_prompt_formatting_test.dart
```

To run a specific test:

```bash
flutter test test/system_prompt_character_test.dart
```

## Common Issues and Solutions

### Issue: Command Exposure in UI

If commands are being exposed in the UI, check:
- System prompt instructions for hiding commands
- Examples of good/bad responses in the system prompt
- Natural language transformation instructions

### Issue: Formatting Not Applied

If formatting is not being applied correctly, verify:
- Formatting instructions in the system prompt
- Examples of formatted responses
- UI rendering of formatted elements

## Conclusion

These focused tests provide a solid foundation for ensuring the system prompt's correct functionality. By verifying character identity, life planning features, and formatting instructions, we can maintain a consistent and engaging user experience while preventing technical details from being exposed in the UI. 