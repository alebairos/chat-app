# Audio Assistant Manual Testing Plan

This document outlines the manual testing procedures to verify that the audio assistant feature works correctly after our recent fixes.

## 1. Parallel Playback Testing

**Objective**: Verify that only one audio message plays at a time.

**Steps**:
1. Generate at least two assistant audio messages
2. Play the first message and confirm it starts playing
3. While the first message is playing, click play on the second message
4. Verify that:
   - The first message stops playing (play button appears)
   - Only the second message plays (pause button appears)
5. Repeat with user audio messages
6. Test mixed scenarios (assistant + user messages)

**Expected Results**:
- Only one audio message should play at any time
- Previously playing message should stop when a new one starts

## 2. Waveform Visualization Testing

**Objective**: Verify that waveform sizing and visualization are appropriate.

**Steps**:
1. Generate assistant audio messages with different durations:
   - Short (1-3 seconds)
   - Medium (10-20 seconds)
   - Long (30+ seconds)
2. Observe the waveform for each message

**Expected Results**:
- Short messages should have a compact waveform (width < 300px)
- Long messages should have a capped width (max 300px)
- All waveforms should have consistent height (40px)
- Waveform visualization should be visible and properly rendered

## 3. Progress Indicator Testing

**Objective**: Verify that the progress indicator moves correctly during playback.

**Steps**:
1. Play an audio message and observe the progress indicator (the "pipe-like char")
2. Let the message play to completion

**Expected Results**:
- Progress indicator should move smoothly from left to right
- Progress indicator should reach the end of the waveform when audio completes
- Progress indicator position should correspond to actual playback position
- Progress indicator should reset when playback is stopped or restarted

## 4. Language Detection and Voice Selection Testing

**Objective**: Verify that the correct voice is used based on message language.

**Steps**:
1. Generate an assistant message in English (e.g., "Hello, how are you today?")
2. Generate an assistant message in Portuguese (e.g., "Olá, como você está hoje?")
3. Play both messages and listen to the voices

**Expected Results**:
- English message should use an English-speaking voice (Adam - EXAVITQu4vr4xnSDxMaL)
- Portuguese message should use a Portuguese-speaking voice (Sergio - IKne3meq5aSn9XLyUdCD)
- Voices should sound natural in their respective languages

## 5. User Recording Component Testing

**Objective**: Verify that the user recording component works correctly.

**Steps**:
1. Click the microphone icon to start recording
2. Verify that the recording UI appears with a stop button
3. Speak for a few seconds
4. Click the stop button
5. Verify that the recorded message appears in the chat

**Expected Results**:
- Recording indicator and duration should be visible while recording
- Stop button should be clearly visible and functional
- After stopping, the recorded message should appear with correct duration
- Playback of the recorded message should work correctly

## 6. Edge Cases Testing

**Objective**: Verify that the audio assistant handles edge cases gracefully.

**Steps**:
1. Test with very short recordings (< 1 second)
2. Test with very long recordings (> 2 minutes)
3. Try playing a message, then quickly playing another before the first one fully loads
4. Try rapid clicking on play/pause buttons
5. Test with missing audio files (if possible to simulate)

**Expected Results**:
- Very short recordings should display and play correctly
- Very long recordings should have capped waveform width but play correctly
- Rapid interactions should not cause crashes or UI glitches
- Error states should be handled gracefully with user feedback

## 7. Cross-Device Testing

**Objective**: Verify that the audio assistant works consistently across different devices.

**Steps**:
1. Test on at least two different device types (phone, tablet)
2. Test on different OS versions if possible

**Expected Results**:
- Consistent behavior across all tested devices
- UI should adapt appropriately to different screen sizes
- Audio playback should work reliably on all devices

## Test Reporting

For each test scenario, document:
- Pass/Fail status
- Any unexpected behavior
- Screenshots of issues (if applicable)
- Device information for failed tests

Report all issues in the project issue tracker with detailed reproduction steps. 