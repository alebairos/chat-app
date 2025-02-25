#!/bin/bash

echo "Running All Test Groups"
echo "========================================"
echo "Started at: $(date)"
echo ""

# Make all scripts executable
chmod +x test_scripts/run_test_group1.sh
chmod +x test_scripts/run_test_group2.sh
chmod +x test_scripts/run_test_group3.sh
chmod +x test_scripts/run_test_group4.sh
chmod +x test_scripts/run_test_group5.sh

# Run each test group
echo "Starting Test Group 1..."
./test_scripts/run_test_group1.sh
echo ""

echo "Starting Test Group 2..."
./test_scripts/run_test_group2.sh
echo ""

echo "Starting Test Group 3..."
./test_scripts/run_test_group3.sh
echo ""

echo "Starting Test Group 4..."
./test_scripts/run_test_group4.sh
echo ""

echo "Starting Test Group 5..."
./test_scripts/run_test_group5.sh
echo ""

echo "All test groups completed at: $(date)"
echo "Results are saved in test_scripts/results/test_results_group*.txt files"

# Create a summary file
echo "Test Summary" > test_scripts/results/test_summary.txt
echo "=======================================" >> test_scripts/results/test_summary.txt
echo "Generated at: $(date)" >> test_scripts/results/test_summary.txt
echo "" >> test_scripts/results/test_summary.txt

# Extract pass/fail information from each result file
echo "Group 1: Audio Recorder Tests" >> test_scripts/results/test_summary.txt
grep -E "All tests passed|Some tests failed" test_scripts/results/test_results_group1.txt >> test_scripts/results/test_summary.txt
echo "" >> test_scripts/results/test_summary.txt

echo "Group 2: Audio Message and System Prompt Tests" >> test_scripts/results/test_summary.txt
grep -E "All tests passed|Some tests failed" test_scripts/results/test_results_group2.txt >> test_scripts/results/test_summary.txt
echo "" >> test_scripts/results/test_summary.txt

echo "Group 3: Claude Service Tests" >> test_scripts/results/test_summary.txt
grep -E "All tests passed|Some tests failed" test_scripts/results/test_results_group3.txt >> test_scripts/results/test_summary.txt
echo "" >> test_scripts/results/test_summary.txt

echo "Group 4: Life Plan Tests" >> test_scripts/results/test_summary.txt
grep -E "All tests passed|Some tests failed" test_scripts/results/test_results_group4.txt >> test_scripts/results/test_summary.txt
echo "" >> test_scripts/results/test_summary.txt

echo "Group 5: Chat UI Tests" >> test_scripts/results/test_summary.txt
grep -E "All tests passed|Some tests failed" test_scripts/results/test_results_group5.txt >> test_scripts/results/test_summary.txt
echo "" >> test_scripts/results/test_summary.txt

echo "Test summary saved to test_scripts/results/test_summary.txt" 