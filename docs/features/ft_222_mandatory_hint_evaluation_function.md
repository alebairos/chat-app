# FT-222: Mandatory Hint Evaluation Function

**Feature ID:** FT-222  
**Priority:** High  
**Category:** AI/ML Enhancement  
**Effort:** Medium (2-3 days)  
**Status:** Proposed  
**Related Features:** FT-200, FT-206, FT-220, FT-221

---

## Problem Statement

**Current Issue:** Pattern detection (FT-206) injects helpful hints into user messages, but the model often ignores them:

```
User message: "What did we talk about on Wednesday?"
Injected hint: [SYSTEM HINT: Conversation history query detected. 
                Use: {"action": "get_conversation_context", "hours": 72}]
```

**Model behavior:**
- ❌ Sees the hint but doesn't act on it
- ❌ Responds with "I only have access to recent conversations"
- ❌ Never generates the MCP command to query history

**Root cause:** The model treats hints as **optional suggestions** rather than **mandatory actions**.

---

## Proposed Solution: Forced Attention Mechanism

### Core Concept

Insert a **mandatory evaluation step** that forces the model to explicitly decide whether to execute deep queries based on detected hints.

### Two Implementation Approaches

---

## Approach A: Claude Tool Use (Native Function Calling)

**Leverage Claude's built-in tool/function calling capability.**

### How It Works

1. Define a `evaluate_hints` tool that Claude must call
2. Claude API returns tool use request
3. Your code executes the tool and returns results
4. Claude continues with the data

### API Structure

```dart
// Add tools parameter to Claude API request
final response = await _client.post(
  Uri.parse(_baseUrl),
  headers: {...},
  body: jsonEncode({
    'model': _model,
    'max_tokens': _maxTokens,
    'system': systemPrompt,
    'messages': messages,
    'tools': [
      {
        'name': 'evaluate_hints',
        'description': 'Evaluate system hints and determine if deep data queries are needed. '
                      'MUST be called when SYSTEM HINT tags are present in user messages.',
        'input_schema': {
          'type': 'object',
          'properties': {
            'hint_detected': {
              'type': 'boolean',
              'description': 'Whether a SYSTEM HINT was detected in the message'
            },
            'hint_type': {
              'type': 'string',
              'enum': ['conversation_history', 'temporal_activity', 'persona_context', 'none'],
              'description': 'Type of hint detected'
            },
            'should_execute': {
              'type': 'boolean',
              'description': 'Whether the hint suggests executing a deep query'
            },
            'suggested_action': {
              'type': 'string',
              'description': 'The MCP command suggested by the hint (if any)'
            }
          },
          'required': ['hint_detected', 'hint_type', 'should_execute']
        }
      }
    ],
    'tool_choice': {
      'type': 'auto' // or 'any' to force tool use
    }
  }),
);
```

### Response Handling

```dart
Future<String> _handleToolUseResponse(Map<String, dynamic> response) async {
  final content = response['content'] as List;
  
  for (var block in content) {
    if (block['type'] == 'tool_use') {
      final toolName = block['name'];
      final toolInput = block['input'];
      final toolUseId = block['id'];
      
      if (toolName == 'evaluate_hints') {
        // Model has evaluated the hint
        final shouldExecute = toolInput['should_execute'] as bool;
        final suggestedAction = toolInput['suggested_action'] as String?;
        
        if (shouldExecute && suggestedAction != null) {
          // Execute the MCP command
          _logger.info('FT-222: Model requested deep query: $suggestedAction');
          final result = await _systemMCP!.processCommand(suggestedAction);
          
          // Send tool result back to Claude
          return await _continueWithToolResult(
            toolUseId: toolUseId,
            result: result,
            originalMessages: messages,
          );
        }
      }
    }
  }
  
  // No tool use or no execution needed
  return _extractTextFromContent(content);
}

Future<String> _continueWithToolResult({
  required String toolUseId,
  required String result,
  required List<Map<String, dynamic>> originalMessages,
}) async {
  // Add tool result to conversation
  final continuationMessages = [
    ...originalMessages,
    {
      'role': 'assistant',
      'content': [
        {
          'type': 'tool_use',
          'id': toolUseId,
          'name': 'evaluate_hints',
          'input': {...}
        }
      ]
    },
    {
      'role': 'user',
      'content': [
        {
          'type': 'tool_result',
          'tool_use_id': toolUseId,
          'content': result
        }
      ]
    }
  ];
  
  // Continue conversation with tool result
  final response = await _client.post(
    Uri.parse(_baseUrl),
    headers: {...},
    body: jsonEncode({
      'model': _model,
      'max_tokens': _maxTokens,
      'system': systemPrompt,
      'messages': continuationMessages,
    }),
  );
  
  return _extractTextFromResponse(response);
}
```

### Pros & Cons

**Pros:**
- ✅ Native Claude API feature (official support)
- ✅ Model is **forced** to evaluate hints
- ✅ Structured output (guaranteed format)
- ✅ Clear separation of concerns
- ✅ Can be made mandatory with `tool_choice: 'any'`

**Cons:**
- ⚠️ Requires two API calls (initial + continuation)
- ⚠️ Higher latency (~2x response time)
- ⚠️ More complex error handling
- ⚠️ Additional token usage for tool definitions

**Token Impact:**
- Tool definition: ~200 tokens
- Tool use: ~100 tokens
- Tool result: ~500-2000 tokens (depending on query)
- **Total overhead:** ~800-2300 tokens per hint

---

## Approach B: Synthetic System Message (Simpler)

**Insert a mandatory evaluation message that the model must respond to.**

### How It Works

1. Detect hint in user message
2. Inject a system-level evaluation request
3. Model must explicitly answer the evaluation
4. Parse model's decision and execute if needed

### Implementation

```dart
Future<String> _sendMessageWithHintEvaluation(String message) async {
  // Detect if hint was injected
  final hasHint = message.contains('[SYSTEM HINT:');
  
  if (hasHint) {
    // Extract hint details
    final hintMatch = RegExp(r'\[SYSTEM HINT: (.*?)\]').firstMatch(message);
    final hintContent = hintMatch?.group(1) ?? '';
    
    // Add mandatory evaluation message
    final evaluationMessage = '''
$message

---
MANDATORY EVALUATION REQUIRED:
A SYSTEM HINT was detected in this message. You MUST evaluate it:

Hint: $hintContent

Answer these questions:
1. Should you execute the suggested action? (YES/NO)
2. If YES, provide the exact MCP command to execute.

Format your response as:
HINT_EVALUATION: [YES/NO]
MCP_COMMAND: [command if YES, otherwise NONE]

Then continue with your normal response.
''';
    
    return await _sendMessageInternal(evaluationMessage);
  }
  
  return await _sendMessageInternal(message);
}

Future<String> _processResponseWithEvaluation(String response) async {
  // Check if response contains evaluation
  if (response.contains('HINT_EVALUATION:')) {
    final evalMatch = RegExp(r'HINT_EVALUATION: (YES|NO)').firstMatch(response);
    final shouldExecute = evalMatch?.group(1) == 'YES';
    
    if (shouldExecute) {
      // Extract MCP command
      final cmdMatch = RegExp(r'MCP_COMMAND: (\{.*?\})').firstMatch(response);
      final mcpCommand = cmdMatch?.group(1);
      
      if (mcpCommand != null) {
        _logger.info('FT-222: Model decided to execute: $mcpCommand');
        
        // Execute the command
        final result = await _systemMCP!.processCommand(mcpCommand);
        final data = jsonDecode(result);
        
        if (data['status'] == 'success') {
          // Format the data
          final formattedData = _formatMCPResult(data);
          
          // Send follow-up message with data
          final followUpResponse = await _sendMessageInternal(
            'Here is the requested data:\n$formattedData\n\nPlease continue your response.'
          );
          
          // Remove evaluation markers from final response
          return _cleanEvaluationMarkers(followUpResponse);
        }
      }
    }
    
    // Remove evaluation markers even if not executed
    return _cleanEvaluationMarkers(response);
  }
  
  return response;
}

String _cleanEvaluationMarkers(String response) {
  return response
      .replaceAll(RegExp(r'HINT_EVALUATION: .*?\n'), '')
      .replaceAll(RegExp(r'MCP_COMMAND: .*?\n'), '')
      .replaceAll(RegExp(r'---\nMANDATORY EVALUATION.*?---\n', dotAll: true), '')
      .trim();
}
```

### Enhanced Version with Structured Prompt

```dart
String _buildMandatoryEvaluationPrompt(String userMessage, String hint) {
  return '''
$userMessage

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 MANDATORY SYSTEM EVALUATION REQUIRED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

A SYSTEM HINT has been detected. You MUST evaluate it before responding.

📋 DETECTED HINT:
$hint

❓ EVALUATION QUESTIONS (Answer ALL):

1. Is this hint relevant to the user's request? (YES/NO)
2. Should you execute the suggested MCP command? (YES/NO)
3. If YES to #2, provide the EXACT command to execute.

📝 REQUIRED FORMAT:
```evaluation
RELEVANT: [YES/NO]
EXECUTE: [YES/NO]
COMMAND: [JSON command or NONE]
```

⚠️ CRITICAL RULES:
- You MUST answer all evaluation questions
- If EXECUTE is YES, you MUST provide a valid JSON command
- After evaluation, continue with your normal response
- The evaluation section will be processed automatically

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
}
```

### Pros & Cons

**Pros:**
- ✅ Simple implementation (no API changes)
- ✅ Single API call (lower latency)
- ✅ Works with current infrastructure
- ✅ Easy to debug and iterate
- ✅ Lower token overhead

**Cons:**
- ⚠️ Model might still ignore the evaluation
- ⚠️ Requires careful prompt engineering
- ⚠️ Response parsing can be brittle
- ⚠️ Not as "forced" as tool use

**Token Impact:**
- Evaluation prompt: ~300 tokens
- Model evaluation: ~100 tokens
- **Total overhead:** ~400 tokens per hint

---

## Approach C: Hybrid (Recommended)

**Combine both approaches for maximum reliability.**

### Strategy

1. **Start with Approach B** (synthetic evaluation)
2. **Monitor success rate** via logging
3. **Fall back to Approach A** (tool use) if model ignores evaluation
4. **Gradually optimize** based on real-world performance

### Implementation

```dart
class HintEvaluationStrategy {
  final Logger _logger = Logger();
  int _ignoredEvaluations = 0;
  int _totalEvaluations = 0;
  
  Future<String> processMessageWithHint(
    String message,
    String hint,
    Function sendMessage,
    Function executeCommand,
  ) async {
    _totalEvaluations++;
    
    // Calculate success rate
    final successRate = _totalEvaluations > 0
        ? 1.0 - (_ignoredEvaluations / _totalEvaluations)
        : 1.0;
    
    // Choose strategy based on success rate
    if (successRate > 0.7) {
      // Synthetic evaluation is working well
      _logger.info('FT-222: Using synthetic evaluation (success rate: ${(successRate * 100).toStringAsFixed(1)}%)');
      return await _syntheticEvaluation(message, hint, sendMessage, executeCommand);
    } else {
      // Fall back to tool use
      _logger.warning('FT-222: Falling back to tool use (success rate too low: ${(successRate * 100).toStringAsFixed(1)}%)');
      return await _toolUseEvaluation(message, hint, sendMessage, executeCommand);
    }
  }
  
  Future<String> _syntheticEvaluation(...) async {
    // Approach B implementation
    final response = await sendMessage(
      _buildMandatoryEvaluationPrompt(message, hint)
    );
    
    // Check if model provided evaluation
    if (!response.contains('EXECUTE:')) {
      _ignoredEvaluations++;
      _logger.warning('FT-222: Model ignored synthetic evaluation');
      // Could retry with tool use here
    }
    
    return await _processEvaluationResponse(response, executeCommand);
  }
  
  Future<String> _toolUseEvaluation(...) async {
    // Approach A implementation
    return await _sendWithToolUse(message, hint, sendMessage, executeCommand);
  }
}
```

### Pros & Cons

**Pros:**
- ✅ Best of both worlds
- ✅ Self-optimizing based on performance
- ✅ Graceful degradation
- ✅ Lower latency when synthetic works
- ✅ Guaranteed execution with tool use fallback

**Cons:**
- ⚠️ More complex implementation
- ⚠️ Requires monitoring and metrics
- ⚠️ Higher maintenance overhead

---

## Comparison Matrix

| Aspect | Approach A (Tool Use) | Approach B (Synthetic) | Approach C (Hybrid) |
|--------|----------------------|------------------------|---------------------|
| **Reliability** | ⭐⭐⭐⭐⭐ (100%) | ⭐⭐⭐ (70-80%) | ⭐⭐⭐⭐⭐ (95%+) |
| **Latency** | ⭐⭐ (2x calls) | ⭐⭐⭐⭐⭐ (1 call) | ⭐⭐⭐⭐ (adaptive) |
| **Token Usage** | ⭐⭐ (800-2300) | ⭐⭐⭐⭐ (400) | ⭐⭐⭐ (400-2300) |
| **Implementation** | ⭐⭐⭐ (medium) | ⭐⭐⭐⭐⭐ (simple) | ⭐⭐ (complex) |
| **Maintenance** | ⭐⭐⭐⭐ (stable API) | ⭐⭐⭐ (prompt tuning) | ⭐⭐ (monitoring) |
| **User Experience** | ⭐⭐⭐ (slower) | ⭐⭐⭐⭐⭐ (fast) | ⭐⭐⭐⭐ (balanced) |

---

## Recommended Implementation Plan

### Phase 1: Proof of Concept (Day 1)

**Implement Approach B (Synthetic Evaluation)**

1. Create `_buildMandatoryEvaluationPrompt()` method
2. Implement evaluation response parsing
3. Add logging for success/failure tracking
4. Test with conversation history queries

**Success Criteria:**
- Model responds with evaluation 80%+ of time
- MCP commands are executed when evaluation says YES
- Response quality remains high

### Phase 2: Production Deployment (Day 2)

**Deploy and Monitor**

1. Enable for all users
2. Track metrics:
   - Evaluation response rate
   - MCP execution rate
   - User satisfaction (implicit via continued usage)
3. A/B test with and without mandatory evaluation

**Success Criteria:**
- Long-term memory queries work 80%+ of time
- No significant increase in response time
- User engagement improves

### Phase 3: Optimization (Day 3)

**Implement Approach C (Hybrid) if needed**

1. Add tool use fallback for ignored evaluations
2. Implement adaptive strategy selection
3. Optimize prompt wording based on failures
4. Fine-tune evaluation format

**Success Criteria:**
- 95%+ success rate for hint execution
- Minimal latency impact
- Self-optimizing system

---

## Code Changes Required

### 1. Pattern Detection Service (FT-206)

```dart
// lib/services/pattern_detection_service.dart

class PatternDetectionService {
  // Add flag to indicate mandatory evaluation needed
  PatternDetectionResult detectPatterns(String message) {
    final result = PatternDetectionResult();
    
    // ... existing pattern detection ...
    
    if (result.hasHint) {
      result.requiresMandatoryEvaluation = true;  // NEW
      result.evaluationPrompt = _buildEvaluationPrompt(result.hint);  // NEW
    }
    
    return result;
  }
}

class PatternDetectionResult {
  bool hasHint = false;
  String? hint;
  bool requiresMandatoryEvaluation = false;  // NEW
  String? evaluationPrompt;  // NEW
}
```

### 2. Claude Service

```dart
// lib/services/claude_service.dart

Future<String> _sendMessageInternal(String message) async {
  // ... existing code ...
  
  // FT-222: Check if mandatory evaluation is needed
  final patternResult = PatternDetectionService.detectPatterns(message);
  
  if (patternResult.requiresMandatoryEvaluation) {
    _logger.info('FT-222: Mandatory hint evaluation required');
    return await _sendWithMandatoryEvaluation(
      message,
      patternResult.hint!,
      patternResult.evaluationPrompt!,
    );
  }
  
  // ... rest of existing code ...
}

Future<String> _sendWithMandatoryEvaluation(
  String message,
  String hint,
  String evaluationPrompt,
) async {
  // Send message with evaluation prompt
  final response = await _sendToAPI(evaluationPrompt);
  
  // Process evaluation response
  return await _processEvaluationResponse(response, hint);
}
```

### 3. Configuration

```json
// assets/config/hint_evaluation_config.json
{
  "enabled": true,
  "strategy": "synthetic",  // "synthetic", "tool_use", or "hybrid"
  "fallback_to_tool_use": true,
  "success_rate_threshold": 0.7,
  "evaluation_format": "structured",
  "retry_on_failure": true,
  "max_retries": 1,
  "logging": {
    "track_success_rate": true,
    "log_ignored_evaluations": true,
    "alert_on_low_success_rate": true
  }
}
```

---

## Testing Strategy

### Unit Tests

```dart
test('FT-222: Mandatory evaluation prompt is generated', () {
  final message = 'What did we talk about yesterday?';
  final hint = 'Use: {"action": "get_conversation_context", "hours": 24}';
  
  final prompt = _buildMandatoryEvaluationPrompt(message, hint);
  
  expect(prompt, contains('MANDATORY EVALUATION'));
  expect(prompt, contains(hint));
  expect(prompt, contains('EXECUTE:'));
});

test('FT-222: Evaluation response is parsed correctly', () {
  final response = '''
```evaluation
RELEVANT: YES
EXECUTE: YES
COMMAND: {"action": "get_conversation_context", "hours": 24}
```

Based on the conversation history...
''';
  
  final result = _parseEvaluationResponse(response);
  
  expect(result.shouldExecute, true);
  expect(result.command, isNotNull);
  expect(result.command!['action'], 'get_conversation_context');
});
```

### Integration Tests

```dart
testWidgets('FT-222: Long-term memory query works with mandatory evaluation', 
  (tester) async {
  // Setup: Create conversation history from 3 days ago
  await _createOldConversation(daysAgo: 3);
  
  // Send query about old conversation
  await tester.enterText(find.byType(TextField), 
    'What did we talk about on Wednesday?');
  await tester.tap(find.byIcon(Icons.send));
  await tester.pumpAndSettle();
  
  // Verify: Response includes information from 3 days ago
  expect(find.textContaining('Wednesday'), findsOneWidget);
  expect(find.textContaining('sleep schedule'), findsOneWidget);
});
```

---

## Metrics and Monitoring

### Key Metrics

1. **Evaluation Response Rate**
   - % of times model provides evaluation when prompted
   - Target: >90%

2. **Execution Success Rate**
   - % of times MCP command is executed when evaluation says YES
   - Target: >95%

3. **Query Success Rate**
   - % of times user gets correct answer to long-term memory queries
   - Target: >85%

4. **Latency Impact**
   - Average response time increase
   - Target: <500ms increase

5. **Token Usage**
   - Average tokens per request with evaluation
   - Target: <500 token increase

### Dashboard

```dart
class HintEvaluationMetrics {
  int totalHints = 0;
  int evaluationsProvided = 0;
  int commandsExecuted = 0;
  int queriesSuccessful = 0;
  
  double get evaluationRate => evaluationsProvided / totalHints;
  double get executionRate => commandsExecuted / evaluationsProvided;
  double get successRate => queriesSuccessful / commandsExecuted;
  
  Map<String, dynamic> toJson() => {
    'total_hints': totalHints,
    'evaluation_rate': evaluationRate,
    'execution_rate': executionRate,
    'success_rate': successRate,
    'overall_effectiveness': evaluationRate * executionRate * successRate,
  };
}
```

---

## Expected Results

### Before FT-222

```
User: "What did we talk about on Wednesday?"
Hint: [SYSTEM HINT: Use get_conversation_context, hours: 72]

Model: "I only have access to recent conversations from yesterday onwards..."
Result: ❌ No query executed, user gets incomplete answer
```

### After FT-222 (Approach B)

```
User: "What did we talk about on Wednesday?"
Hint: [SYSTEM HINT: Use get_conversation_context, hours: 72]

Evaluation Prompt: [MANDATORY EVALUATION REQUIRED...]

Model Response:
```evaluation
RELEVANT: YES
EXECUTE: YES
COMMAND: {"action": "get_conversation_context", "hours": 72}
```

System: [Executes command, retrieves Wednesday conversation]

Model: "On Wednesday, we discussed your sleep schedule and gym plans. 
You mentioned wanting to sleep by 11 PM on Tuesday to wake up early 
for the gym at 6 AM on Wednesday morning..."

Result: ✅ Query executed, user gets complete answer
```

---

## Rollout Plan

### Week 1: Development
- Day 1: Implement Approach B (synthetic evaluation)
- Day 2: Add logging and metrics
- Day 3: Internal testing and refinement

### Week 2: Beta Testing
- Day 4-5: Deploy to beta testers (10% of users)
- Day 6-7: Monitor metrics and gather feedback

### Week 3: Production
- Day 8: Deploy to 50% of users (A/B test)
- Day 9-10: Monitor and optimize
- Day 11: Full rollout if metrics are good

### Week 4: Optimization
- Day 12-14: Implement Approach C (hybrid) if needed
- Continue monitoring and iterating

---

## Risk Mitigation

### Risk 1: Model Still Ignores Evaluation

**Mitigation:**
- Start with very explicit, visually distinct prompts
- Add multiple redundant cues (emoji, borders, caps)
- Fall back to tool use (Approach A) if success rate < 70%

### Risk 2: Increased Latency

**Mitigation:**
- Use Approach B by default (single API call)
- Only use Approach A when necessary
- Implement caching for frequently accessed data

### Risk 3: Token Cost Increase

**Mitigation:**
- Optimize evaluation prompt length
- Cache MCP results to avoid repeated queries
- Monitor cost per conversation and set alerts

### Risk 4: Response Quality Degradation

**Mitigation:**
- A/B test with control group
- Monitor user engagement metrics
- Allow users to disable feature if needed

---

## Success Criteria

### Must Have (Launch Blockers)

- ✅ Evaluation response rate > 80%
- ✅ MCP execution when evaluation says YES > 90%
- ✅ No increase in error rate
- ✅ Response time increase < 1 second

### Should Have (Post-Launch Goals)

- ✅ Long-term memory query success > 85%
- ✅ User satisfaction maintained or improved
- ✅ Token cost increase < 20%

### Nice to Have (Future Enhancements)

- ✅ Self-optimizing based on success rate
- ✅ Personalized evaluation strategies per user
- ✅ Predictive hint injection

---

## Conclusion

**Mandatory hint evaluation** solves the core problem: the model sees hints but doesn't act on them. By forcing explicit evaluation, we ensure:

1. ✅ Model **must** consider the hint
2. ✅ Decision is **logged** and **trackable**
3. ✅ Execution is **guaranteed** when evaluation says YES
4. ✅ System can **adapt** based on success rate

**Recommended approach:** Start with **Approach B (Synthetic Evaluation)** for simplicity and speed, with **Approach C (Hybrid)** as the long-term goal for maximum reliability.

---

**Next Steps:**
1. Review and approve this proposal
2. Implement Approach B (1 day)
3. Test with real conversations
4. Deploy to beta users
5. Monitor and optimize

**Document Version:** 1.0  
**Last Updated:** October 25, 2025  
**Author:** FT-222 Proposal

