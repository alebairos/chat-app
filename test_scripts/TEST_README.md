# Test Organization and Execution

This directory contains scripts to run tests for the Chat App in 6 organized groups.

## Test Groups

### Group 1: Audio Recorder Tests
- `audio_recorder_test.dart` - Core recorder functionality
- `audio_recorder_button_style_test.dart` - UI and styling
- `audio_recorder_delete_test.dart` - Audio deletion
- `audio_recorder_error_handling_test.dart` - Error handling

### Group 2: Audio Message and System Prompt Tests
- `audio_message_test.dart` - Basic audio message tests
- `audio_message_integration_test.dart` - Visual integration tests
- `system_prompt_*_test.dart` files - Various system prompt tests
- `config_loader_test.dart` - Configuration loading

### Group 3: Claude Service Tests
- `claude_service_test.dart` - API communication
- `claude_service_error_handling_test.dart` - Error handling
- `services/claude_service_*.dart` - Service integration
- `transcription_service_test.dart` - Audio transcription

### Group 4: Life Plan Tests
- `life_plan_mcp_csv_loading_test.dart` - Data loading
- `services/life_plan_service_test.dart` - Service functionality
- `services/life_plan_mcp_service_test.dart` - MCP service
- `utf8_handling_test.dart` - Character encoding

### Group 5: Chat UI Tests
- `chat_screen_test.dart` - Main screen functionality
- `chat_message_test.dart` - Message display
- `chat_app_bar_test.dart`, `chat_input_test.dart` - UI components
- `chat_storage_test.dart` - Data persistence
- `widget_test.dart` - General widget tests

### Group 6: Path Utils and Utility Tests
- `utils/path_utils_test.dart` - Basic path operations
- `utils/path_utils_normalization_test.dart` - Path normalization
- `utils/path_utils_file_exists_test.dart` - File existence checks
- `utils/path_utils_integration_test.dart` - Integration functionality

## Usage

### Running All Tests
```bash
chmod +x run_all_tests.sh
./run_all_tests.sh
```

### Running Specific Test Groups
```bash
chmod +x run_test_group<N>.sh
./run_test_group<N>.sh  # Replace <N> with 1-6
```

## Output Files
- Individual reports: `test_scripts/results/test_results_group<N>.txt`
- Summary report: `test_scripts/results/test_summary.txt`

## Troubleshooting
- Make scripts executable: `chmod +x run_*.sh`
- Check Flutter installation: `flutter doctor`
- Install dependencies: `flutter pub get`
- For failing tests, check the individual test results files 

## Relationship to Main README

This document provides detailed information about test organization and execution that supplements the main README.md. While the main README offers a high-level overview of the testing framework and coverage statistics, this document serves as the technical reference for running and managing tests.

Key connections between documents:
1. The main README references this document for detailed test execution instructions
2. Test statistics in the main README are derived from running these test scripts
3. For anyone working on test maintenance or development, start here
4. For project overview and general testing status, refer to the main README

If you modify the test organization or add new tests, please update both documents to maintain consistency. 