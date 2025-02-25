#!/bin/bash

echo "Running Test Group 1: Audio Recorder Tests"
echo "========================================"
echo "Started at: $(date)"
echo ""

OUTPUT_FILE="test_scripts/results/test_results_group1.txt"

echo "Test Group 1: Audio Recorder Tests" > $OUTPUT_FILE
echo "=======================================" >> $OUTPUT_FILE
echo "Started at: $(date)" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Run each test file and append results to output file
flutter test test/audio_recorder_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/audio_recorder_button_style_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/audio_recorder_delete_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/audio_recorder_error_handling_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

# Note: audio_recorder_concurrency_test.dart is skipped as mentioned in the code

echo "Completed at: $(date)" >> $OUTPUT_FILE
echo "Test Group 1 completed. Results saved to $OUTPUT_FILE" 