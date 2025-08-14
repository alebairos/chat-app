### Feature Fix: Single masculine ElevenLabs voice for pt_BR and en_US (simplified, no code changes)

- **ID**: FT-019
- **Type**: Fix
- **Area**: Audio Assistant > TTS (ElevenLabs)
- **Owner**: Voice/Audio
- **Status**: Proposed

### Summary
Ensure Ari uses the SAME masculine ElevenLabs voice with correct pronunciation and accent in both Portuguese (pt_BR) and English (en_US). This version proposes a configuration-only approach (no code changes) using a single env var for the voice.

### Problem
- Current voice selection does not guarantee a masculine Brazilian Portuguese voice with natural pronunciation.
- English responses may use a different voice or pronunciation model inconsistently.
- Voice selection is not explicitly tied to Ari’s male identity.

### Goals
- Always use a single masculine voice ID for Ari across pt_BR and en_US.
- Keep configuration to a single environment variable (no schema/code changes).
- Prefer multilingual model behavior already available in provider/platform; no code changes required here.

### Non-Goals
- Changing providers (we keep ElevenLabs).
- UI changes for selecting voices.

### Proposed Solution
1. Use a single multilingual-capable male voice ID via configuration.
   - Keep code free of hardcoded IDs.
   - Key:
     - ELEVEN_VOICE_ID_MALE_MULTILINGUAL
2. Update `CharacterVoiceConfig` to expose Ari’s default masculine voice ID and read the env override.
3. In `AudioAssistantTTSService._configureProviderForLanguage`, keep the same `voiceId` always, switch only `modelId`/tuning if needed:
   - Preferred model: `eleven_multilingual_v2` (if available) or fallback `eleven_multilingual_v1`.
   - For both pt_BR and en_US use the same `voiceId`.
4. Tuning values (both languages, adjust minimally if needed):
   - stability 0.65–0.70, similarityBoost 0.80, style 0.05–0.10
5. Fallbacks:
   - If `ELEVEN_VOICE_ID_MALE_MULTILINGUAL` missing → use Ari’s default masculine voice ID (from `CharacterVoiceConfig`).
   - If still missing → use provider default to avoid breaking TTS.

### Configuration (no code changes)
- Add to `.env` (sample):
  - ELEVEN_LABS_API_KEY="<your_api_key>"
  - ELEVEN_LABS_VOICE_ID="Zk0wRqIFBWGMu2lIk7hw"  # Marcio
- Tip: If you already use ELEVENLABS_API_KEY/ELEVENLABS_VOICE_ID, keep those; both naming styles are read.

### Code Changes
- None. This fix relies solely on environment configuration that is already supported by the provider.

### Acceptance Criteria
- pt_BR message: Ari speaks with a natural Brazilian Portuguese masculine voice (correct accent and pronunciation).
- en_US message: Ari speaks with a natural American English masculine voice.
- Language switching between pt_BR and en_US keeps the SAME voice ID (no voice change), only prosody/model adapts.
- If environment voice ID is missing, TTS still works with the default Ari masculine voice, or provider default if not set.

### Testing Strategy
- Very focused; simple; no mocks needed initially.
1. Unit: Voice selection logic (conceptual)
   - Given language pt_BR → `voiceId` = value from ELEVEN_LABS_VOICE_ID
   - Given language en_US → `voiceId` = value from ELEVEN_LABS_VOICE_ID
   - Missing env → provider uses its existing default voice
2. Integration: TTS generate path-only
   - Call `generateAudio("Olá", language: 'pt_BR')` and verify speech uses the same voice as en_US.
   - Call `generateAudio("Hello", language: 'en_US')` and verify speech uses the same voice.
3. Later (optional, ask before using mocks): add provider call verification with a minimal mock to assert `voiceId` is in the request payload.

### Rollout
- Behind configuration only; safe to ship.
- Default remains stable; adding IDs improves speech quality immediately once provided.

### Risks & Mitigations
- Risk: Missing env values → Mitigation: robust fallbacks as above.
- Risk: Wrong model for language → Mitigation: unit tests on `_configureProviderForLanguage`.

### Implementation Steps
No steps. Configuration-only rollout.

### Acceptance Test Data
- pt_BR sample: "Hoje foi um bom dia." → natural Brazilian male accent.
- en_US sample: "This is a clear English sentence." → natural American male accent.

### Notes
- Choose actual ElevenLabs male voice IDs that you confirm sound natural in pt_BR and en_US. Add them to `.env` without committing the secrets.


