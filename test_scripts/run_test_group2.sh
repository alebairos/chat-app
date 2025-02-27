#!/bin/bash

echo "Running Test Group 2: Audio Message and System Prompt Tests"
echo "========================================"
echo "Started at: $(date)"
echo ""

# Create results directory if it doesn't exist
mkdir -p test_scripts/results

OUTPUT_FILE="test_scripts/results/test_results_group2.txt"

echo "Test Group 2: Audio Message and System Prompt Tests" > $OUTPUT_FILE
echo "=======================================" >> $OUTPUT_FILE
echo "Started at: $(date)" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Run each test file and append results to output file
flutter test test/audio_message_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/system_prompt_functionality_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/system_prompt_character_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/system_prompt_life_planning_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/system_prompt_formatting_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/system_prompt_mcp_integration_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/config_loader_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

echo "Completed at: $(date)" >> $OUTPUT_FILE

# Check if any tests failed
if grep -q "Some tests failed" $OUTPUT_FILE; then
  echo "❌ Some tests failed in Group 2. See $OUTPUT_FILE for details."
else
  echo "✅ All tests passed in Group 2!"
fi

echo "Test Group 2 completed. Results saved to $OUTPUT_FILE" 