### Feature Improvement: Adopt `ari_life_coach_config_1.0.json` as Ari's primary config

- ID: FT-020
- Type: Improvement
- Area: Configuration loading (Ari persona)
- Status: Proposed

### Summary
Adopt the newly created `assets/config/ari_life_coach_config_1.0.json` as the primary configuration source for the Ari persona, replacing the older `assets/config/ari_life_coach_config.json`. Keep a safe fallback to the previous file to avoid runtime failures. No runtime behavior change beyond loading the new prompt content (CSV references removed; catalog embedded).

### Problem
- Ari still loads `assets/config/ari_life_coach_config.json` by default via `CharacterConfigManager`.
- The newer `ari_life_coach_config_1.0.json` contains the improved, self-contained prompt (no CSV references) and should be the default.

### Goals
- Use `assets/config/ari_life_coach_config_1.0.json` as the default Ari config.
- Preserve a transparent fallback to `assets/config/ari_life_coach_config.json` if the 1.0 file is not present.
- Zero user-facing UI changes; seamless switch.

### Non-Goals
- Changing persona metadata or enabling/disabling personas.
- Restructuring asset paths or changing `pubspec.yaml` assets (already includes `assets/config/`).

### Proposed Change (minimal)
1. Update `CharacterConfigManager.configFilePath` mapping for `CharacterPersona.ariLifeCoach` to point to `assets/config/ari_life_coach_config_1.0.json`.
2. Add a narrow fallback when loading the JSON:
   - If loading 1.0 fails, try the previous `assets/config/ari_life_coach_config.json`.
3. Keep the existing external text prompt override logic intact (if external prompt not found, fallback to JSON).

### Acceptance Criteria
- When Ari is the active persona, system prompt and `exploration_prompts` load from `assets/config/ari_life_coach_config_1.0.json`.
- If the 1.0 file is missing or unreadable, the app gracefully falls back to `assets/config/ari_life_coach_config.json` with no crash.
- No changes for other personas.

### Implementation Steps
1. File: `lib/config/character_config_manager.dart`
   - Change the `configFilePath` for `CharacterPersona.ariLifeCoach` to `assets/config/ari_life_coach_config_1.0.json`.
   - In `loadSystemPrompt()` and `loadExplorationPrompts()` where we currently do:
     - `rootBundle.loadString(configFilePath)` → wrap with a try/catch and, on failure, try the legacy path `assets/config/ari_life_coach_config.json`.
2. No changes required in `pubspec.yaml` (directory-level asset already included).

### Testing Strategy (very focused, simple, no mocks)
1. Unit: Path mapping
   - Assert `CharacterConfigManager().configFilePath` equals `assets/config/ari_life_coach_config_1.0.json` when active persona is Ari.
2. Unit: Fallback on missing file
   - Temporarily simulate missing 1.0 asset (test environment) and assert it falls back to `assets/config/ari_life_coach_config.json` without throwing.
3. Integration: Prompt load
   - Call `loadSystemPrompt()` with Ari active and assert the loaded prompt contains unique text from the 1.0 config (e.g., the enhanced catalog section or welcome).
   - Call `loadExplorationPrompts()` and assert keys `physical`, `mental`, `relationships`, `work`, `spirituality` are present and non-empty.

### Rollout
- Small PR; safe. If issues arise, revert the mapping to the legacy file.

### Notes
- The 1.0 file already consolidates catalog content and removes CSV references, aligning with the persona documentation efforts.


