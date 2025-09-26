# FT-149: Metadata pass-through in two-pass detection (GPT-5 High)

- Feature ID: FT-149
- Priority: High
- Status: Proposed Fix (safe, additive)
- Owner: GPT-5 High

## Context
- Observed: Activities detected via FT-140 MCP path are saved with `metadata: null`.
- UI/logs confirm detection and storage work; only metadata is missing.
- Root cause: Metadata is never propagated through the pipeline.

## Root Cause (precise)
- `ActivityDetection` has no `metadata` field.
- `SystemMCPService._parseDetectionResults` does not extract flat keys (`quantitative_*`).
- `ClaudeService._processDetectedActivitiesFromMCP` does not extract or pass metadata.
- `IntegratedMCPProcessor._logActivitiesWithPreciseTime` does not forward metadata to `ActivityModel.fromDetection`.
- Fallback (`SemanticActivityDetector`) also lacks metadata extraction.

## Fix Scope (minimal, no prompt changes)
Safe pass-through only. No detection rules change; zero risk to activity classification.

1) Data model (in-memory)
- Add to `ActivityDetection`:
  - `final Map<String, dynamic> metadata;` (default: `{}`).

2) MCP parsing → in-memory
- `SystemMCPService._parseDetectionResults(...)`:
  - Import `FlatMetadataParser`.
  - For each `activityData` map, set:
    - `metadata: FlatMetadataParser.extractRawQuantitative(activityData)`

3) Claude MCP results → in-memory
- `ClaudeService._processDetectedActivitiesFromMCP(...)`:
  - Import `FlatMetadataParser`.
  - For each `data` map, set:
    - `metadata: FlatMetadataParser.extractRawQuantitative(data)`

4) In-memory → storage
- `IntegratedMCPProcessor._logActivitiesWithPreciseTime(...)`:
  - When constructing `ActivityModel.fromDetection(...)`, pass:
    - `metadata: detection.metadata`

5) Fallback path (optional but recommended)
- `SemanticActivityDetector._parseDetectionResults(...)`:
  - `metadata: FlatMetadataParser.extractRawQuantitative(activity)`

## Data Format (flat, no nesting)
- Keys: `quantitative_{type}_value`, `quantitative_{type}_unit`
- Examples:
  - `quantitative_steps_value: 7000`, `quantitative_steps_unit: "steps"`
  - `quantitative_volume_value: 220`, `quantitative_volume_unit: "ml"`
  - `quantitative_distance_value: 444`, `quantitative_distance_unit: "meters"`

## Logging (existing Logger only)
- Add debug breadcrumbs (class + message) at:
  - MCP JSON parsed → "extracted metadata keys: ..."
  - ActivityDetection created → "metadata.size=..."
  - Persisting model → "metadata null?/len"
- Do not use `print`.

## Acceptance Criteria
- AC-1: When message contains numbers+units (e.g., "bebi 220 ml de água e andei 444 m"), stored activities for SF1/SF15 have non-null `metadata` with the flat keys.
- AC-2: When no numbers+units present, `metadata` is `null` in the DB (constructor already converts empty `{}` → `null`).
- AC-3: No change in detected activity codes vs. current behavior.
- AC-4: `flutter test` passes; existing metadata tests remain green.

## Test Plan (very focused, simple, no mocks)
1) Unit: `FlatMetadataParser` (already exists; keep green).
2) Unit: Add test for `ActivityModel.fromDetection(metadata: {...})` → JSON stored, `null` when `{}`.
3) Integration (FT-140 path, offline fixture):
   - Simulate MCP result list item containing `quantitative_*` fields and assert the saved `ActivityModel.metadata` is non-null and includes those fields.
4) UI smoke: `MetadataInsights` renders values when `metadata` present.

## Risks & Mitigations
- Risk: None to detection quality (no prompt edits).
- Mitigation: Feature is additive; gracefully degrades to `null` metadata.

## Rollback
- Revert the 4 touched files; DB schema unchanged (metadata already present).

## Implementation Checklist
- [ ] Add `metadata` to `ActivityDetection` with default `{}`
- [ ] SystemMCPService: extract and attach metadata
- [ ] ClaudeService: extract and attach metadata
- [ ] IntegratedMCPProcessor: pass metadata to storage
- [ ] (Optional) SemanticActivityDetector: extract and attach metadata
- [ ] Run build_runner and tests

## Notes
- Prompt enhancement (`MetadataPromptEnhancement.getInstructions()`) can be added later behind a flag, after pass-through proves stable.


