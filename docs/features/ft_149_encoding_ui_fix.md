# FT-149.5: Encoding & UI Display Fix

## Problems
1. **UTF-8 Encoding**: Portuguese characters corrupted (`Respiração` → `RespiraÃ§Ã£o`)
2. **UI Display**: Rich metadata not showing for new structure (activities 79-81)

## Root Causes
1. **Missing charset** in `LeanClaudeConnector` HTTP headers
2. **Missing parser** for new `quantitative/qualitative/relational/behavioral` structure in `MetadataInsightGenerator`

## Solutions

### Fix 1: UTF-8 Encoding
**File**: `lib/services/lean_claude_connector.dart`
```dart
// BEFORE
'Content-Type': 'application/json',

// AFTER  
'Content-Type': 'application/json; charset=utf-8',
```

### Fix 2: New Metadata Structure Parser
**File**: `lib/services/metadata_insight_generator.dart`

Add new parser method:
```dart
static List<String> _extractNewStructureInsights(Map<String, dynamic> metadata) {
  final insights = <String>[];
  
  // Quantitative
  final quantitative = metadata['quantitative'];
  if (quantitative is Map<String, dynamic>) {
    quantitative.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final val = value['value'];
        final unit = value['unit'];
        if (val != null && unit != null) {
          insights.add('📊 $val $unit');
        }
      }
    });
  }
  
  // Qualitative
  final qualitative = metadata['qualitative'];
  if (qualitative is Map<String, dynamic>) {
    qualitative.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final desc = value['description'] ?? value['difficulty'];
        if (desc != null) {
          insights.add('✨ $desc');
        }
      }
    });
  }
  
  // Behavioral
  final behavioral = metadata['behavioral'];
  if (behavioral is Map<String, dynamic>) {
    behavioral.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final reason = value['reason'];
        if (reason != null) {
          insights.add('🎯 $reason');
        }
      }
    });
  }
  
  return insights;
}
```

Update `generateSummary()`:
```dart
// Add at start of generateSummary() method
if (metadata.containsKey('quantitative') || 
    metadata.containsKey('qualitative') || 
    metadata.containsKey('behavioral')) {
  final newInsights = _extractNewStructureInsights(metadata);
  if (newInsights.isNotEmpty) insights.addAll(newInsights);
}
```

## Expected Results
- ✅ Portuguese characters display correctly
- ✅ Rich metadata shows in UI for activities 79-81
- ✅ Maintains 100% metadata extraction success
