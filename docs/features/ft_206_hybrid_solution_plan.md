# FT-206: Hybrid Solution - Simplified Structure + Universal Laws

**Date**: 2025-10-24  
**Approach**: Option 3 - Hybrid (Best of Both Worlds)  
**Estimated Effort**: 3-4 hours  
**Risk Level**: Low  

---

## 🎯 Strategy

**Combine the simplicity of the working version (aa8d769) with the clarity of Universal Laws**

### Key Principles
1. ✅ **Keep working version's simple structure** (no massive priority header)
2. ✅ **Add 8 Universal Laws** (concise, clear, non-repetitive)
3. ✅ **Simplify conversation context** (remove 50+ lines of instructions)
4. ✅ **Leverage existing config files** (don't duplicate what's already there)
5. ✅ **Increase message limit** (back to 30 messages for better context)

---

## 📊 Current State Analysis

### **Existing Config Files Already Define:**

#### 1. **`core_behavioral_rules.json`** (Already has System Laws #4-#7!)
- ✅ **System Law #4**: Absolute Configuration Adherence
- ✅ **System Law #5**: Mandatory Conversation Awareness (MCP commands)
- ✅ **System Law #6**: Conversation Context Boundaries (activity detection)
- ✅ **System Law #7**: Response Continuity and Repetition Prevention
- ✅ Data integrity rules
- ✅ Response quality rules
- ✅ Transparency constraints

#### 2. **`mcp_base_config.json`** (Already has MCP instructions!)
- ✅ Mandatory data queries (get_activity_stats)
- ✅ System functions documentation
- ✅ When to use each MCP command
- ✅ Conversation continuity commands

#### 3. **`multi_persona_config.json`** (Already has multi-persona protocol!)
- ✅ Identity guidelines
- ✅ Persona switching protocol (4 steps)
- ✅ Conversation continuity protocol
- ✅ Symbol guidance
- ✅ Amnesia prevention

#### 4. **`conversation_database_config.json`** (Already has context strategy!)
- ✅ Proactive context loading
- ✅ Interleaved format
- ✅ Performance limits (8-10 messages)

---

## 💡 Key Insight

**We're duplicating instructions that already exist in config files!**

The current `_buildSystemPrompt()` adds:
- 50+ line priority header → **Already in `core_behavioral_rules.json`**
- 50+ lines of conversation instructions → **Already in `multi_persona_config.json`**
- MCP command rules → **Already in `mcp_base_config.json`**

**Solution**: Reference the configs, don't duplicate them!

---

## 🎯 Hybrid Solution Design

### **New System Prompt Structure**

```
## 🎯 IDENTITY
[Persona Name & Role]
[Oracle Framework - if enabled]

## 📜 THE 8 UNIVERSAL LAWS (Quick Reference)

LAW #1: Multi-Temporal Awareness
  → Use current time. Think: past (learn) → present (act) → future (plan)
  
LAW #2: Data-Informed Coaching
  → Use MCP for historical data. Never approximate.
  
LAW #3: Goal-Oriented Coaching
  → Always act as helpful coach. Every interaction moves user toward goals.
  
LAW #4: Activity Detection Boundaries
  → Detect activities ONLY from current message. History = context, not data.
  
LAW #5: Conversation Continuity
  → Review last exchange. Build on what was just discussed.
  
LAW #6: Response Uniqueness
  → Never repeat exact responses. Stay fresh and natural.
  
LAW #7: Persona Identity
  → Maintain YOUR unique style. Don't copy other personas.

LAW #8: Multi-Persona Handoff
  → If persona switch: acknowledge, understand context, maintain YOUR identity.

---

## 📊 CURRENT CONTEXT

### Recent Conversation (30 messages):
Just now: User: "sim, quero. Comecei!"
A minute ago: You: "quer começar? vou cronometrar os 25 minutos pra você."
5 minutes ago: User: "me ajuda que vai dar bom"
...

### Time Context:
[Current time, time gap, session state]

---

## 🔧 AVAILABLE TOOLS
- get_current_time: Current temporal information
- get_activity_stats: Historical activity data
- get_message_stats: Conversation patterns

---

Now respond to the user, following the 8 Universal Laws.
```

**Total**: ~60-80 lines (vs ~150+ in current, ~30-40 in working version)

---

## 🔧 Implementation Plan

### **Phase 1: Create Universal Laws (Minimal)**

**File**: `assets/config/universal_laws.json`

```json
{
  "universal_laws": {
    "description": "8 Core Laws - Quick reference. Detailed rules in core_behavioral_rules.json",
    "version": "1.0",
    "format": "concise",
    "laws": [
      {
        "id": 1,
        "name": "Multi-Temporal Awareness",
        "rule": "Use current time. Think: past (learn) → present (act) → future (plan)"
      },
      {
        "id": 2,
        "name": "Data-Informed Coaching",
        "rule": "Use MCP for historical data. Never approximate."
      },
      {
        "id": 3,
        "name": "Goal-Oriented Coaching",
        "rule": "Always act as helpful coach. Every interaction moves user toward goals."
      },
      {
        "id": 4,
        "name": "Activity Detection Boundaries",
        "rule": "Detect activities ONLY from current message. History = context, not data."
      },
      {
        "id": 5,
        "name": "Conversation Continuity",
        "rule": "Review last exchange. Build on what was just discussed."
      },
      {
        "id": 6,
        "name": "Response Uniqueness",
        "rule": "Never repeat exact responses. Stay fresh and natural."
      },
      {
        "id": 7,
        "name": "Persona Identity",
        "rule": "Maintain YOUR unique style. Don't copy other personas."
      },
      {
        "id": 8,
        "name": "Multi-Persona Handoff",
        "rule": "If persona switch: acknowledge, understand context, maintain YOUR identity."
      }
    ],
    "note": "These are quick references. Full details in core_behavioral_rules.json, mcp_base_config.json, and multi_persona_config.json"
  }
}
```

**Key**: Keep it SHORT. Just the rule, no expansion. Details are in other configs.

---

### **Phase 2: Refactor `_buildSystemPrompt()`**

**Changes**:

1. **Remove the 50+ line priority header** (lines 757-808)
2. **Add concise 8 Universal Laws** (~20 lines)
3. **Simplify conversation context** (back to working version format)
4. **Increase message limit** (30 messages like working version)

**New Implementation**:

```dart
Future<String> _buildSystemPrompt() async {
  // Generate time context
  final lastMessageTime = await _getLastMessageTimestamp();
  final timeContext = await TimeContextService.generatePreciseTimeContext(lastMessageTime);
  
  // Get conversation context (simplified format)
  final conversationContext = await _buildRecentConversationContext();
  
  // Build system prompt
  String systemPrompt = _systemPrompt ?? '';
  
  // 1. Add Universal Laws (concise reference)
  final universalLaws = await _loadUniversalLaws();
  if (universalLaws.isNotEmpty) {
    systemPrompt = '$universalLaws\n\n---\n\n$systemPrompt';
  }
  
  // 2. Add conversation context first (simple format)
  if (conversationContext.isNotEmpty) {
    systemPrompt = '$conversationContext\n\n$systemPrompt';
  }
  
  // 3. Add time context
  if (timeContext.isNotEmpty) {
    systemPrompt = '$timeContext\n\n$systemPrompt';
  }
  
  // 4. Add session MCP context (unchanged)
  if (_systemMCP != null) {
    String sessionMcpContext = '\n\n## SESSION CONTEXT\n'
        '**Current Session**: Active MCP functions available\n'
        '**Data Source**: Real-time database queries\n'
        '**Temporal Context**: Use current time for accurate day calculations\n\n'
        '**Session Functions**:\n'
        '- get_current_time: Current temporal information\n'
        '- get_device_info: Device and system information\n'
        '- get_activity_stats: Activity tracking data\n'
        '- get_message_stats: Chat statistics\n\n'
        '**Session Rules**:\n'
        '- Always use fresh data from MCP commands\n'
        '- Never rely on conversation memory for activity data\n'
        '- Calculate precise temporal offsets based on current time\n'
        '- Present data naturally while maintaining accuracy';
    
    systemPrompt += sessionMcpContext;
  }
  
  return systemPrompt;
}
```

---

### **Phase 3: Add `_loadUniversalLaws()` Method**

```dart
/// Load and format Universal Laws (concise version)
Future<String> _loadUniversalLaws() async {
  try {
    final configString = await rootBundle.loadString('assets/config/universal_laws.json');
    final config = json.decode(configString) as Map<String, dynamic>;
    final laws = config['universal_laws']['laws'] as List;
    
    final buffer = StringBuffer();
    buffer.writeln('## 📜 THE 8 UNIVERSAL LAWS (Quick Reference)');
    buffer.writeln('');
    
    for (final law in laws) {
      final id = law['id'];
      final name = law['name'];
      final rule = law['rule'];
      buffer.writeln('LAW #$id: $name');
      buffer.writeln('  → $rule');
      buffer.writeln('');
    }
    
    return buffer.toString();
  } catch (e) {
    _logger.warning('Failed to load universal laws: $e');
    return '';
  }
}
```

---

### **Phase 4: Simplify `_buildRecentConversationContext()`**

**Revert to working version format**:

```dart
Future<String> _buildRecentConversationContext() async {
  if (_storageService == null) return '';
  
  try {
    // Increase limit back to 30 (like working version)
    final messages = await _storageService!.getMessages(limit: 30);
    if (messages.isEmpty) return '';
    
    final now = DateTime.now();
    final contextLines = <String>[];
    
    for (final msg in messages.reversed) {
      final timeDiff = now.difference(msg.timestamp);
      final timeAgo = _formatNaturalTime(timeDiff);
      
      // Include persona label for multi-persona awareness
      final speaker = msg.isUser 
          ? 'User' 
          : (msg.personaDisplayName != null 
              ? '[${msg.personaDisplayName}]' 
              : 'You');
      
      contextLines.add('$timeAgo: $speaker: "${msg.text}"');
    }
    
    return '''## RECENT CONVERSATION
${contextLines.join('\n')}

For deeper conversation history, use: {"action": "get_conversation_context", "hours": N}''';
  } catch (e) {
    _logger.debug('Failed to build conversation context: $e');
    return '';
  }
}

/// Format time difference in natural language (from working version)
String _formatNaturalTime(Duration diff) {
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 2) return 'A minute ago';
  if (diff.inMinutes < 10) return '${diff.inMinutes} minutes ago';
  if (diff.inMinutes < 30) return 'About ${diff.inMinutes} minutes ago';
  if (diff.inHours < 1) return 'About an hour ago';
  if (diff.inHours < 2) return 'An hour ago';
  if (diff.inHours < 6) return '${diff.inHours} hours ago';
  if (diff.inDays < 1) return 'Earlier today';
  if (diff.inDays == 1) return 'Yesterday';
  return '${diff.inDays} days ago';
}
```

---

### **Phase 5: Update Config (Optional)**

**File**: `assets/config/conversation_database_config.json`

```json
{
  "performance": {
    "max_interleaved_messages": 30,  // Increased from 10
    "max_interleaved_messages_oracle": 25,  // Increased from 8
    "max_context_tokens": 900,  // Increased from 600
    "max_context_tokens_oracle": 750  // Increased from 500
  }
}
```

---

## 📊 Comparison: Before vs After

### **Current (Problematic)**
```
1. Priority Header (50+ lines) ❌
2. Time Context (5-10 lines) ✅
3. Conversation Context with instructions (60+ lines) ❌
   - 50 lines of instructions
   - 8-10 messages
4. Original System Prompt (1000+ lines) ✅
5. Session MCP Context (20 lines) ✅

Total: ~1150+ lines
```

### **Hybrid Solution**
```
1. Time Context (5-10 lines) ✅
2. Universal Laws (20 lines) ✅ NEW
3. Conversation Context (simple) (35 lines) ✅
   - 0 lines of instructions
   - 30 messages
4. Original System Prompt (1000+ lines) ✅
5. Session MCP Context (20 lines) ✅

Total: ~1080 lines (7% reduction, but MUCH clearer)
```

### **Working Version (Reference)**
```
1. Time Context (5-10 lines) ✅
2. Conversation Context (simple) (35 lines) ✅
   - 30 messages
3. Original System Prompt (1000+ lines) ✅
4. Session MCP Context (20 lines) ✅

Total: ~1060 lines
```

**Key Difference**: Hybrid adds 20 lines of Universal Laws but removes 110+ lines of repetitive instructions.

---

## ✅ Benefits of Hybrid Approach

1. **Simplicity**: Like working version, but with clear laws
2. **Clarity**: 8 laws are easy to remember and follow
3. **No Duplication**: Laws reference existing configs
4. **More Context**: 30 messages vs 8-10
5. **Clean Format**: Simple speaker/message format
6. **Low Risk**: Minimal changes from working version
7. **Quick Implementation**: 3-4 hours vs 8-10 for full Universal Laws

---

## 🧪 Testing Plan

### **Test Scenarios**

1. **Repetition Bug**: Replay message #121 ("sim, quero. Comecei!")
   - Expected: No repetition, acknowledges previous question
   
2. **Time Awareness**: Test messages sent hours apart
   - Expected: Correct time gap recognition
   
3. **Data Query**: Test "resumo da semana"
   - Expected: Calls get_activity_stats(days: 7)
   
4. **Multi-Persona**: Test "@ithere tava conversando com o Tony"
   - Expected: Acknowledges handoff, maintains identity
   
5. **Context Awareness**: Test with 30 messages of history
   - Expected: Better context understanding than current 8-10

---

## 📋 Implementation Checklist

- [ ] Create `assets/config/universal_laws.json` (concise version)
- [ ] Add `_loadUniversalLaws()` method to `claude_service.dart`
- [ ] Remove priority header from `_buildSystemPrompt()` (lines 757-808)
- [ ] Add Universal Laws loading to `_buildSystemPrompt()`
- [ ] Revert `_buildRecentConversationContext()` to simple format
- [ ] Add `_formatNaturalTime()` helper method
- [ ] Update message limit to 30
- [ ] Test repetition bug scenario
- [ ] Test multi-persona handoff
- [ ] Test time awareness
- [ ] Document results
- [ ] Commit and push

---

## 🎯 Success Criteria

- [ ] No repetition in message #121 scenario
- [ ] Correct time gap calculation
- [ ] MCP commands called for data queries
- [ ] Smooth multi-persona transitions
- [ ] Better context awareness with 30 messages
- [ ] System prompt ~1080 lines (vs ~1150+ current)
- [ ] All tests pass

---

## 📝 Notes

### **Why This Works**

1. **Leverages Existing Configs**: Doesn't duplicate what's already there
2. **Simple Reference**: 8 laws are quick reminders, not full instructions
3. **Working Version Base**: Starts from proven structure
4. **Minimal Changes**: Low risk, high reward
5. **Clear Hierarchy**: Time → Laws → Conversation → Persona → Session

### **What We're NOT Doing**

- ❌ Not adding 50+ line priority header
- ❌ Not adding 50+ lines of conversation instructions
- ❌ Not duplicating config file content
- ❌ Not reducing message limit
- ❌ Not over-engineering

### **What We ARE Doing**

- ✅ Adding concise 8 Universal Laws (20 lines)
- ✅ Reverting to simple conversation format
- ✅ Increasing message limit to 30
- ✅ Removing instruction overload
- ✅ Keeping working version's simplicity

---

**Ready to implement!**

