#!/bin/bash

echo "Running Test Group 4: Life Plan Tests"
echo "========================================"
echo "Started at: $(date)"
echo ""

# Create results directory if it doesn't exist
mkdir -p test_scripts/results

OUTPUT_FILE="test_scripts/results/test_results_group4.txt"

echo "Test Group 4: Life Plan Tests" > $OUTPUT_FILE
echo "=======================================" >> $OUTPUT_FILE
echo "Started at: $(date)" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Run each test file and append results to output file
flutter test test/life_plan_mcp_csv_loading_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/services/life_plan_service_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/services/life_plan_mcp_service_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/services/life_plan_integration_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/life_plan/models/life_plan_command_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/life_plan/models/life_plan_response_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/life_plan/services/life_plan_command_handler_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/models/life_plan/dimensions_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/models/life_plan/goal_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/models/life_plan/habit_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/models/life_plan/track_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

flutter test test/utf8_handling_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

echo "Completed at: $(date)" >> $OUTPUT_FILE

# Check if any tests failed
if grep -q "Some tests failed" $OUTPUT_FILE; then
  echo "❌ Some tests failed in Group 4. See $OUTPUT_FILE for details."
else
  echo "✅ All tests passed in Group 4!"
fi

echo "Test Group 4 completed. Results saved to $OUTPUT_FILE" 