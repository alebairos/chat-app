#!/bin/bash

echo "Running Test Group 4: Life Plan Tests"
echo "========================================"
echo "Started at: $(date)"
echo ""

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

flutter test test/utf8_handling_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

echo "Completed at: $(date)" >> $OUTPUT_FILE
echo "Test Group 4 completed. Results saved to $OUTPUT_FILE" 