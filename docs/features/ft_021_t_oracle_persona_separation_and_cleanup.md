### Feature: Separate Oracle (shared KB) from Personas; keep only Ari and Sergeant Oracle (aligned with config-only extensibility)

- ID: FT-021
- Type: Refactor / Cleanup / Config
- Status: In Progress

### Summary
Refactor prompt architecture to separate the Oracle knowledge base (authors, methods, protocols, habit catalog) from persona overlays (style/voice). Keep only two personas: Ari (Life Coach) and Sergeant Oracle. Decommission Zen Guide and Claude. Configure the Oracle prompt path via `.env`. Personas remain config-only per FT-022 (no code change needed to add/remove personas).

This update introduces a persona-only Ari 2.0 config and moves all non-persona content from Ari 1.0 into an Oracle prompt file to preserve semantics while enabling FT-022.

### Goals
- Single source of truth for the coaching system (Oracle) shared across all personas.
- Personas only define communication style, brevity rules, and exploration prompts.
- Keep only Ari and Sergeant Oracle personas; remove Zen Guide and Claude configs.
- Configure Oracle prompt path via `.env`.

### Non-Goals
- UI changes beyond existing persona selection.
- Changing the Oracle knowledge content itself.

### Current State (assets/config)
- `ari_life_coach_config_1.0.json` (new Ari)
- `ari_life_coach_config.json` (legacy Ari)
- `sergeant_oracle_config.json`
- `zen_guide_config.json` (to be removed)
- `claude_config.json` (to be removed)
- `personas_config.json`

### Proposed Architecture (compatible with FT-022)
- Oracle (shared KB):
  - Path: `assets/config/oracle/oracle_prompt_1.0.md`
  - Env: `ORACLE_PROMPT_PATH=assets/config/oracle/oracle_prompt_1.0.md`
  - Content: frameworks, protocols, objectives, trilhas, and full habits catalog — strictly extracted from `assets/config/ari_life_coach_config_1.0.json` and excluding persona tone.
- Personas (overlay):
  - Defined in `assets/config/personas_config.json` with a `configPath` per FT-022
  - Ari → `configPath: assets/config/ari_life_coach_config_2.0.json` (persona-only: tone/style + exploration prompts)
  - Sergeant Oracle → `configPath: assets/config/sergeant_oracle_config.json`
  - Remove: Zen Guide and Claude entries and their config files

### Runtime Behavior
Build final system prompt as:
1) Oracle prompt (from `ORACLE_PROMPT_PATH`)
2) Persona overlay (current persona config/system style)

Fallbacks (preserve semantics of Ari 1.0):
- If Oracle path missing/unset → use Ari 1.0 full config (`assets/config/ari_life_coach_config_1.0.json`).
- If Ari 2.0 persona overlay missing → fallback to Ari 1.0 full config.
- Legacy fallback for Ari still supported: `assets/config/ari_life_coach_config.json`.

Persona selection:
- User selection in the app updates the active persona immediately via `CharacterConfigManager.setActivePersona(...)` and subsequent calls to `ConfigLoader.loadSystemPrompt()` will compose Oracle + the newly selected persona overlay.
- Oracle is always attempted first (env `ORACLE_PROMPT_PATH` or default `assets/config/oracle/oracle_prompt_1.0.md`). If Oracle fails to load, Ari falls back to 1.0 to preserve semantics; other personas return their overlay-only content.

### .env Configuration
- `ORACLE_PROMPT_PATH=assets/config/oracle/oracle_prompt_1.0.md`
- `DEFAULT_PERSONA=ariLifeCoach` (optional)

### Code Changes (minimal, and aligned with FT-022)
- Persona discovery/loading should use `personas_config.json` with `configPath` (FT-022). Until FT-022 is merged, keep current enum-based behavior but prefer Ari 2.0 when available.
- In `loadSystemPrompt()`: if `ORACLE_PROMPT_PATH` is set, load and prepend oracle to the persona overlay; if not set or fails, fallback to Ari 1.0 full config to preserve semantics.
- `loadExplorationPrompts()` remains persona-driven (sourced from Ari 2.0 overlay).
- Update `assets/config/personas_config.json` to include `configPath` fields for personas.

### Migration Steps
1) Create `assets/config/oracle/oracle_prompt_1.0.md` by extracting all non-persona content from `assets/config/ari_life_coach_config_1.0.json`.
2) Create `assets/config/ari_life_coach_config_2.0.json` containing only persona tone/style and `exploration_prompts`.
3) Update `assets/config/personas_config.json` to add `configPath` for Ari → `ari_life_coach_config_2.0.json` and Sergeant Oracle.
4) Keep Ari 1.0 and legacy Ari configs for fallback to preserve semantics.
5) Ensure FT-022 will read `configPath` dynamically; until then, prefer Ari 2.0 in code when Oracle is present.
6) Verify build includes `assets/config/oracle/` (directory-level asset already present in `pubspec.yaml`).

### Testing Strategy (very focused)
- Unit: oracle + persona composition
  - With `ORACLE_PROMPT_PATH` set → final prompt contains Oracle content + Ari 2.0 persona overlay.
  - Without `ORACLE_PROMPT_PATH` → final prompt equals Ari 1.0 full content.
- Unit: fallbacks
  - Missing Ari 2.0 overlay → fallback to Ari 1.0.
  - Missing Oracle file → fallback to Ari 1.0.
- Integration: persona switch
  - Switch between Ari and Sergeant Oracle; Oracle content remains present/unchanged when env is set.

### Rollback
- Re-add removed persona config files and revert `personas_config.json` if needed.


