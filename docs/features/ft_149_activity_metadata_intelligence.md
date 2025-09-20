# FT-149: Activity Metadata Intelligence

**Feature ID**: FT-149  
**Priority**: High  
**Category**: Data Enhancement / User Experience  
**Effort**: 3-4 hours  

## Problem Statement

Activities are detected and stored but lose rich contextual details that users naturally provide:
- **Lost Quantities**: "bebi 500ml de água" → stores only "Beber água"
- **Missing Context**: "corri 30 minutos no parque" → loses duration and location
- **Reduced Value**: Activity logs show counts but not meaningful progress data

**Current State**: Basic activity detection without contextual intelligence  
**Desired State**: Rich, intelligent metadata extraction with user editability

## Solution Overview

Enhance the existing **two-pass Oracle detection system (FT-140)** with intelligent metadata post-processing, maintaining zero additional LLM costs and **simple feature flag control** for safe rollout.

### **Post-Processing Integration Architecture**

**Integration Point**: Add metadata intelligence as a post-processing step after FT-140 Oracle detection within the existing two-pass flow.

**Current Flow:**
```
Pass 1: Immediate persona response
Pass 2: Background Oracle detection (FT-140) → Store activity
```

**Enhanced Flow:**
```
Pass 1: Immediate persona response  
Pass 2: Background Oracle detection (FT-140) → Store activity → FT-149 metadata post-processing
```

**Key Benefits:**
- ✅ **Zero Risk**: FT-140 Oracle detection continues working exactly as before
- ✅ **Zero Cost**: Uses existing two-pass architecture and timing
- ✅ **Smart Context**: FT-149 receives detected Oracle activity as context
- ✅ **Graceful Degradation**: If metadata extraction fails, activities still get logged

## Core Principle

**Intelligent Context Preservation**: Capture rich details users naturally provide through semantic understanding, not pattern matching, while maintaining cost efficiency and deployment safety.

## 🚩 **Feature Flag Architecture (Simplified)**

### **Two Flags, Three States**

```json
// assets/config/metadata_intelligence_config.json
{
  "version": "1.0",
  "enabled": true,
  "ai_extraction": true
}
```

### **State Matrix:**

| `enabled` | `ai_extraction` | Result |
|-----------|-----------------|--------|
| `false` | `false` | **Current system** - no metadata at all |
| `true` | `false` | **Manual only** - user can add/edit metadata |
| `true` | `true` | **Full intelligence** - AI extracts + user edits |

### **Configuration Manager**

```dart
// lib/config/metadata_config.dart
class MetadataConfig {
  static bool _enabled = false;
  static bool _aiExtraction = false;
  
  static Future<void> initialize() async {
    try {
      final configString = await rootBundle.loadString(
        'assets/config/metadata_intelligence_config.json'
      );
      final config = json.decode(configString);
      _enabled = config['enabled'] ?? false;
      _aiExtraction = config['ai_extraction'] ?? false;
      Logger().info('✅ Metadata config loaded: enabled=$_enabled, ai=$_aiExtraction');
    } catch (e) {
      Logger().warning('⚠️ Metadata config not found, using defaults: $e');
      _enabled = false;
      _aiExtraction = false;
    }
  }
  
  // Three simple states
  static bool get isDisabled => !_enabled;
  static bool get isManualOnly => _enabled && !_aiExtraction;
  static bool get isFullIntelligence => _enabled && _aiExtraction;
}
```

## Technical Approach

### **Phase 1: Focused Post-Processing Integration**

**Architecture**: Add metadata extraction as a focused post-processing step after FT-140 Oracle detection, using existing `ClaudeService` infrastructure for optimal accuracy.

**Integration Point**: Enhance `ActivityMemoryService.logActivity()` to trigger metadata post-processing.

```dart
// Enhanced ActivityMemoryService with post-processing
class ActivityMemoryService {
  
  /// Enhanced logActivity with FT-149 metadata post-processing
  static Future<ActivityModel> logActivity({
    required String? activityCode,
    required String activityName,
    required String dimension,
    required String source,
    // ... existing parameters
    // FT-149: Post-processing context
    String? userMessage,
    String? oracleActivityName,
  }) async {
    // Store activity first (existing FT-140 logic)
    final activity = ActivityModel.fromDetection(/* ... */);
    await _database.writeTxn(() async {
      await _database.activityModels.put(activity);
    });
    
    // FT-149: Metadata post-processing (if enabled and context available)
    if (userMessage != null && oracleActivityName != null) {
      await _extractAndStoreMetadata(activity, userMessage, oracleActivityName);
    }
    
    return activity;
  }
  
  /// FT-149: Focused metadata extraction post-processing
  static Future<void> _extractAndStoreMetadata(
    ActivityModel activity,
    String userMessage,
    String oracleActivityName,
  ) async {
    try {
      // Use existing ClaudeService for focused metadata extraction
      final metadata = await MetadataExtractionService.extractMetadata(
        userMessage: userMessage,
        detectedActivity: activity,
        oracleActivityName: oracleActivityName,
      );

      if (metadata != null && metadata.isNotEmpty) {
        activity.metadataMap = metadata;
        await _database.writeTxn(() async {
          await _database.activityModels.put(activity);
        });
        Logger.info('FT-149: ✅ Added ${metadata.keys.length} metadata fields');
      }
    } catch (e) {
      Logger.warning('FT-149: Metadata extraction failed gracefully: $e');
      // Activity already stored - graceful degradation
    }
  }
}
```

### **Phase 2: Focused Metadata Extraction Service**

**Key Innovation**: Use existing `ClaudeService._callClaudeWithPrompt()` for focused, high-accuracy metadata extraction.

```dart
// NEW: Dedicated metadata extraction service
class MetadataExtractionService {
  
  /// FT-149: Focused metadata extraction using existing ClaudeService
  static Future<Map<String, dynamic>?> extractMetadata({
    required String userMessage,
    required ActivityModel detectedActivity,
    required String oracleActivityName,
  }) async {
    try {
      // Feature flag check
      if (MetadataConfig.isDisabled || !MetadataConfig.isFullIntelligence) {
        return null;
      }

      // Build focused metadata extraction prompt
      final prompt = _buildFocusedMetadataPrompt(
        userMessage: userMessage,
        activityCode: detectedActivity.activityCode ?? 'UNKNOWN',
        activityName: oracleActivityName,
      );

      // Use existing ClaudeService infrastructure (optimal accuracy)
      final claudeService = ClaudeService();
      await claudeService.initialize();
      final response = await claudeService._callClaudeWithPrompt(prompt);
      
      // Parse metadata from focused response
      return _parseMetadataResponse(response);
    } catch (e) {
      Logger.warning('FT-149: Metadata extraction failed: $e');
      return null; // Graceful degradation
    }
  }
  
  /// Build focused metadata extraction prompt (50-100 tokens)
  static String _buildFocusedMetadataPrompt({
    required String userMessage,
    required String activityCode,
    required String activityName,
  }) {
    return '''
# METADATA EXTRACTION (FT-149)

## Context
**User Message**: "$userMessage"
**Detected Activity**: $activityName ($activityCode)

## Task
Extract relevant metadata from the user's message for this specific activity.

### Focus Areas by Activity Type:
- **SF1 (Water)**: Volume (ml, L, cups, glasses), temperature, container type
- **SF12 (Exercise)**: Duration, intensity, type, location, equipment
- **TG8 (Work)**: Duration, task type, productivity level, tools used
- **SM1 (Meditation)**: Duration, technique, location, guidance type

### Portuguese Colloquialisms:
- "copinho" → ~150ml, "copão" → ~300ml
- "garrafinha" → ~500ml, "garrafa" → ~1L
- "corridinha" → light jog, "voltinha" → short walk

## Output (JSON only):
Return ONLY a JSON object. If no metadata found, return {}.

Examples:
- "bebi 300ml de água" → {"quantity": "300", "unit": "ml", "substance": "water"}
- "fiz 20 flexões" → {"count": "20", "exercise_type": "push-ups"}
- "corri 2km no parque" → {"distance": "2", "unit": "km", "location": "park"}

JSON:''';
  }
  
  /// Parse metadata from Claude response
  static Map<String, dynamic>? _parseMetadataResponse(String response) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');
      
      if (jsonStart == -1 || jsonEnd == -1) return null;
      
      final jsonStr = response.substring(jsonStart, jsonEnd + 1);
      final parsed = json.decode(jsonStr);
      
      return parsed is Map<String, dynamic> && parsed.isNotEmpty ? parsed : null;
    } catch (e) {
      Logger.debug('FT-149: Failed to parse metadata response: $e');
      return null;
    }
  }
}
```

### **Key Benefits of Focused Post-Processing Approach**

**Accuracy Advantages:**
- ✅ **Specialized Context**: Perfect context for metadata extraction: "User said X, detected activity Y"
- ✅ **Focused Prompts**: Dedicated prompts optimized only for metadata extraction
- ✅ **Error Isolation**: Activity detection accuracy remains unchanged
- ✅ **Iterative Improvement**: Can refine metadata prompts based on real usage

**Cost Efficiency:**
- ✅ **Minimal Token Usage**: ~50-100 tokens per metadata extraction vs. thousands for activity detection
- ✅ **Conditional Execution**: Only runs when activities are detected and feature enabled
- ✅ **Existing Infrastructure**: Leverages proven `ClaudeService._callClaudeWithPrompt()` method

**Implementation Safety:**
- ✅ **Zero Risk to FT-140**: Oracle detection continues working exactly as before
- ✅ **Graceful Degradation**: If metadata extraction fails, activities still get logged
- ✅ **Feature Flag Control**: Can be disabled instantly if issues arise

### **Phase 2: ActivityModel Enhancement**

```dart
// Enhanced ActivityModel with simple flag awareness
class ActivityModel {
  // Existing fields unchanged...
  
  // NEW: Metadata storage (only populated if feature enabled)
  Map<String, dynamic>? metadata;
  Map<String, String>? metadataTypes;
  
  // NEW: Smart access methods with feature flag checks
  double? getEstimatedValue(String key) {
    if (MetadataConfig.isDisabled) return null;
    return metadata?['${key}_estimated']?.toDouble();
  }
  
  String? getOriginalExpression(String key) {
    if (MetadataConfig.isDisabled) return null;
    return metadata?['${key}_original']?.toString();
  }
  
  bool get hasMetadata => 
    !MetadataConfig.isDisabled && 
    metadata?.isNotEmpty == true;
}
```

### **Phase 3: UI Enhancement with State Awareness**

```dart
// Enhanced ActivityCard with three-state behavior
class ActivityCard extends StatefulWidget {
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildActivityHeader(),
          _buildDimensionRow(),
          
          // Show metadata section based on state
          if (!MetadataConfig.isDisabled)
            _buildMetadataSection(),
        ],
      ),
    );
  }
  
  Widget _buildMetadataSection() {
    return CollapsibleSection(
      header: "Metadata",
      child: Column(
        children: [
          // STATE 2 & 3: Always show user editing when enabled
          _buildUserMetadataEditor(),
          
          // STATE 3: Show AI extracted data only in full intelligence mode
          if (MetadataConfig.isFullIntelligence && _hasAIMetadata())
            _buildAIMetadataDisplay(),
        ],
      ),
    );
  }
  
  Widget _buildUserMetadataEditor() {
    return Column(
      children: [
        Text('Your Details', style: TextStyle(fontWeight: FontWeight.w600)),
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Add quantity, notes, or other details...',
          ),
          onChanged: (value) => _updateUserMetadata('notes', value),
        ),
        // Add more user input fields as needed
      ],
    );
  }
  
  Widget _buildAIMetadataDisplay() {
    return Column(
      children: [
        Text('AI Detected', style: TextStyle(fontWeight: FontWeight.w600)),
        ...widget.activity.metadata?.entries.map((entry) => 
          _buildMetadataRow(entry.key, entry.value)
        ).toList() ?? [],
      ],
    );
  }
}
```

## 📊 **Three States Explained**

### **State 1: Disabled (`enabled: false`)**
```json
{"enabled": false, "ai_extraction": false}
```
- **Behavior**: Exactly current system
- **UI**: No metadata sections visible
- **Detection**: No metadata extraction in prompts
- **Storage**: No metadata fields populated
- **Use Case**: Default state, rollback option

### **State 2: Manual Only (`enabled: true, ai_extraction: false`)**
```json
{"enabled": true, "ai_extraction": false}
```
- **Behavior**: User can manually add metadata
- **UI**: Shows empty metadata section with input fields
- **Detection**: Basic activity detection (no AI extraction)
- **Storage**: Only user-entered metadata saved
- **Use Case**: User-controlled metadata without AI assistance

**UI Example:**
```
SF1  Beber água                    21:13
🏃 Physical Health    ✅ Completed
     
     [▼ Metadata]
     Your Details:
     [Add quantity, notes, or other details...]
     [+ Add field]
```

### **State 3: Full Intelligence (`enabled: true, ai_extraction: true`)**
```json
{"enabled": true, "ai_extraction": true}
```
- **Behavior**: AI extracts metadata + user can edit
- **UI**: Shows AI-extracted metadata with user editing
- **Detection**: Enhanced prompt with intelligent extraction
- **Storage**: AI metadata + user modifications
- **Use Case**: Full collaborative intelligence

**UI Example:**
```
SF1  Beber água                    21:13
🏃 Physical Health    ✅ Completed
     
     [▼ Metadata]
     AI Detected:
     quantity: 500ml [edit]
     type: water [edit]
     
     Your Details:
     [Add additional notes...]
```

## Functional Requirements

### **FR-149-1: Three-State Control**
- **Disabled**: Complete feature disable, zero impact on current system
- **Manual Only**: User metadata input without AI extraction
- **Full Intelligence**: AI extraction + user editing capabilities

### **FR-149-2: Post-Processing Integration**
- Add metadata extraction as post-processing step after FT-140 Oracle detection
- Maintain existing two-pass conversation flow and timing
- Zero risk to existing Oracle detection system (FT-140)

### **FR-149-3: Intelligent Extraction (Full Intelligence Mode Only)**
- Extract quantities, durations, and contextual details using semantic understanding
- Preserve original user expressions alongside interpreted values
- Support Portuguese colloquialisms ("meio", "umas", "tempinho", "bastante")

### **FR-149-4: User Editability (Manual + Full Intelligence Modes)**
- Display metadata in collapsible UI component
- Allow user input and editing of metadata values
- Preserve user data independently of AI extractions

## Non-Functional Requirements

### **NFR-149-1: Performance**
- Zero additional API calls in Disabled and Manual modes
- Metadata extraction adds ≤300 tokens per activity in Full Intelligence mode
- UI remains responsive with collapsible design

### **NFR-149-2: Reliability**
- Configuration failures default to Disabled state
- Metadata extraction failures don't prevent activity storage
- Maintain existing 95% activity detection success rate

## Acceptance Criteria

### **AC-149-1: Configuration Control**
- [ ] `{"enabled": false}` results in zero metadata functionality (current system)
- [ ] `{"enabled": true, "ai_extraction": false}` shows user input only
- [ ] `{"enabled": true, "ai_extraction": true}` shows AI extraction + user input
- [ ] Configuration changes take effect on app restart

### **AC-149-2: State Behaviors**
- [ ] **Disabled**: No metadata sections in UI, no extraction in detection
- [ ] **Manual Only**: User input fields visible, no AI extraction
- [ ] **Full Intelligence**: AI extraction + user editing both functional

### **AC-149-3: Semantic Intelligence (Full Intelligence Mode)**
- [ ] "meio copo" interpreted as ~125ml with original expression preserved
- [ ] "umas flexões" estimated as ~10 reps with confidence level
- [ ] Portuguese colloquialisms handled intelligently
- [ ] User can edit all AI-extracted values

## Implementation Plan

### **Step 1: Configuration Infrastructure (45 minutes)** ✅ COMPLETED
- ✅ Create `metadata_intelligence_config.json`
- ✅ Implement `MetadataConfig` class with three-state logic
- ✅ Test configuration loading and state detection

### **Step 2: ActivityModel Enhancement (30 minutes)** ✅ COMPLETED
- ✅ Add metadata fields to `ActivityModel`
- ✅ Implement state-aware access methods
- ✅ Update database schema (Isar auto-migration)

### **Step 3: UI Implementation (1.5 hours)** ✅ COMPLETED
- ✅ Create collapsible metadata section with state awareness
- ✅ Implement user input fields for Manual and Full Intelligence modes
- ✅ Add AI metadata display for Full Intelligence mode
- ✅ Test UI behavior in all three states

### **Step 4: Post-Processing Integration (1.5 hours)** 🔄 IN PROGRESS
- [x] ✅ **Core Implementation Complete**: All FT-149 services implemented
- [x] ✅ **MetadataExtractionService**: Focused Claude calls with Portuguese colloquialisms
- [x] ✅ **ActivityModel**: JSON metadata fields with safe parsing
- [x] ✅ **ActivityMemoryService**: Post-processing integration ready
- [ ] ❌ **INTEGRATION GAP**: Missing context passing in `ClaudeService._logActivitiesWithPreciseTime()`
  - **Issue**: Oracle detection not passing `userMessage` and `oracleActivityName` to metadata extraction
  - **Fix Required**: Single method update to pass required parameters
  - **Status**: Ready for implementation (surgical change)
- [ ] **UI Integration**: Metadata display components not yet implemented
  - **Current**: Metadata extracted and stored in database
  - **Missing**: ActivityCard collapsible metadata section
  - **Impact**: No visual feedback to users yet

## 🚧 Current Implementation Status (September 2025)

### **✅ Completed Components**
- **MetadataConfig**: Feature flag system with 3-state management
- **MetadataExtractionService**: Focused Claude API calls with Portuguese support
- **ActivityModel**: JSON metadata storage with safe parsing helpers
- **ActivityMemoryService**: Post-processing integration infrastructure
- **ClaudeService**: Public `callClaudeWithPrompt()` method for focused calls

### **❌ Integration Gap Identified**
**Problem**: Oracle detection (FT-140) → Metadata extraction (FT-149) bridge incomplete

**Root Cause**: `ClaudeService._logActivitiesWithPreciseTime()` not passing required context:
```dart
// Current (missing context)
await ActivityMemoryService.logActivity(/* basic params only */);

// Required (with FT-149 context)
await ActivityMemoryService.logActivity(
  // ... existing params
  userMessage: userMessage,           // ❌ Missing
  oracleActivityName: detected['activityName'], // ❌ Missing
);
```

**Impact**: Metadata extraction never triggers (condition `userMessage != null && oracleActivityName != null` never met)

### **🔧 Next Steps**
1. **Integration Fix** (15 minutes): Update `ClaudeService._logActivitiesWithPreciseTime()` parameter passing
2. **UI Implementation** (2-3 hours): ActivityCard metadata display components
3. **End-to-End Testing**: Verify complete flow from user input → UI display

## Success Metrics

- **Configuration Reliability**: 100% correct state detection from config
- **State Isolation**: Each state behaves independently without interference
- **Metadata Capture Rate** (Full Intelligence): 70% of activities with quantifiable details
- **User Adoption** (Manual Mode): 30% of users add manual metadata within first week
- **Performance Impact**: ≤300 token increase in Full Intelligence mode only

## Dependencies

- **FT-064**: Semantic activity detection (existing)
- **FT-119**: Activity queue system (existing)
- **ActivityModel**: Current data model and storage

## Migration Strategy

- **Backward Compatible**: Existing activities work unchanged (null metadata)
- **Default State**: `{"enabled": false}` maintains current system behavior
- **Gradual Rollout**: Enable Manual mode first, then Full Intelligence
- **Zero Downtime**: No breaking changes to existing functionality

---

**Key Innovation**: Simple two-flag system provides three distinct operational modes, enabling gradual rollout from current system → manual metadata → full AI intelligence, with complete rollback capability at any time.
