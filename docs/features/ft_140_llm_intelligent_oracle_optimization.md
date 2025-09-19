# FT-140: LLM-Intelligent Oracle Optimization via MCP Integration

**Feature ID:** FT-140  
**Priority:** Critical  
**Category:** Performance Optimization / MCP Integration  
**Effort Estimate:** 2-3 days  
**Status:** Specification (MCP-Integrated)  

## Problem Statement

**CRITICAL ISSUE IDENTIFIED**: Phase 1 implementation violates Oracle methodology compliance and conflicts with MCP system architecture.

### **Oracle Methodology Violations:**
- **Pre-selection filtering**: Only 15-30 activities visible to detection LLM
- **Invisible activities**: 235+ activities cannot be detected if not pre-selected
- **False compliance claims**: "All 265 activities accessible" is demonstrably false
- **Methodology integrity broken**: Oracle's comprehensive approach compromised

### **MCP System Conflicts:**
- **System prompt explosion**: 18,500+ tokens (MCP + Oracle + Persona + Audio)
- **Missing Oracle MCP commands**: No `oracle_detect_activities` integration
- **Architectural mismatch**: Background detection bypasses MCP system
- **Token budget violation**: 6x over optimization target

### **Current System Prompt Analysis:**
```
System Prompt Composition:
- MCP Instructions: ~2,000 tokens
- Oracle Prompt 4.2: ~15,000 tokens (full descriptions)
- Persona Prompt: ~1,000 tokens  
- Audio Instructions: ~500 tokens
Total: ~18,500 tokens per conversation (CRITICAL)
```

**Impact**: System violates both Oracle methodology and performance targets

## Core Principles (CORRECTED)

### 1. **MCP-First Integration** 
- **Integrate Oracle optimization WITH MCP system** - not around it
- **Preserve existing MCP commands** - `get_activity_stats`, `get_current_time` unchanged
- **Add Oracle-specific MCP commands** - `oracle_detect_activities`, `oracle_query_activities`
- **Maintain two-pass MCP flow** - enhance with Oracle capabilities

### 2. **Oracle Methodology STRICT Compliance**
- **All 265 activities ALWAYS accessible** - via compact format + MCP commands
- **No pre-filtering or activity hiding** - complete Oracle universe visible
- **Static cache + compact representation** - optimize FORMAT not CONTENT
- **Single source of truth** - Oracle 4.2 JSON loaded once at app start

### 3. **System Prompt Optimization**
- **75% token reduction** - 18,500 → 4,500 tokens
- **Compact Oracle format** - `SF1:Água,SF2:Exercício,...` (1,000 tokens vs 15,000)
- **MCP-based activity detection** - Oracle access via commands, not prompt bloat
- **Preserve all existing functionality** - TTS, qualification, error handling

## Technical Architecture (MCP-INTEGRATED)

### **Static Oracle Cache (App Startup)**

```dart
/// Oracle Static Cache - Loaded once at app start
class OracleStaticCache {
  static String? _compactOracleContext;
  static Map<String, OracleActivity>? _activityLookup;
  static bool _isInitialized = false;
  
  /// Initialize at app startup - one-time loading
  static Future<void> initializeAtStartup() async {
    Logger().info('🧠 Initializing Oracle static cache...');
    
    // Load Oracle 4.2 JSON (one-time file I/O)
    final oracleData = await _loadOracle42();
    
    // Create compact LLM format: ALL 265 activities
    _compactOracleContext = _buildCompactLLMFormat(oracleData);
    
    // Build fast lookup for post-processing
    _activityLookup = _buildActivityLookup(oracleData);
    
    Logger().info('✅ Oracle cache ready: ${_activityLookup!.length} activities');
    _isInitialized = true;
  }
  
  /// Get compact representation of ALL Oracle activities
  static String getCompactOracleForLLM() {
    if (!_isInitialized) throw StateError('Oracle cache not initialized');
    return _compactOracleContext!;
  }
  
  /// Compact format: SF1:Água,SF2:Exercício,R1:Escuta,E1:Gratidão,...
  static String _buildCompactLLMFormat(OracleData oracle) {
    return oracle.activities
        .map((a) => '${a.code}:${a.name}')
        .join(',');
  }
}
```

### **Enhanced MCP Service with Oracle Commands**

```dart
/// Enhanced SystemMCPService with Oracle integration
class SystemMCPService {
  Future<String> processCommand(String command) async {
    final cmd = jsonDecode(command);
    
    switch (cmd['action']) {
      // Existing MCP commands (UNCHANGED)
      case 'get_current_time': return _getCurrentTime();
      case 'get_activity_stats': return await _getActivityStats(cmd['days'] ?? 0);
      case 'get_message_stats': return await _getMessageStats(cmd['limit'] ?? 10);
      
      // NEW: Oracle-specific MCP commands
      case 'oracle_detect_activities':
        return await _oracleDetectActivities(cmd);
      case 'oracle_query_activities':
        return await _oracleQueryActivities(cmd);
      case 'oracle_get_compact_context':
        return await _getCompactOracleContext();
        
      default:
        return _errorResponse('Unknown action: ${cmd['action']}');
    }
  }
  
  /// Oracle activity detection via MCP (maintains full 265-activity access)
  Future<String> _oracleDetectActivities(Map<String, dynamic> cmd) async {
    final userMessage = cmd['message'] as String;
    
    // Get ALL 265 activities in compact format from static cache
    final compactOracle = OracleStaticCache.getCompactOracleForLLM();
    
    // Single LLM call with complete Oracle context
    final prompt = '''
User message: "$userMessage"
Oracle activities (ALL 265): $compactOracle

Analyze semantically and detect completed activities.
Return JSON: {"activities": [{"code": "SF1", "confidence": "high"}]}
''';
    
    final response = await _callClaude(prompt);
    final activities = _parseDetectionResults(response);
    
    return jsonEncode({
      'status': 'success',
      'data': {
        'detected_activities': activities.map((a) => a.toJson()).toList(),
        'oracle_context_size': compactOracle.length,
        'total_activities_available': 265,
        'method': 'mcp_oracle_detection'
      }
    });
  }
}
```

### **MCP-Integrated Activity Detection (CORRECTED)**

```dart
/// CORRECTED: MCP-based Oracle activity detection
Future<void> _processBackgroundActivitiesWithQualification(
    String userMessage, String qualificationResponse) async {
  
  // Existing qualification logic (UNCHANGED)
  if (!_shouldAnalyzeUserActivities(qualificationResponse)) {
    _logger.info('Activity analysis: Skipped - message not activity-focused');
    return;
  }

  // CORRECTED: MCP-based Oracle detection (preserves all 265 activities)
  await _mcpOracleActivityDetection(userMessage);
}

/// NEW: MCP-based Oracle activity detection with full methodology compliance
Future<void> _mcpOracleActivityDetection(String userMessage) async {
  try {
    _logger.debug('FT-140: Starting MCP Oracle activity detection');
    
    // Use MCP command for Oracle activity detection
    final mcpCommand = jsonEncode({
      'action': 'oracle_detect_activities',
      'message': userMessage,
    });
    
    // Process via MCP system (maintains full Oracle context)
    final result = await _systemMCP!.processCommand(mcpCommand);
    final data = jsonDecode(result);
    
    if (data['status'] == 'success') {
      final detectedActivities = data['data']['detected_activities'] as List;
      _logger.info('FT-140: ✅ Detected ${detectedActivities.length} activities via MCP');
      
      // Process detected activities using existing infrastructure
      await _processDetectedActivitiesFromMCP(detectedActivities, userMessage);
    }
    
  } catch (e) {
    _logger.warning('FT-140: MCP Oracle detection failed gracefully: $e');
    // Fallback to original method
    await _analyzeUserActivitiesWithFullContext(userMessage);
  }
}

/// Process activities detected via MCP Oracle detection
Future<void> _processDetectedActivitiesFromMCP(
    List<dynamic> detectedActivities, String userMessage) async {
  
  if (detectedActivities.isEmpty) return;
  
  final timeData = await _getCurrentTimeData();
  
  // Convert MCP results to ActivityDetection objects
  final activities = detectedActivities.map((data) => ActivityDetection.fromJson(data)).toList();
  
  // Use existing activity logging infrastructure
  await _logActivitiesWithPreciseTime(
    activities: activities,
    timeContext: timeData,
  );
  
  _logger.info('FT-140: ✅ Successfully logged ${activities.length} activities via MCP');
}
```

### **Optimized System Prompt Composition**

```dart
/// CORRECTED: System prompt with compact Oracle integration
Future<String> loadSystemPrompt() async {
  String finalPrompt = '';
  
  // 1. MCP Instructions (enhanced with Oracle commands)
  final mcpInstructions = await buildMcpInstructionsText();
  if (mcpInstructions.isNotEmpty) {
    finalPrompt = mcpInstructions.trim();
  }
  
  // 2. Oracle Context (COMPACT format - not full descriptions)
  if (await isOracleEnabled()) {
    await OracleStaticCache.initializeAtStartup(); // Ensure cache ready
    final compactOracle = OracleStaticCache.getCompactOracleForLLM();
    
    finalPrompt += '\n\n## ORACLE ACTIVITIES AVAILABLE\n';
    finalPrompt += 'Complete Oracle 4.2 context (265 activities): $compactOracle\n';
    finalPrompt += 'Use oracle_detect_activities MCP command for activity detection.\n';
    finalPrompt += 'All activities accessible via MCP - Oracle methodology preserved.\n';
  }
  
  // 3. Persona Prompt
  finalPrompt += '\n\n$personaPrompt';
  
  // 4. Audio Instructions (if enabled)
  if (audioInstructions.isNotEmpty) {
    finalPrompt += audioInstructions;
  }
  
  return finalPrompt;
}
```

### **Token Usage Optimization Results**

```
📊 SYSTEM PROMPT TOKEN ANALYSIS:

Before (Current System):
- MCP Instructions: ~2,000 tokens
- Oracle Full Descriptions: ~15,000 tokens  
- Persona Prompt: ~1,000 tokens
- Audio Instructions: ~500 tokens
Total: ~18,500 tokens per conversation

After (MCP-Integrated Optimization):
- MCP Instructions (enhanced): ~2,200 tokens
- Oracle Compact Format: ~1,000 tokens
- Persona Prompt: ~1,000 tokens  
- Audio Instructions: ~500 tokens
Total: ~4,700 tokens per conversation

Reduction: 75% (18,500 → 4,700 tokens)
Oracle Access: 100% (all 265 activities via MCP)
```
```

## **MCP Integration Requirements**

### **Enhanced MCP Instructions Config:**

```json
{
  "available_functions": [
    {
      "name": "oracle_detect_activities",
      "description": "Detect Oracle activities using complete 265-activity context",
      "usage": "{\"action\": \"oracle_detect_activities\", \"message\": \"user's exact message\"}",
      "oracle_compliance": "Maintains access to all 265 Oracle activities via compact representation",
      "token_efficiency": "Uses compact format (1,000 tokens vs 15,000 full descriptions)"
    },
    {
      "name": "oracle_query_activities",
      "description": "Query specific Oracle activities by codes or semantic search", 
      "usage": "{\"action\": \"oracle_query_activities\", \"query\": \"exercise water\", \"codes\": [\"SF1\", \"SF2\"]}"
    },
    {
      "name": "oracle_get_compact_context",
      "description": "Get compact representation of all Oracle activities",
      "usage": "{\"action\": \"oracle_get_compact_context\"}",
      "returns": "Comma-separated list: SF1:Água,SF2:Exercício,R1:Escuta,..."
    }
  ]
}
```

### **App Initialization Integration:**

```dart
// In main.dart or splash screen
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Oracle static cache at app start
  await OracleStaticCache.initializeAtStartup();
  
  runApp(MyApp());
}
```

### **Token Usage Comparison:**

```
📊 MCP-INTEGRATED OPTIMIZATION RESULTS:

System Prompt Optimization:
- Before: 18,500 tokens (MCP + Full Oracle + Persona + Audio)
- After: 4,700 tokens (MCP + Compact Oracle + Persona + Audio)
- Reduction: 75% token savings

Activity Detection Optimization:
- Before: 6,000+ tokens per detection (background process)
- After: 1,000 tokens per MCP command (oracle_detect_activities)
- Reduction: 83% token savings

Overall Performance:
- System prompt: 75% reduction (18,500 → 4,700)
- Activity detection: 83% reduction (6,000 → 1,000)
- Oracle access: 100% preserved (all 265 activities)
- Rate limit risk: CRITICAL → LOW
```
```

### **Critical Issue Resolution:**

#### **❌ Phase 1 Implementation Problems (FIXED):**
```dart
// BROKEN: Pre-selection violates Oracle methodology
final selectedCodes = await LLMActivityPreSelector.selectRelevantActivities(
  userMessage, maxActivities: 15  // Only 15 out of 265 activities!
);
// Result: 250 activities INVISIBLE to detection LLM
```

#### **✅ MCP-Integrated Solution (CORRECT):**
```dart
// CORRECT: All 265 activities accessible via MCP
final mcpCommand = jsonEncode({
  'action': 'oracle_detect_activities',
  'message': userMessage,  // LLM sees ALL activities in compact format
});
final result = await _systemMCP!.processCommand(mcpCommand);
// Result: Complete Oracle methodology preserved
```

### **Safety Validation Framework:**

```dart
/// Oracle Methodology Compliance Validator
class OracleComplianceValidator {
  /// Verify all 265 activities are accessible
  static Future<bool> validateOracleAccess() async {
    final compactOracle = OracleStaticCache.getCompactOracleForLLM();
    final activityCount = compactOracle.split(',').length;
    
    if (activityCount != 265) {
      Logger().error('Oracle compliance VIOLATED: Only $activityCount/265 activities accessible');
      return false;
    }
    
    Logger().info('✅ Oracle compliance VERIFIED: All 265 activities accessible');
    return true;
  }
  
  /// Test activity detection coverage
  static Future<void> testDetectionCoverage() async {
    final testCases = [
      'Bebi água',           // Should detect SF1
      'Fiz exercício',       // Should detect SF2, SF3, etc.
      'Meditated for 10min', // Should detect SM1, SM2, etc.
      'Trabajé en proyecto', // Should detect TG activities
    ];
    
    for (final testCase in testCases) {
      final result = await _testOracleDetection(testCase);
      Logger().info('Test "$testCase": ${result.length} activities detected');
    }
  }
}
```

### **System Integration Validation:**

#### **TTS Pipeline Safety (UNCHANGED):**
```dart
// TTS Flow remains completely unaffected
final textResponse = await sendMessage(message);  // Clean text
final cleanedResponse = _cleanResponseForUser(textResponse);  // Remove markers
final processedText = TTSTextProcessor.processForTTS(cleanedResponse);  // Format
final audioPath = await elevenLabs.generateSpeech(processedText);  // Generate

// Activity Detection (NOW via MCP - background only):
_processBackgroundActivitiesWithQualification(message, rawResponse);
```

#### **MCP System Compatibility:**
```dart
// Existing MCP commands preserved (UNCHANGED)
case 'get_current_time': return _getCurrentTime();
case 'get_activity_stats': return await _getActivityStats(days);
case 'get_message_stats': return await _getMessageStats(limit);

// New Oracle MCP commands added (ENHANCED)
case 'oracle_detect_activities': return await _oracleDetectActivities(cmd);
case 'oracle_query_activities': return await _oracleQueryActivities(cmd);
```

#### **Performance Benefits:**
- **75% system prompt reduction** → Faster conversation initialization
- **83% activity detection reduction** → Lower rate limiting risk
- **Static cache loading** → Eliminates file I/O per query
- **MCP integration** → Unified system architecture
- **Oracle compliance** → All 265 activities always accessible
```

## **Implementation Plan (MCP-INTEGRATED)**

### **Phase 1: Static Cache & MCP Integration (1 day)**

**Files to Create/Modify:**
1. **Create `lib/services/oracle_static_cache.dart`**:
   - Implement static Oracle cache with app startup loading
   - Build compact LLM format for all 265 activities
   - Add fast lookup and validation methods

2. **Enhance `lib/services/system_mcp_service.dart`**:
   - Add `oracle_detect_activities` MCP command
   - Add `oracle_query_activities` MCP command  
   - Add `oracle_get_compact_context` MCP command

3. **Modify `lib/services/claude_service.dart`**:
   - Replace broken pre-selection with MCP-based detection
   - Integrate `oracle_detect_activities` command usage
   - Maintain existing qualification and error handling

**Implementation Steps:**
```dart
// Step 1: Static Oracle Cache
class OracleStaticCache {
  static Future<void> initializeAtStartup() async {
    // Load Oracle 4.2 JSON once
    // Build compact format: SF1:Água,SF2:Exercício,...
    // Create fast lookup structures
  }
  
  static String getCompactOracleForLLM() {
    // Return ALL 265 activities in compact format
  }
}

// Step 2: Enhanced MCP Service
class SystemMCPService {
  Future<String> _oracleDetectActivities(Map<String, dynamic> cmd) async {
    final compactOracle = OracleStaticCache.getCompactOracleForLLM();
    // Single LLM call with ALL activities visible
    // Return detected activities with full Oracle compliance
  }
}

// Step 3: MCP-Integrated Detection
Future<void> _mcpOracleActivityDetection(String userMessage) async {
  final mcpCommand = jsonEncode({
    'action': 'oracle_detect_activities',
    'message': userMessage,
  });
  final result = await _systemMCP!.processCommand(mcpCommand);
  // Process results using existing infrastructure
}
```
```

### **Phase 2: System Prompt Optimization (1 day)**

**Files to Modify:**
1. **Update `assets/config/mcp_instructions_config.json`**:
   - Add Oracle MCP commands documentation
   - Include usage examples and Oracle compliance notes
   - Update available functions list

2. **Modify `lib/config/character_config_manager.dart`**:
   - Update `loadSystemPrompt()` to use compact Oracle format
   - Integrate Oracle static cache initialization
   - Maintain MCP instructions positioning

3. **Enhance `main.dart` or splash screen**:
   - Add Oracle static cache initialization at app startup
   - Add validation and error handling

**Implementation Steps:**
```dart
// Step 1: Enhanced MCP Instructions
{
  "available_functions": [
    {
      "name": "oracle_detect_activities",
      "description": "Detect activities using complete Oracle 4.2 context (265 activities)",
      "oracle_compliance": "All activities accessible via compact format"
    }
  ]
}

// Step 2: Optimized System Prompt
Future<String> loadSystemPrompt() async {
  // MCP Instructions + Compact Oracle + Persona + Audio
  // Result: 75% token reduction (18,500 → 4,700)
}

// Step 3: App Initialization
void main() async {
  await OracleStaticCache.initializeAtStartup();
  runApp(MyApp());
}
```
```

### **Phase 3: Testing & Validation (0.5 days)**

**Critical Testing Strategy:**
1. **Oracle Compliance Tests**: Verify all 265 activities accessible
2. **MCP Integration Tests**: Test new Oracle MCP commands
3. **Performance Tests**: Measure 75% system prompt token reduction
4. **Regression Tests**: Ensure existing functionality preserved

**Validation Checklist:**
```dart
// Test 1: Oracle methodology compliance (CRITICAL)
test('all 265 Oracle activities must be accessible', () async {
  final compactOracle = OracleStaticCache.getCompactOracleForLLM();
  final activityCount = compactOracle.split(',').length;
  expect(activityCount, equals(265));  // All activities present
  
  final isCompliant = await OracleComplianceValidator.validateOracleAccess();
  expect(isCompliant, isTrue);  // Oracle methodology preserved
});

// Test 2: System prompt optimization
test('system prompt should be reduced by 75%', () async {
  final beforeTokens = await _measureSystemPromptTokens(useFullOracle: true);
  final afterTokens = await _measureSystemPromptTokens(useCompactOracle: true);
  final reduction = (beforeTokens - afterTokens) / beforeTokens;
  expect(reduction, greaterThan(0.7));  // 70%+ reduction
});

// Test 3: MCP Oracle commands
test('oracle MCP commands should work correctly', () async {
  final result = await systemMCP.processCommand(jsonEncode({
    'action': 'oracle_detect_activities',
    'message': 'Bebi água e fiz exercício'
  }));
  final data = jsonDecode(result);
  expect(data['status'], equals('success'));
  expect(data['data']['total_activities_available'], equals(265));
});

// Test 4: No regressions
test('existing functionality should be preserved', () async {
  // TTS pipeline unchanged
  // Activity qualification logic preserved
  // Error handling maintained
  // All 612 existing tests continue to pass
});
```

## **Expected Results (MCP-INTEGRATED)**

### **System Prompt Optimization:**
```
📊 BEFORE (Current System):
- System Prompt: 18,500+ tokens per conversation
- MCP Instructions: ~2,000 tokens
- Oracle Full Context: ~15,000 tokens
- Persona + Audio: ~1,500 tokens
- Rate Limit Risk: CRITICAL

🎯 AFTER (MCP-Integrated System):
- System Prompt: 4,700 tokens per conversation
- MCP Instructions: ~2,200 tokens (enhanced)
- Oracle Compact Context: ~1,000 tokens
- Persona + Audio: ~1,500 tokens
- Rate Limit Risk: LOW

Reduction: 75% (18,500 → 4,700 tokens)
```

### **Activity Detection Optimization:**
```
📊 BEFORE (Background Detection):
- Activity Detection: 6,000+ tokens per call
- Oracle Context: Full descriptions (15,000 tokens)
- Processing: Separate background process
- Oracle Access: All 265 activities (but inefficient)

🎯 AFTER (MCP Oracle Detection):
- MCP Command: 1,000 tokens per call
- Oracle Context: Compact format (1,000 tokens)
- Processing: Integrated via MCP system
- Oracle Access: All 265 activities (efficient)

Reduction: 83% (6,000 → 1,000 tokens)
```

### **Oracle Methodology Compliance:**
- **100% Activity Access**: All 265 Oracle activities accessible via MCP
- **No Filtering**: Complete Oracle universe visible to LLM
- **Methodology Preserved**: Oracle 4.2 framework intact
- **Static Cache**: One-time loading, persistent access

### **System Performance:**
- **Conversation Initialization**: 75% faster (reduced system prompt)
- **Activity Detection**: 83% more efficient (MCP integration)
- **Rate Limiting**: CRITICAL → LOW risk level
- **Memory Usage**: Optimized (static cache vs repeated file I/O)
- **API Calls**: Reduced (MCP commands vs separate detection calls)

## **Oracle Methodology Compliance (CORRECTED)**

### **CRITICAL CORRECTIONS:**

#### **❌ Phase 1 Implementation VIOLATED Oracle Methodology:**
- Pre-selection approach filtered 235+ activities from LLM visibility
- "Progressive context" still hid activities in early phases
- Claims of "all activities accessible" were demonstrably false
- Oracle's comprehensive methodology was compromised

#### **✅ MCP-Integrated Solution PRESERVES Oracle Methodology:**
- **All 265 activities ALWAYS visible** - via compact format in MCP commands
- **No filtering or pre-selection** - complete Oracle universe accessible
- **Static cache approach** - optimizes delivery, not content
- **MCP integration** - Oracle access via system commands, not prompt bloat

### **Strict Compliance Guarantees:**
- ✅ **All 265 activities accessible** - Via `oracle_detect_activities` MCP command
- ✅ **No Oracle content modification** - Activities loaded from Oracle 4.2 JSON unchanged
- ✅ **Complete methodology preserved** - Full Oracle framework accessible
- ✅ **Static cache strategy** - In-memory loading as requested
- ✅ **No new activities created** - Only Oracle-defined activities used
- ✅ **Multilingual support** - LLM semantic understanding, no hardcoded rules
- ✅ **MCP system integration** - Oracle functionality via system commands

### **User Feedback Compliance:**
> "Smart activity should not reduce the richness of the model. It's best to use an in-memory caching strategy based on usage. THE MODEL SHOULD NOT CREATE NEW ACTIVITIES. SHOULD FOLLOW STRICTLY THE ORACLE METHODOLOGY. It's multilingual. Avoid hardcoding language specifics."

**MCP-Integrated Response:**
- ✅ **Richness preserved**: All 265 activities accessible via MCP (not filtered)
- ✅ **In-memory caching**: Static cache loaded at app startup
- ✅ **No new activities**: Oracle 4.2 JSON is single source of truth
- ✅ **Strict Oracle methodology**: Complete framework accessible via MCP
- ✅ **Multilingual**: LLM semantic understanding in MCP commands
- ✅ **No hardcoded specifics**: Pure LLM processing via MCP system

---

**Created:** 2025-09-19  
**Updated:** 2025-09-19 (MCP integration analysis & Oracle compliance correction)  
**Author:** Development Agent  
**Dependencies:** FT-139 (Oracle Preprocessing Completeness Fix)  
**Status:** Specification Complete - MCP-Integrated Approach  
**Next:** Phase 1 implementation - Static Cache + MCP Oracle Commands  
**Critical Fix:** Replaces broken pre-selection with MCP-integrated Oracle access
