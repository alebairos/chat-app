#!/bin/bash

echo "Running All Test Groups"
echo "========================================"
echo "Started at: $(date)"
echo ""

# Create results directory if it doesn't exist
mkdir -p test_scripts/results

# Make all scripts executable
chmod +x test_scripts/run_test_group1.sh
chmod +x test_scripts/run_test_group2.sh
chmod +x test_scripts/run_test_group3.sh
chmod +x test_scripts/run_test_group4.sh
chmod +x test_scripts/run_test_group5.sh

# Run each test group
echo "Starting Test Group 1..."
./test_scripts/run_test_group1.sh
GROUP1_STATUS=$?
echo ""

echo "Starting Test Group 2..."
./test_scripts/run_test_group2.sh
GROUP2_STATUS=$?
echo ""

echo "Starting Test Group 3..."
./test_scripts/run_test_group3.sh
GROUP3_STATUS=$?
echo ""

echo "Starting Test Group 4..."
./test_scripts/run_test_group4.sh
GROUP4_STATUS=$?
echo ""

echo "Starting Test Group 5..."
./test_scripts/run_test_group5.sh
GROUP5_STATUS=$?
echo ""

echo "All test groups completed at: $(date)"
echo "Results are saved in test_scripts/results/test_results_group*.txt files"

# Create a summary file
echo "Test Summary" > test_scripts/results/test_summary.txt
echo "=======================================" >> test_scripts/results/test_summary.txt
echo "Generated at: $(date)" >> test_scripts/results/test_summary.txt
echo "" >> test_scripts/results/test_summary.txt

# Add status for each group
echo "Group 1: Audio Recorder Tests" >> test_scripts/results/test_summary.txt
if [ $GROUP1_STATUS -eq 0 ] && ! grep -q "Some tests failed" test_scripts/results/test_results_group1.txt; then
  echo "✅ All tests passed" >> test_scripts/results/test_summary.txt
else
  echo "❌ Some tests failed" >> test_scripts/results/test_summary.txt
  # Extract failing test information
  grep -A 5 "The following tests failed" test_scripts/results/test_results_group1.txt >> test_scripts/results/test_summary.txt 2>/dev/null
fi
echo "" >> test_scripts/results/test_summary.txt

echo "Group 2: Audio Message and System Prompt Tests" >> test_scripts/results/test_summary.txt
if [ $GROUP2_STATUS -eq 0 ] && ! grep -q "Some tests failed" test_scripts/results/test_results_group2.txt; then
  echo "✅ All tests passed" >> test_scripts/results/test_summary.txt
else
  echo "❌ Some tests failed" >> test_scripts/results/test_summary.txt
  # Extract failing test information
  grep -A 5 "The following tests failed" test_scripts/results/test_results_group2.txt >> test_scripts/results/test_summary.txt 2>/dev/null
fi
echo "" >> test_scripts/results/test_summary.txt

echo "Group 3: Claude Service Tests" >> test_scripts/results/test_summary.txt
if [ $GROUP3_STATUS -eq 0 ] && ! grep -q "Some tests failed" test_scripts/results/test_results_group3.txt; then
  echo "✅ All tests passed" >> test_scripts/results/test_summary.txt
else
  echo "❌ Some tests failed" >> test_scripts/results/test_summary.txt
  # Extract failing test information
  grep -A 5 "The following tests failed" test_scripts/results/test_results_group3.txt >> test_scripts/results/test_summary.txt 2>/dev/null
fi
echo "" >> test_scripts/results/test_summary.txt

echo "Group 4: Life Plan Tests" >> test_scripts/results/test_summary.txt
if [ $GROUP4_STATUS -eq 0 ] && ! grep -q "Some tests failed" test_scripts/results/test_results_group4.txt; then
  echo "✅ All tests passed" >> test_scripts/results/test_summary.txt
else
  echo "❌ Some tests failed" >> test_scripts/results/test_summary.txt
  # Extract failing test information
  grep -A 5 "The following tests failed" test_scripts/results/test_results_group4.txt >> test_scripts/results/test_summary.txt 2>/dev/null
fi
echo "" >> test_scripts/results/test_summary.txt

echo "Group 5: Chat UI Tests" >> test_scripts/results/test_summary.txt
if [ $GROUP5_STATUS -eq 0 ] && ! grep -q "Some tests failed" test_scripts/results/test_results_group5.txt; then
  echo "✅ All tests passed" >> test_scripts/results/test_summary.txt
else
  echo "❌ Some tests failed" >> test_scripts/results/test_summary.txt
  # Extract failing test information
  grep -A 5 "The following tests failed" test_scripts/results/test_results_group5.txt >> test_scripts/results/test_summary.txt 2>/dev/null
fi
echo "" >> test_scripts/results/test_summary.txt

# Overall status
if [ $GROUP1_STATUS -eq 0 ] && [ $GROUP2_STATUS -eq 0 ] && [ $GROUP3_STATUS -eq 0 ] && [ $GROUP4_STATUS -eq 0 ] && [ $GROUP5_STATUS -eq 0 ] && 
   ! grep -q "Some tests failed" test_scripts/results/test_results_group*.txt; then
  echo "✅ ALL TEST GROUPS PASSED!" >> test_scripts/results/test_summary.txt
else
  echo "❌ SOME TEST GROUPS FAILED. See individual test results for details." >> test_scripts/results/test_summary.txt
fi

echo "Test summary saved to test_scripts/results/test_summary.txt"

# Print overall status to console
if [ $GROUP1_STATUS -eq 0 ] && [ $GROUP2_STATUS -eq 0 ] && [ $GROUP3_STATUS -eq 0 ] && [ $GROUP4_STATUS -eq 0 ] && [ $GROUP5_STATUS -eq 0 ] && 
   ! grep -q "Some tests failed" test_scripts/results/test_results_group*.txt; then
  echo "✅ ALL TEST GROUPS PASSED!"
else
  echo "❌ SOME TEST GROUPS FAILED. See test_scripts/results/test_summary.txt for details."
fi 