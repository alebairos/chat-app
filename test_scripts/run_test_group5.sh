#!/bin/bash

echo "Running Test Group 5: Chat UI Tests"
echo "========================================"
echo "Started at: $(date)"
echo ""

# Create results directory if it doesn't exist
mkdir -p test_scripts/results

OUTPUT_FILE="test_scripts/results/test_results_group5.txt"

echo "Test Group 5: Chat UI Tests" > $OUTPUT_FILE
echo "=======================================" >> $OUTPUT_FILE
echo "Started at: $(date)" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Run each test file and append results to output file
flutter test test/chat_screen_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/chat_message_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/chat_app_bar_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/chat_input_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/chat_storage_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/widget_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

echo "Completed at: $(date)" >> $OUTPUT_FILE

# Check if any tests failed
if grep -q "Some tests failed" $OUTPUT_FILE; then
  echo "❌ Some tests failed in Group 5. See $OUTPUT_FILE for details."
else
  echo "✅ All tests passed in Group 5!"
fi

echo "Test Group 5 completed. Results saved to $OUTPUT_FILE" 