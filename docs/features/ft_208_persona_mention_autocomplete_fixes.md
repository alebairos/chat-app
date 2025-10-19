# FT-208: Persona Mention Autocomplete Fixes

**Feature ID:** FT-208  
**Priority:** High  
**Category:** Bug Fix  
**Effort:** 1 hour  
**Date:** October 19, 2025

## Overview

Fix critical issues with FT-207 Persona Mention Autocomplete that prevent proper functionality and user experience.

---

## **Problem Statement**

### **Issue 1: Missing Personas in Autocomplete**
- **Problem**: Tony persona (`tonyWithOracle42`) not appearing in autocomplete suggestions when typing `@`
- **User Impact**: Users cannot switch to Tony via @mention despite it being enabled
- **Root Cause**: 5-item limit (`_maxSuggestions = 5`) cuts off the 6th enabled persona
- **Investigation**: Only 6 personas are enabled, Tony is #6 alphabetically so gets cut off by 5-item limit
- **Enabled Personas**: Ari 4.5 Oracle Coach, Aristios 4.5 Philosopher, I-There 4.2, Ryo Tzu 4.2, Sergeant Oracle 4.2, **Tony 4.2**

### **Issue 2: Persona Title Not Updating After Switch**
- **Problem**: App bar title shows old persona name after @mention persona switch
- **User Impact**: Users get confused about which persona is active
- **Root Cause**: Main app (TabBarView parent) doesn't listen for persona changes from ChatInput

### **Evidence from Logs**
```
flutter: FT-207: Found 12 personas in config
flutter: FT-207: Adding enabled persona: tonyWithOracle42
flutter: FT-207: Successfully loaded 12 enabled personas
```
Personas are loading, but Tony's short name extraction is failing.

---

## **Root Cause Analysis**

### **Issue 1: Alphabetical Sorting + 5-Item Limit**
**File**: `lib/services/persona_autocomplete_service.dart`
**Problem**: Personas are sorted alphabetically, then limited to 5 items

Current logic:
```dart
static const int _maxSuggestions = 5;

// Sort personas alphabetically by display name
personas.sort((a, b) => a.displayName.compareTo(b.displayName));

if (query.isEmpty) {
  return personas.take(_maxSuggestions).toList(); // Only first 5!
}
```

**Issue**: When user types `@`, only the first 5 personas alphabetically are shown. Tony 4.2 is #11 in alphabetical order, so it gets cut off.

### **Issue 2: Title Update Logic**
**File**: `lib/main.dart` (lines 148-174)
**Problem**: `FutureBuilder<String>` in AppBar doesn't rebuild when persona changes

Current logic:
```dart
FutureBuilder<String>(
  future: _configLoader.activePersonaDisplayName,
  builder: (context, snapshot) {
    // This doesn't rebuild when persona changes
  },
)
```

**Issue**: The `Future` is created once and doesn't update when `ConfigLoader.setActivePersona()` is called.

---

## **Solution Design**

### **Fix 1: Increase Persona Limit & Add Debug Logging**
- **Increase `_maxSuggestions`** from 5 to 10 to show more personas
- **Add comprehensive debug logging** to track filtering process
- **Investigate why `@tony` filtering doesn't work** (should show Tony even with 5-item limit)

### **Fix 2: Reactive Title Updates**
- **Convert to StreamBuilder** or **StatefulWidget** with listener
- **Listen for persona changes** in the main app
- **Trigger rebuilds** when persona switches occur

---

## **Technical Implementation**

### **Phase 1: Fix Persona Limit & Add Debug Logging (15 minutes)**

#### **Increase Persona Limit**
**File**: `lib/services/persona_autocomplete_service.dart`
```dart
// FIXED: Increased from 5 to 10
static const int _maxSuggestions = 10; // FT-208: Show more personas
```

#### **Add Comprehensive Debug Logging**
**File**: `lib/services/persona_autocomplete_service.dart`
```dart
List<PersonaOption> filterPersonas(List<PersonaOption> personas, String query) {
  print('FT-208: Filtering ${personas.length} personas with query: "$query"');
  
  if (query.isEmpty) {
    final result = personas.take(_maxSuggestions).toList();
    print('FT-208: Empty query, returning first ${result.length} personas alphabetically');
    for (int i = 0; i < result.length; i++) {
      print('FT-208: [$i] ${result[i].displayName} (@${result[i].shortName})');
    }
    return result;
  }

  // Filter personas with detailed logging
  final matchingPersonas = <PersonaOption>[];
  for (final persona in personas) {
    final matches = persona.matches(query);
    print('FT-208: ${persona.displayName} (@${persona.shortName}) matches "$query": $matches');
    if (matches) {
      matchingPersonas.add(persona);
    }
  }

  print('FT-208: Found ${matchingPersonas.length} matching personas before sorting');
  
  // Sort by relevance with logging
  matchingPersonas.sort((a, b) {
    final scoreA = a.getRelevanceScore(query);
    final scoreB = b.getRelevanceScore(query);
    return scoreA.compareTo(scoreB);
  });

  final result = matchingPersonas.take(_maxSuggestions).toList();
  print('FT-208: Final result: ${result.length} personas');
  for (int i = 0; i < result.length; i++) {
    print('FT-208: [$i] ${result[i].displayName} (@${result[i].shortName}) - relevance: ${result[i].getRelevanceScore(query)}');
  }
  
  return result;
}
```

**Status**: ✅ **IMPLEMENTED** - Limit increased to 10, comprehensive logging added

### **Phase 2: Fix Title Updates (30 minutes)**

#### **Option A: Add Persona Change Listener**
**File**: `lib/main.dart`
```dart
class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  // ... existing code ...
  String _currentPersonaDisplayName = 'Loading...';

  @override
  void initState() {
    super.initState();
    // ... existing code ...
    _loadCurrentPersonaName();
  }

  Future<void> _loadCurrentPersonaName() async {
    try {
      final name = await _configLoader.activePersonaDisplayName;
      if (mounted) {
        setState(() {
          _currentPersonaDisplayName = name;
        });
      }
    } catch (e) {
      print('Error loading persona name: $e');
    }
  }

  // Add method to refresh persona name
  void _refreshPersonaName() {
    _loadCurrentPersonaName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AI Personas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _currentPersonaDisplayName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ChatScreen(onPersonaChanged: _refreshPersonaName), // Pass callback
          const StatsScreen(),
          const JournalScreen(),
          const ProfileScreen(),
        ],
      ),
      // ... rest of build method
    );
  }
}
```

#### **Update ChatScreen to Notify Parent**
**File**: `lib/screens/chat_screen.dart`
```dart
class ChatScreen extends StatefulWidget {
  final ChatStorageService? storageService;
  final ClaudeService? claudeService;
  final bool testMode;
  final VoidCallback? onPersonaChanged; // Add callback

  const ChatScreen({
    this.storageService,
    this.claudeService,
    this.testMode = false,
    this.onPersonaChanged, // Add parameter
    super.key,
  });
}
```

#### **Update ChatInput Integration**
**File**: `lib/widgets/chat_input.dart`
```dart
class _ChatInputState extends State<ChatInput> {
  // ... existing code ...

  Future<void> _initializeMentionController() async {
    // ... existing code ...
    
    _mentionController.onPersonaSelected = (personaKey) async {
      try {
        await _configLoader.setActivePersona(personaKey);
        print('FT-207: Switched to persona: $personaKey');
        
        // FT-208: Notify parent about persona change
        if (widget.onPersonaChanged != null) {
          widget.onPersonaChanged!();
        }
      } catch (e) {
        print('FT-207: Error switching persona: $e');
      }
    };
    
    // ... rest of method
  }
}
```

#### **Add Callback to ChatInput**
**File**: `lib/widgets/chat_input.dart`
```dart
class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String path, Duration duration) onSendAudio;
  final VoidCallback? onPersonaChanged; // Add callback

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onSendAudio,
    this.onPersonaChanged, // Add parameter
  });
}
```

### **Phase 3: Integration and Testing (15 minutes)**

#### **Update ChatScreen to Pass Callback**
**File**: `lib/screens/chat_screen.dart`
```dart
ChatInput(
  controller: _messageController,
  onSend: _sendMessage,
  onSendAudio: _handleAudioMessage,
  onPersonaChanged: widget.onPersonaChanged, // Pass through callback
),
```

---

## **Testing Strategy**

### **Test Case 1: Tony Persona Autocomplete**
1. **Open chat input**
2. **Type `@tony`**
3. **Verify**: Tony 4.2 appears in suggestions
4. **Tap Tony option**
5. **Verify**: Text becomes `@tony ` and persona switches

### **Test Case 2: Title Update**
1. **Note current persona in title**
2. **Type `@ryo` and select Ryo Tzu**
3. **Verify**: Title updates to show "Ryo Tzu 4.2"
4. **Type `@tony` and select Tony**
5. **Verify**: Title updates to show "Tony 4.2"

### **Test Case 3: All Personas Available**
1. **Type `@`**
2. **Verify**: All enabled personas appear (should be 12+ personas)
3. **Check logs**: Verify all personas have proper short names

---

## **Expected Outcomes**

### **Before Fix**
- Tony not appearing in `@tony` autocomplete
- Title showing old persona name after switch
- User confusion about active persona

### **After Fix**
- All personas appear in autocomplete with correct short names
- Title updates immediately when persona switches via @mention
- Clear visual feedback about active persona
- Debug logs help track persona loading and filtering

---

## **Implementation Priority**

### **Phase 1: Debug Logging (Immediate)**
- **Critical**: Understand why Tony isn't appearing
- **Add comprehensive logging** to track persona loading and filtering
- **Validate short name extraction** for all personas

### **Phase 2: Title Updates (High Priority)**
- **User-facing issue**: Confusing when title doesn't update
- **Implement callback system** for persona change notifications
- **Ensure immediate visual feedback** when switching personas

### **Phase 3: Polish and Optimization (Medium Priority)**
- **Remove debug logs** once issues are resolved
- **Optimize performance** if needed
- **Add error handling** for edge cases

---

## **Risk Mitigation**

### **Backward Compatibility**
- **Optional callbacks**: New parameters are optional, won't break existing code
- **Graceful fallbacks**: If callbacks fail, core functionality still works
- **Minimal changes**: Focus on specific issues without major refactoring

### **Performance Impact**
- **Lightweight callbacks**: Simple function calls, minimal overhead
- **Debounced updates**: Title updates are infrequent, no performance impact
- **Debug logging**: Can be easily removed or disabled

---

## **Success Metrics**

### **Functional**
- **Tony persona appears** in `@tony` autocomplete
- **All enabled personas** have proper short names and appear in suggestions
- **Title updates immediately** when persona switches via @mention

### **User Experience**
- **Clear visual feedback** about active persona
- **Intuitive @mention behavior** matching user expectations
- **No confusion** about which persona is currently active

### **Technical**
- **Debug logs provide insight** into persona loading and filtering
- **Callback system works reliably** for persona change notifications
- **No performance degradation** from the fixes

---

## **Related Features**

- **FT-207**: Persona Mention Autocomplete (base feature)
- **FT-030**: Dynamic Chat Header with Persona Names (title display)
- **FT-200**: Conversation History Database Queries (persona switching)

---

## **Conclusion**

FT-208 addresses critical usability issues in the persona mention autocomplete feature. The fixes ensure all personas are accessible via @mention and provide immediate visual feedback when personas switch, creating a seamless user experience for multi-persona conversations.

**This fix is essential for FT-207 to be fully functional and user-friendly.**

---

**Implementation Date**: October 19, 2025  
**Status**: Ready for Implementation  
**Breaking Changes**: None  
**Feature Toggle**: Uses existing FT-207 toggle
