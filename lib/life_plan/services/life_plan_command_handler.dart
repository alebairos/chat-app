import '../models/life_plan_command.dart';
import '../models/life_plan_response.dart';
import '../../services/claude_service.dart';
import 'package:flutter/foundation.dart';

/// Handles life plan commands and generates appropriate responses
class LifePlanCommandHandler {
  final ClaudeService _claudeService;
  bool _isInPlanningMode = false;

  LifePlanCommandHandler({
    required ClaudeService claudeService,
  }) : _claudeService = claudeService {
    debugPrint('🔧 LifePlanCommandHandler initialized');
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
    String prompt;
    switch (dimension) {
      case LifePlanDimension.physical:
        prompt =
            "As Sergeant Oracle, tell me about the available paths for physical health improvement. "
            "Use the goals data to inform your response, but keep it conversational and inspiring. "
            "Maintain your character's voice and suggest next steps.";
        break;
      case LifePlanDimension.mental:
        prompt =
            "As Sergeant Oracle, share the mental wellbeing journeys available. "
            "Use the goals data to inform your response, but focus on inspiration and clear next steps. "
            "Keep your unique voice.";
        break;
      case LifePlanDimension.relationships:
        prompt =
            "As Sergeant Oracle, reveal the paths to stronger relationships. "
            "Use the goals data in your response, but maintain the conversation natural and engaging. "
            "Stay in character and guide them to next steps.";
        break;
    }
    debugPrint(
        '✅ Generated prompt: ${prompt.substring(0, prompt.length.clamp(0, 100))}...');
    return prompt;
  }
}
