### Feature: Config-only persona extensibility (add personas without code changes)

- ID: FT-022
- Type: Improvement / Architecture
- Status: Proposed

### Summary
Enable adding a new persona by only:
1) Dropping a new persona config file under `assets/config/`
2) Updating `assets/config/personas_config.json`

No code changes required after a one-time refactor that removes hardcoded persona paths and the enum switch.

### Goals
- Dynamically discover persona config paths from `personas_config.json`.
- Keep current UX (runtime persona switching) intact.
- Backward compatible with existing Ari and Sergeant Oracle configs.
- Only Ari and Sergeant Oracle are supported; Zen Guide and Claude are removed.

### Non-Goals
- Changing how prompts are authored; only how they’re wired.
- Adding UI for persona management.

### Proposed `personas_config.json` schema (simplified)
Only `configPath` is required for each persona. No external prompt overrides.

```json
{
  "enabledPersonas": ["ariLifeCoach", "sergeantOracle"],
  "defaultPersona": "ariLifeCoach",
  "personas": {
    "ariLifeCoach": {
      "enabled": true,
      "displayName": "Ari - Life Coach",
      "description": "...",
      "configPath": "assets/config/ari_life_coach_config_2.0.json"
    },
    "sergeantOracle": {
      "enabled": true,
      "displayName": "Sergeant Oracle",
      "description": "...",
      "configPath": "assets/config/sergeant_oracle_config.json"
    }
  }
}
```

Notes:
- `configPath` points directly to the persona’s JSON config (persona-only overlay for Ari 2.0).
- Zen Guide and Claude are no longer present in the schema or assets; any legacy references must be removed or routed to supported personas.

### One-time refactor (enables config-only additions)
- Replace hardcoded switch/enum in `lib/config/character_config_manager.dart` with dynamic resolution:
  - Active persona becomes a string key from `personas_config.json` (no enum expansion needed).
  - Read `configPath` from the active persona entry to load system prompt/exploration prompts.
  - Keep `.env` support (e.g., `DEFAULT_PERSONA`).

### Acceptance Criteria
- Adding a new persona only requires adding a file and updating `personas_config.json` (no code changes).
- Existing personas (Ari, Sergeant Oracle) continue to work.
- Default persona comes from `defaultPersona` (or `.env` override if set).

### Migration
1) Update `personas_config.json` to include `configPath` for Ari and Sergeant Oracle only.
2) Refactor `CharacterConfigManager` to remove deprecated persona code paths (Zen Guide, Claude) and move to dynamic lookup using `personas_config.json`.
3) Keep Oracle + persona composition behavior from FT-021.

### Testing (very focused)
- Unit: For a mocked `personas_config.json` with a new persona key/path, manager loads from `configPath` without any code changes to personas.
- Unit: Default persona resolves from `defaultPersona` (and `.env` override if present).
- Integration: Switching personas at runtime pulls correct prompts/config via the dynamic paths.

### Rollback
- Revert `CharacterConfigManager` to the previous switch-based approach.


