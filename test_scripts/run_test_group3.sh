#!/bin/bash

echo "Running Test Group 3: Claude Service Tests"
echo "========================================"
echo "Started at: $(date)"
echo ""

OUTPUT_FILE="test_scripts/results/test_results_group3.txt"

echo "Test Group 3: Claude Service Tests" > $OUTPUT_FILE
echo "=======================================" >> $OUTPUT_FILE
echo "Started at: $(date)" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Run each test file and append results to output file
flutter test test/claude_service_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/claude_service_error_handling_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/services/claude_service_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/services/claude_service_error_handling_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/services/claude_service_integration_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/chat_screen_error_handling_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/transcription_service_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

echo "Completed at: $(date)" >> $OUTPUT_FILE
echo "Test Group 3 completed. Results saved to $OUTPUT_FILE" 