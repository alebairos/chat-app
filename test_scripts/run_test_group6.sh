#!/bin/bash

echo "Running Test Group 6: Path Utils and Utility Tests"
echo "========================================"
echo "Started at: $(date)"
echo ""

# Create results directory if it doesn't exist
mkdir -p test_scripts/results

OUTPUT_FILE="test_scripts/results/test_results_group6.txt"

echo "Test Group 6: Path Utils and Utility Tests" > $OUTPUT_FILE
echo "=======================================" >> $OUTPUT_FILE
echo "Started at: $(date)" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Run the path utils tests
echo "Running basic path utils tests:" >> $OUTPUT_FILE
flutter test test/utils/path_utils_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

echo "Running path utils normalization tests:" >> $OUTPUT_FILE
flutter test test/utils/path_utils_normalization_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

echo "Running path utils file operations tests:" >> $OUTPUT_FILE
flutter test test/utils/path_utils_file_exists_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

echo "Running path utils integration tests:" >> $OUTPUT_FILE
flutter test test/utils/path_utils_integration_test.dart -v >> $OUTPUT_FILE 2>&1
echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

# Add space for any future utility tests
# flutter test test/utils/some_other_util_test.dart -v >> $OUTPUT_FILE 2>&1
# echo "\n-------------------------------------------\n" >> $OUTPUT_FILE

echo "Completed at: $(date)" >> $OUTPUT_FILE

# Check if any tests failed
if grep -q "Some tests failed" $OUTPUT_FILE; then
  echo "❌ Some tests failed in Group 6. See $OUTPUT_FILE for details."
else
  echo "✅ All tests passed in Group 6!"
fi

echo "Test Group 6 completed. Results saved to $OUTPUT_FILE" 