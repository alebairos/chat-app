# Test Organization and Execution

This directory contains scripts to run the tests for the Chat App in organized groups. The tests have been divided into 5 logical groups to make testing more manageable and to help isolate issues.

## Test Groups

### Group 1: Audio Recorder Tests
- `audio_recorder_test.dart`
- `audio_recorder_button_style_test.dart`
- `audio_recorder_delete_test.dart`
- `audio_recorder_error_handling_test.dart`
- Note: `audio_recorder_concurrency_test.dart` is skipped as it's marked with `@Skip` in the code

### Group 2: Audio Message and System Prompt Tests
- `audio_message_test.dart`
- `system_prompt_functionality_test.dart`
- `system_prompt_character_test.dart`
- `system_prompt_life_planning_test.dart`
- `system_prompt_formatting_test.dart`
- `config_loader_test.dart`

### Group 3: Claude Service Tests
- `claude_service_test.dart`
- `claude_service_error_handling_test.dart`
- `services/claude_service_test.dart`
- `services/claude_service_error_handling_test.dart`
- `services/claude_service_integration_test.dart`
- `chat_screen_error_handling_test.dart`
- `transcription_service_test.dart`

### Group 4: Life Plan Tests
- `life_plan_mcp_csv_loading_test.dart`
- `services/life_plan_service_test.dart`
- `services/life_plan_mcp_service_test.dart`
- `utf8_handling_test.dart`

### Group 5: Chat UI Tests
- `chat_screen_test.dart`
- `chat_message_test.dart`
- `chat_app_bar_test.dart`
- `chat_input_test.dart`
- `chat_storage_test.dart`
- `widget_test.dart`

## Running the Tests

### Running All Tests
To run all test groups sequentially:

```bash
chmod +x run_all_tests.sh
./run_all_tests.sh
```

This will execute all test groups and create a summary file `test_summary.txt` with the pass/fail status of each group.

### Running Individual Test Groups
To run a specific test group:

```bash
chmod +x run_test_group1.sh
./run_test_group1.sh
```

Replace `1` with the group number you want to run (1-5).

## Test Results
Each test group will generate a results file:
- `test_results_group1.txt`
- `test_results_group2.txt`
- `test_results_group3.txt`
- `test_results_group4.txt`
- `test_results_group5.txt`

These files contain the detailed output of each test run, including any failures or errors.

The `test_summary.txt` file provides a quick overview of which test groups passed or failed.

## Troubleshooting
If you encounter issues running the scripts:

1. Make sure all scripts are executable:
   ```bash
   chmod +x run_*.sh
   ```

2. Ensure Flutter is properly installed and in your PATH:
   ```bash
   flutter doctor
   ```

3. Check that all test dependencies are installed:
   ```bash
   flutter pub get
   ```

4. If specific tests are failing, check the corresponding results file for details. 