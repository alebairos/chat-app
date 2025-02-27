import '../models/life_plan_command.dart';
import '../models/life_plan_response.dart';
import '../../services/claude_service.dart';
import '../../config/config_loader.dart';
import 'package:flutter/foundation.dart';
import '../../models/life_plan/dimensions.dart';

/// Handles life plan commands and generates appropriate responses
class LifePlanCommandHandler {
  final ClaudeService _claudeService;
  final ConfigLoader _configLoader;
  bool _isInPlanningMode = false;
  Map<String, String>? _explorationPrompts;

  LifePlanCommandHandler({
    required ClaudeService claudeService,
    ConfigLoader? configLoader,
  })  : _claudeService = claudeService,
        _configLoader = configLoader ?? ConfigLoader() {
    debugPrint('🔧 LifePlanCommandHandler initialized');
    _loadExplorationPrompts();
  }

  /// Loads exploration prompts from configuration
  Future<void> _loadExplorationPrompts() async {
    try {
      _explorationPrompts = await _configLoader.loadExplorationPrompts();
      debugPrint('✅ Exploration prompts loaded successfully');
    } catch (e) {
      debugPrint('❌ Error loading exploration prompts: $e');
      // Set default prompts as fallback
      _explorationPrompts = {
        'physical': 'Tell me about physical health improvement paths.',
        'mental': 'Share mental wellbeing journeys available.',
        'relationships': 'Reveal paths to stronger relationships.',
        'spirituality': 'Illuminate the paths to spiritual growth and purpose.',
        'work':
            'Outline the journeys toward professional excellence and work-life harmony.'
      };
    }
  }

  /// Checks if the given text is a life plan command or dimension code
  bool isLifePlanCommand(String text) {
    final isCommand = LifePlanCommand.isCommand(text);
    if (!isCommand && _isInPlanningMode) {
      // Check if it's a dimension code while in planning mode
      try {
        LifePlanDimension.fromCode(text);
        return true;
      } catch (_) {
        return false;
      }
    }
    debugPrint(
        '🔍 Checking if text is a command: "$text" -> ${isCommand ? 'yes' : 'no'}');
    return isCommand;
  }

  /// Handles a life plan command and returns a response
  Future<String> handleCommand(String text) async {
    debugPrint('\n🎮 Handling command: "$text"');
    try {
      // Ensure prompts are loaded
      if (_explorationPrompts == null) {
        await _loadExplorationPrompts();
      }

      LifePlanCommand command;

      // Check if it's a dimension code while in planning mode
      if (_isInPlanningMode && !text.startsWith('/')) {
        try {
          final dimension = LifePlanDimension.fromCode(text);
          command = LifePlanCommand(
            type: LifePlanCommandType.explore,
            dimension: dimension,
          );
        } catch (_) {
          _isInPlanningMode = false;
          return LifePlanResponse.error(
                  'Invalid dimension code. Type /help for available commands.')
              .message;
        }
      } else {
        command = LifePlanCommand.fromText(text);
      }

      debugPrint('📋 Parsed command type: ${command.type}');
      if (command.dimension != null) {
        debugPrint('🎯 Command dimension: ${command.dimension!.code}');
      }

      LifePlanResponse response;

      switch (command.type) {
        case LifePlanCommandType.plan:
          debugPrint('📝 Generating plan response');
          _isInPlanningMode = true;
          response = LifePlanResponse.plan();
          break;

        case LifePlanCommandType.explore:
          if (command.dimension == null) {
            debugPrint('⚠️ No dimension specified for explore command');
            response = LifePlanResponse.explore(null);
          } else {
            debugPrint('🔍 Exploring dimension: ${command.dimension!.title}');
            try {
              final prompt = _getExplorationPrompt(command.dimension!);
              debugPrint('🤖 Sending exploration prompt to Claude');
              final claudeResponse = await _claudeService.sendMessage(prompt);
              debugPrint('✅ Received response from Claude');
              _isInPlanningMode = false;
              response = LifePlanResponse(message: claudeResponse);
            } catch (e) {
              debugPrint('❌ Error getting response from Claude: $e');
              _isInPlanningMode = false;
              response = LifePlanResponse.error(
                  'Error getting response from Claude: $e');
            }
          }
          break;

        case LifePlanCommandType.help:
          debugPrint('❓ Generating help response');
          _isInPlanningMode = false;
          response = LifePlanResponse.help();
          break;

        default:
          debugPrint('❓ Generating help response for unknown command');
          _isInPlanningMode = false;
          response = LifePlanResponse.help();
          break;
      }

      debugPrint('✅ Command handled successfully');
      return response.message;
    } catch (e) {
      debugPrint('❌ Error processing command: $e');
      _isInPlanningMode = false;
      return LifePlanResponse.error('Error processing command: $e').message;
    }
  }

  /// Generates a prompt for exploring a specific dimension
  String _getExplorationPrompt(LifePlanDimension dimension) {
    debugPrint(
        '📝 Generating exploration prompt for dimension: ${dimension.title}');

    // Get prompt from configuration based on dimension
    String? prompt;
    switch (dimension) {
      case LifePlanDimension.physical:
        prompt = _explorationPrompts?['physical'];
        break;
      case LifePlanDimension.mental:
        prompt = _explorationPrompts?['mental'];
        break;
      case LifePlanDimension.relationships:
        prompt = _explorationPrompts?['relationships'];
        break;
      case LifePlanDimension.spirituality:
        prompt = _explorationPrompts?['spirituality'];
        break;
      case LifePlanDimension.work:
        prompt = _explorationPrompts?['work'];
        break;
    }

    // If prompt is not found in configuration, use a default prompt
    if (prompt == null || prompt.isEmpty) {
      debugPrint(
          '⚠️ Exploration prompt not found in configuration, using default');
      prompt =
          "As Sergeant Oracle, tell me about the available paths for ${dimension.title.toLowerCase()} improvement. Use only data from the MCP database.";
    }

    debugPrint(
        '✅ Generated prompt: ${prompt.substring(0, prompt.length.clamp(0, 100))}...');
    return prompt;
  }
}
