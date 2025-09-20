# FT-146: Oracle-Based Dimension Display Fix

**Feature ID**: FT-146  
**Priority**: Medium  
**Category**: Bug Fix / Technical Debt  
**Effort**: 3 hours  

## Problem Statement

The `ActivityCard` widget contains hardcoded dimension mappings that are:

1. **Outdated**: Missing Oracle 4.2 dimensions (TT, PR, F)
2. **Hardcoded**: English translations instead of using Oracle JSON data
3. **Duplicated**: Same logic exists in `SystemMCPService` and `ActivityCard`
4. **Inconsistent**: Some dimensions use codes (SF), others use full names (SAUDE_FISICA)
5. **Unmaintainable**: Changes require updates in multiple places

**Current Issues**:
- Missing "Screen Time", "Anti-Procrastination", "Finance" dimensions
- Hardcoded English names instead of Oracle JSON `display_name`
- Code duplication between UI and service layers

## Root Cause

The Oracle JSON already contains proper dimension information:
```json
{
  "TT": {
    "code": "TT",
    "name": "TEMPO DE TELA", 
    "display_name": "Tempo de Tela"
  },
  "PR": {
    "code": "PR", 
    "name": "PROCRASTINAÇÃO",
    "display_name": "Procrastinação"
  }
}
```

But the current system:
1. **OracleDimension model** doesn't capture `display_name`
2. **ActivityCard** uses hardcoded English translations
3. **Missing Oracle integration** in UI layer

## Solution

Use Oracle JSON as the single source of truth for all dimension display information.

## Functional Requirements

### FR-1: Oracle Integration
- **MUST** read dimension display names from Oracle JSON
- **MUST** support all Oracle 4.2 dimensions (SF, R, TG, E, SM, TT, PR, F)
- **MUST** use `display_name` field from Oracle configuration

### FR-2: Eliminate Hardcoding
- **MUST** remove all hardcoded dimension mappings from ActivityCard
- **MUST** remove duplicate logic from SystemMCPService
- **MUST** use Oracle data for colors and icons (with smart defaults)

### FR-3: Backward Compatibility
- **MUST** maintain existing UI appearance for known dimensions
- **MUST** gracefully handle missing Oracle data
- **MUST** provide fallbacks for unknown dimensions

## Technical Implementation

### Step 1: Extend OracleDimension Model

**File**: `lib/services/semantic_activity_detector.dart`

```dart
class OracleDimension {
  final String code;
  final String name;           // "TEMPO DE TELA"
  final String displayName;    // "Tempo de Tela" - NEW
  final List<OracleActivity> activities;

  OracleDimension({
    required this.code,
    required this.name,
    required this.displayName,  // NEW
    required this.activities,
  });
}
```

### Step 2: Update Oracle Context Manager

**File**: `lib/services/oracle_context_manager.dart`

**Location**: `_loadOracleFromPath()` method, line 111-116

```dart
dimensions[dimensionCode] = OracleDimension(
  code: dimensionCode,
  name: dimensionData['name'] as String? ?? dimensionCode,
  displayName: dimensionData['display_name'] as String? ?? 
               dimensionData['name'] as String? ?? 
               dimensionCode,  // NEW: Capture display_name
  activities: activities,
);
```

### Step 3: Create Dimension Display Service

**File**: `lib/services/dimension_display_service.dart` (NEW)

```dart
import '../services/oracle_context_manager.dart';
import '../services/semantic_activity_detector.dart';
import 'package:flutter/material.dart';

class DimensionDisplayService {
  static OracleContext? _cachedContext;
  
  /// Initialize with current Oracle context
  static Future<void> initialize() async {
    _cachedContext = await OracleContextManager.getForCurrentPersona();
  }
  
  /// Get display name from Oracle data
  static String getDisplayName(String dimensionCode) {
    final dimension = _cachedContext?.dimensions[dimensionCode.toUpperCase()];
    return dimension?.displayName ?? dimensionCode;
  }
  
  /// Get dimension color with smart defaults
  static Color getColor(String dimensionCode) {
    switch (dimensionCode.toUpperCase()) {
      case 'SF': return Colors.green;      // Physical Health
      case 'SM': return Colors.blue;       // Mental Health  
      case 'TG': case 'T': return Colors.orange; // Work & Management
      case 'R': return Colors.pink;        // Relationships
      case 'E': return Colors.purple;      // Spirituality
      case 'TT': return Colors.red;        // Screen Time
      case 'PR': return Colors.amber;      // Anti-Procrastination
      case 'F': return Colors.teal;        // Finance
      default: return Colors.grey;
    }
  }
  
  /// Get dimension icon with smart defaults
  static IconData getIcon(String dimensionCode) {
    switch (dimensionCode.toUpperCase()) {
      case 'SF': return Icons.fitness_center;
      case 'SM': return Icons.psychology;
      case 'TG': case 'T': return Icons.work;
      case 'R': return Icons.people;
      case 'E': return Icons.self_improvement;
      case 'TT': return Icons.screen_time;
      case 'PR': return Icons.timer;
      case 'F': return Icons.account_balance_wallet;
      default: return Icons.category;
    }
  }
  
  /// Refresh context when persona changes
  static Future<void> refresh() async {
    await initialize();
  }
}
```

### Step 4: Update ActivityCard Widget

**File**: `lib/widgets/stats/activity_card.dart`

**Remove**: All hardcoded methods (`_getDimensionColor`, `_getDimensionIcon`, `_getDimensionDisplayName`)

**Replace with**:
```dart
import '../../services/dimension_display_service.dart';

class ActivityCard extends StatelessWidget {
  // ... existing code ...

  @override
  Widget build(BuildContext context) {
    return Card(
      // ... existing card structure ...
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity header with code and time
            Row(
              children: [
                if (code != null && code!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: DimensionDisplayService.getColor(dimension).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: DimensionDisplayService.getColor(dimension).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      code!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: DimensionDisplayService.getColor(dimension),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // ... rest of header ...
              ],
            ),

            const SizedBox(height: 8),

            // Dimension and confidence info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DimensionDisplayService.getColor(dimension).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        DimensionDisplayService.getIcon(dimension),
                        size: 12,
                        color: DimensionDisplayService.getColor(dimension),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DimensionDisplayService.getDisplayName(dimension),
                        style: TextStyle(
                          fontSize: 11,
                          color: DimensionDisplayService.getColor(dimension),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // ... rest of row ...
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 5: Remove Duplicate Logic from SystemMCPService

**File**: `lib/services/system_mcp_service.dart`

**Remove**: `_getDimensionDisplayName()` method (lines 686-718)

**Replace**: Use `DimensionDisplayService.getDisplayName()` in line 389

### Step 6: Initialize Service at App Startup

**File**: `lib/main.dart`

```dart
// Add to main() function after Oracle cache initialization
await DimensionDisplayService.initialize();
```

## Acceptance Criteria

### AC-1: Oracle Integration ✅
- ✅ Displays "Tempo de Tela" for TT dimension (from Oracle JSON)
- ✅ Displays "Procrastinação" for PR dimension (from Oracle JSON)  
- ✅ Displays "Finanças" for F dimension (from Oracle JSON)
- ✅ Uses Oracle `display_name` field as source of truth

### AC-2: Hardcoding Elimination ✅
- ✅ No hardcoded dimension names in ActivityCard
- ✅ No duplicate logic between UI and service layers
- ✅ Single source of truth (Oracle JSON)

### AC-3: Backward Compatibility ✅
- ✅ Existing dimensions (SF, R, TG, E, SM) display correctly
- ✅ Colors and icons remain consistent
- ✅ Graceful fallback for missing Oracle data

### AC-4: New Dimension Support ✅
- ✅ TT (Screen Time) displays with red color and screen_time icon
- ✅ PR (Anti-Procrastination) displays with amber color and timer icon
- ✅ F (Finance) displays with teal color and wallet icon

## Testing Strategy

### Test Cases
1. **Oracle Integration**: Verify dimension names come from Oracle JSON
2. **Missing Data Handling**: Test fallback behavior when Oracle unavailable
3. **Persona Switching**: Ensure display updates when changing personas
4. **New Dimensions**: Validate TT, PR, F dimensions display correctly

### Validation Commands
```bash
# Test Oracle integration
flutter test test/dimension_display_service_test.dart

# Test UI integration  
flutter test test/activity_card_oracle_integration_test.dart
```

## Implementation Notes

### Design Decisions
1. **Service Pattern**: Centralized dimension logic in dedicated service
2. **Oracle First**: Use Oracle JSON as primary source, fallback to defaults
3. **Lazy Loading**: Initialize service at app startup for performance
4. **Smart Defaults**: Maintain existing colors/icons for consistency

### Migration Strategy
1. **Phase 1**: Create service and extend Oracle model
2. **Phase 2**: Update ActivityCard to use service
3. **Phase 3**: Remove duplicate logic from other components
4. **Phase 4**: Add initialization to app startup

## Success Metrics

- ✅ **0 Hardcoded Strings**: All dimension names from Oracle JSON
- ✅ **100% Oracle Coverage**: All 8 Oracle 4.2 dimensions supported
- ✅ **Code Reduction**: ~50 lines removed from ActivityCard
- ✅ **Maintainability**: Single source of truth for dimension display

## Dependencies

- Oracle JSON structure (existing)
- OracleContextManager (existing)
- App initialization sequence (existing)

---

**Estimated Time**: 3 hours  
**Risk Level**: Low (backward compatible changes)  
**Impact**: Medium (eliminates technical debt, adds Oracle 4.2 support)
