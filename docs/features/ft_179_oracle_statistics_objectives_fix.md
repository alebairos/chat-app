# FT-179: Oracle Statistics Objectives Fix

**Feature ID:** FT-179  
**Priority:** High  
**Category:** Bug Fix  
**Effort Estimate:** 1-2 hours  

## Problem Statement

Personas provide incorrect objective counts when users ask "Quantos objetivos vc tem no seu bd?":
- **Current Response:** "17 objetivos principais" (hardcoded/approximated)
- **Actual Data:** 28 objectives in `oracle_prompt_4.2_goals_mapping.json`
- **Root Cause:** `oracle_get_statistics` MCP function doesn't include objectives data
- **Violation:** Breaks Oracle extension's "never_approximate" rule

## Solution

Extend existing `oracle_get_statistics` MCP function to include objectives data from goals mapping JSON with performance-optimized caching.

## Technical Implementation

### 1. Extend OracleStaticCache

**File:** `lib/services/oracle_static_cache.dart`

```dart
class OracleStaticCache {
  // Add goals mapping cache
  static Map<String, dynamic>? _goalsMappingCache;
  static bool _goalsMappingInitialized = false;
  
  static Future<void> initializeGoalsMapping() async {
    if (_goalsMappingInitialized) return;
    
    try {
      final jsonString = await rootBundle.loadString(
        'assets/config/oracle/oracle_prompt_4.2_goals_mapping.json'
      );
      _goalsMappingCache = json.decode(jsonString);
      _goalsMappingInitialized = true;
      Logger().info('✅ Goals mapping cache initialized');
    } catch (e) {
      Logger().warning('Failed to load goals mapping: $e');
    }
  }
  
  static Map<String, dynamic> getObjectivesStatistics() {
    if (!_goalsMappingInitialized || _goalsMappingCache == null) {
      return {
        'total_objectives': 0,
        'objectives_by_dimension': <String, List<String>>{},
        'all_objectives': <String>[]
      };
    }
    
    return _extractObjectivesFromCache();
  }
  
  static Map<String, dynamic> _extractObjectivesFromCache() {
    final goalTrilhaMapping = _goalsMappingCache!['goal_trilha_mapping'] as Map<String, dynamic>? ?? {};
    final objectivesByDimension = <String, List<String>>{};
    final allObjectives = <String>[];
    
    for (final entry in goalTrilhaMapping.entries) {
      final objectiveCode = entry.key;
      final objectiveData = entry.value as Map<String, dynamic>;
      final dimension = objectiveData['dimension'] as String? ?? 'Unknown';
      
      allObjectives.add(objectiveCode);
      objectivesByDimension.putIfAbsent(dimension, () => []).add(objectiveCode);
    }
    
    return {
      'total_objectives': allObjectives.length,
      'objectives_by_dimension': objectivesByDimension,
      'all_objectives': allObjectives,
    };
  }
}
```

### 2. Initialize Goals Mapping at Startup

**File:** `lib/main.dart`

```dart
// Add to existing Oracle initialization
try {
  await OracleStaticCache.initializeAtStartup();
  await OracleStaticCache.initializeGoalsMapping(); // NEW
  logger.info('✅ Oracle static cache and goals mapping initialized');
} catch (e) {
  logger.warning('Failed to initialize Oracle cache: $e');
}
```

### 3. Enhance oracle_get_statistics

**File:** `lib/services/system_mcp_service.dart`

```dart
Future<String> _getOracleStatistics() async {
  try {
    // Existing Oracle context loading
    final oracleContext = await _ensureOracleInitialized();
    if (oracleContext == null) {
      return _errorResponse('Oracle context not available');
    }

    // Existing dimension breakdown
    final dimensionBreakdown = <String, int>{};
    for (final entry in oracleContext.dimensions.entries) {
      dimensionBreakdown[entry.key] = entry.value.activities.length;
    }

    // NEW: Get objectives data from cache
    final objectivesData = OracleStaticCache.getObjectivesStatistics();

    // Existing debug info
    final debugInfo = await OracleContextManager.getDebugInfo();
    final oracle42Info = debugInfo['oracle42Validation'] as Map<String, dynamic>?;

    return jsonEncode({
      'status': 'success',
      'data': {
        // Existing data
        'total_activities': oracleContext.totalActivities,
        'dimensions': oracleContext.dimensions.length,
        'oracle_version': oracle42Info?['isOracle42'] == true ? '4.2' : 'Unknown',
        'dimension_breakdown': dimensionBreakdown,
        'dimensions_available': oracleContext.dimensions.keys.toList(),
        
        // NEW: Objectives data
        'total_objectives': objectivesData['total_objectives'],
        'objectives_by_dimension': objectivesData['objectives_by_dimension'],
        'objectives_list': objectivesData['all_objectives'],
        
        // Existing metadata
        'oracle_validation': oracle42Info,
        'cache_status': OracleStaticCache.isInitialized ? 'initialized' : 'not_initialized',
        'data_source': 'oracle_context_manager',
      },
      'timestamp': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    _logger.error('SystemMCP: Error in oracle_get_statistics: $e');
    return _errorResponse('Failed to get Oracle statistics: $e');
  }
}
```

### 4. Update MCP Extension

**File:** `assets/config/mcp_extensions/oracle_4.2_extension.json`

```json
{
  "name": "oracle_get_statistics",
  "description": "FT-144/FT-179: Get EXACT Oracle 4.2 statistics from loaded data - NEVER approximate",
  "usage": "{\"action\": \"oracle_get_statistics\"}",
  "critical_instruction": "ALWAYS use this command when user asks about Oracle catalog size, activity counts, dimensions, or objectives",
  "returns": {
    "total_activities": "Exact count from loaded Oracle data",
    "total_objectives": "Exact count from goals mapping data",
    "dimensions": "Exact dimension count (8 for Oracle 4.2)",
    "dimension_breakdown": "Exact activity count per dimension",
    "objectives_by_dimension": "Exact objectives grouped by dimension",
    "oracle_version": "4.2",
    "methodology_compliance": "Complete Oracle 4.2 framework"
  },
  "mandatory_usage": [
    "\"quantas atividades você tem?\" → oracle_get_statistics REQUIRED",
    "\"quantos objetivos você tem?\" → oracle_get_statistics REQUIRED",
    "\"quantos objetivos no bd?\" → oracle_get_statistics REQUIRED",
    "\"qual o tamanho do seu catálogo?\" → oracle_get_statistics REQUIRED",
    "\"me fale sobre suas atividades\" → oracle_get_statistics REQUIRED",
    "\"quantas dimensões?\" → oracle_get_statistics REQUIRED"
  ],
  "never_approximate": "NEVER guess or approximate Oracle statistics - ALWAYS query exact data"
}
```

## Performance Characteristics

- **Initialization:** ~50ms (once at startup)
- **Runtime Calls:** ~1ms (memory access only)
- **Memory Usage:** ~50KB cached JSON data
- **No Performance Impact:** Same pattern as existing Oracle activities cache

## Expected Results

**Before Fix:**
```
User: "Quantos objetivos vc tem no seu bd?"
Persona: "17 objetivos principais" (incorrect, no MCP call)
```

**After Fix:**
```
User: "Quantos objetivos vc tem no seu bd?"
Persona: Uses {"action": "oracle_get_statistics"}
Response: "Tenho 28 objetivos principais no Oracle 4.2, distribuídos em 8 dimensões..."
```

## Testing

1. **Unit Test:** Verify objectives extraction from goals mapping
2. **Integration Test:** Confirm MCP command returns correct data
3. **Persona Test:** Validate accurate responses to objectives queries
4. **Performance Test:** Ensure no regression in response times

## Dependencies

- Requires `oracle_prompt_4.2_goals_mapping.json` to be present
- Graceful fallback if goals mapping unavailable (returns 0 objectives)
- Backward compatible with existing `oracle_get_statistics` usage
