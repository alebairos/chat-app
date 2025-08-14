# FT-025: Prompt Documentation Generator Script

**Feature Type**: Developer Tool Enhancement  
**Priority**: Medium  
**Status**: Ready  
**Estimated Effort**: 1-2 hours  

## Problem Statement

The AI persona configurations are stored in JSON files with complex, minified content that is difficult to read, understand, and maintain. This creates several issues:

### Current Pain Points
1. **Poor Readability**: JSON format with escaped newlines (`\n`) makes prompts hard to read
2. **Difficult Maintenance**: Editing long prompt strings in JSON is error-prone
3. **No Documentation**: No human-readable documentation of what each persona does
4. **Hard to Review**: Code reviews of prompt changes are difficult
5. **Knowledge Transfer**: New team members struggle to understand persona configurations

### Example of Current Issue
```json
{
  "system_prompt": {
    "content": "Você é um Life Management Coach especializado em mudança comportamental baseada em evidências científicas.\n\n## FUNDAMENTOS TEÓRICOS\n\n### 1. TINY HABITS (BJ Fogg)\n- **Princípio**: Mudanças sustentáveis começam pequenas\n..."
  }
}
```

### Desired Output
```markdown
# Ari - Life Coach Configuration

## Overview
Ari is a Life Management Coach specialized in evidence-based behavioral change...

## System Prompt

### Role
Life Management Coach specialized in evidence-based behavioral change...

### Theoretical Foundations

#### 1. TINY HABITS (BJ Fogg)
- **Principle**: Sustainable changes start small
- **Application**: Always break down big goals into micro-habits
...
```

## Solution Overview

Create a single, minimal **Prompt Documentation Generator** script that:

1. Reads `assets/config/personas_config.json` to discover supported personas (Ari and Sergeant Oracle only)
2. Loads each persona `configPath` and extracts `system_prompt.content` and `exploration_prompts`
3. Converts prompt text to readable Markdown (newlines, headings, lists preserved)
4. Writes one Markdown file per persona/version under `docs/prompts/`

## Technical Requirements

### 1. Script Design (KISS)

Single Python script with a few small functions. No classes, no extra models.

```python
# scripts/generate_prompt_docs.py
import argparse
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description='Generate Markdown docs from persona configs')
    parser.add_argument('--persona', help='Filter by persona key (e.g., ari, sergeant_oracle)')
    parser.add_argument('--out', default='docs/prompts', help='Output directory')
    args = parser.parse_args()

    generate_all(persona_filter=args.persona, out_dir=Path(args.out))


def generate_all(persona_filter=None, out_dir=Path('docs/prompts')):
    personas = load_personas_config()
    out_dir.mkdir(parents=True, exist_ok=True)
    for p in personas:
        key = p.get('key') or p.get('name')
        if persona_filter and key != persona_filter:
            continue
        generate_persona_doc(p, out_dir)


def load_personas_config():
    cfg_path = Path('assets/config/personas_config.json')
    data = json.loads(cfg_path.read_text(encoding='utf-8'))
    return list(data.get('personas', []))


def generate_persona_doc(persona, out_dir: Path):
    config_path = Path(persona['configPath'])
    config = json.loads(config_path.read_text(encoding='utf-8'))
    system_content = str(((config.get('system_prompt') or {}).get('content')) or '')
    exploration = dict(config.get('exploration_prompts') or {})
    md_text = to_markdown(persona, system_content, exploration)
    out_name = config_path.name.replace('.json', '.md')
    (out_dir / out_name).write_text(md_text, encoding='utf-8')


def to_markdown(persona, content: str, exploration: dict) -> str:
    name = str(persona.get('displayName') or persona.get('name') or 'Persona')
    desc = str(persona.get('description') or '')
    lines = []
    lines.append(f'# {name}')
    lines.append('')
    lines.append('## Overview')
    lines.append(f"- **Description**: {desc if desc else '—'}")
    lines.append(f"- **Config File**: `{persona.get('configPath')}`")
    lines.append('')
    lines.append('## System Prompt')
    lines.append(normalize(content))
    lines.append('')
    lines.append('## Exploration Prompts')
    if exploration:
        for k, v in exploration.items():
            lines.append(f"- **{k}**: {v}")
    else:
        lines.append('—')
    return '\n'.join(lines).strip() + '\n'


def normalize(text: str) -> str:
    # STRICT: Only convert literal "\\n" sequences to real newlines. No trimming/reflow.
    return text.replace('\\n', '\n')


if __name__ == '__main__':
    main()
```

### 2. Input Processing (Minimal)

- Read `assets/config/personas_config.json` and iterate personas (Ari, Sergeant Oracle)
- For each persona, open `configPath` JSON and extract:
  - `system_prompt.content` (required)
  - `exploration_prompts` (optional)
- No external index or comparison needed

### 3. Output Generation (Minimal)

#### Markdown Template
```
# [Display Name]

## Overview
- **Description**: …
- **Config File**: `path.json`

## System Prompt
[normalized content]

## Exploration Prompts
- **physical**: …
- **mental**: …
```

#### File Organization
- All files go to `docs/prompts/`
- File name mirrors config name, e.g. `ari_life_coach_config_2.0.md`

### 4. Content Formatting (Minimal)

- Convert escaped newlines (`\\n`) to real newlines
- Preserve existing Markdown headings, list markers, punctuation, casing, and spacing exactly as provided
- Do not reflow, re-wrap, or auto-correct any text
- Do not trim or collapse whitespace inside lines; only insert real newlines when converting `\\n`

### 5. Content Integrity Policy (STRICT)

- **No word changes**: The generator must not rewrite, translate, or edit content
- **No punctuation or casing changes**: All punctuation, symbols, and capitalization remain intact
- **No structure changes**: Headings and list markers are preserved verbatim
- **Only permitted transformation**: Replace literal `\\n` sequences with real newlines (`\n`)
- **Ordering preserved**: Content order must remain exactly the same as in the source
- **Oracle/persona composition is out of scope**: The script only documents the persona JSON as-is

## Implementation Plan

### Implementation Steps (One pass)
1. Add `scripts/generate_prompt_docs.py` with the minimal functions above
2. Read personas from `assets/config/personas_config.json`
3. For each persona, load config, normalize content, write Markdown to `docs/prompts/`
4. Add a short README in `docs/prompts/` explaining how files are generated (optional)
5. Add a convenience command in `README.md` (optional)

## Script Interface

### Command Line Usage
```bash
# Generate docs for all personas (default output to docs/prompts)
python scripts/generate_prompt_docs.py

# Generate only for one persona
python scripts/generate_prompt_docs.py --persona ari

# Custom output directory
python scripts/generate_prompt_docs.py --out docs/prompts/
```

### Configuration Options
```json
{
  "promptDocGenerator": {
    "outputDirectory": "docs/prompts/",
    "maxLineLength": 80
  }
}
```

## Example Transformations

### Before: JSON Configuration
```json
{
  "system_prompt": {
    "role": "system",
    "content": "Você é um Life Management Coach especializado em mudança comportamental baseada em evidências científicas.\n\n## FUNDAMENTOS TEÓRICOS\n\n### 1. TINY HABITS (BJ Fogg)\n- **Princípio**: Mudanças sustentáveis começam pequenas\n- **Aplicação**: Sempre quebre objetivos grandes em micro-hábitos\n- **Fórmula**: B = MAP (Behavior = Motivation + Ability + Prompt)\n- **Celebração**: Reconheça cada pequena vitória imediatamente"
  },
  "exploration_prompts": {
    "physical": "Energy patterns?",
    "mental": "Mental clarity when?"
  }
}
```

### After: Generated Markdown
```markdown
# Ari - Life Coach Configuration

## Overview
- **Display Name**: Ari - Life Coach
- **Description**: TARS-inspired life coach combining 9 expert frameworks
- **Config File**: `assets/config/ari_life_coach_config_2.0.json`
- **Last Updated**: 2025-01-27 15:30:00

## System Prompt

### Role
You are a Life Management Coach specialized in evidence-based behavioral change.

### Theoretical Foundations

#### 1. TINY HABITS (BJ Fogg)
- **Principle**: Sustainable changes start small
- **Application**: Always break down big goals into micro-habits
- **Formula**: B = MAP (Behavior = Motivation + Ability + Prompt)
- **Celebration**: Recognize each small victory immediately

## Exploration Prompts

| Dimension | Prompt |
|-----------|--------|
| Physical | Energy patterns? |
| Mental | Mental clarity when? |
| Relationships | Which relationship needs attention? |
| Work | What energizes you most? |
| Spirituality | What gives meaning now? |

## Configuration Details
- **File Format**: JSON
- **Version**: 2.0
- **Dependencies**: Oracle Knowledge Base (`oracle_prompt_1.0.md`)
- **Integration**: Uses persona overlay system with Oracle base
```

## Benefits & Value

### For Developers
- **Easier Maintenance**: Edit prompts in readable format
- **Better Code Reviews**: Clear diff visualization
- **Faster Onboarding**: New developers can understand personas quickly
- **Documentation Sync**: Always up-to-date prompt documentation

### For Product Team
- **Content Review**: Easier to review and approve prompt changes
- **Version Tracking**: Clear visibility into prompt evolution
- **Quality Control**: Better oversight of AI persona behavior
- **Collaboration**: Non-technical team members can contribute

### For Users (Indirect)
- **Better AI Quality**: More maintainable prompts lead to better AI responses
- **Consistent Experience**: Well-documented personas ensure consistent behavior
- **Faster Improvements**: Easier prompt iteration and testing

## Success Criteria

### Functional Requirements
- ✅ Discover personas from `personas_config.json`
- ✅ Extract `system_prompt.content` and `exploration_prompts`
- ✅ Normalize newlines and write Markdown files

### Quality Requirements
- ✅ Output is readable and minimally formatted
- ✅ File naming mirrors source config for easy diffing

### Technical Requirements
- ✅ No external dependencies beyond Dart SDK
- ✅ Completes in a few seconds for current personas

## Testing Strategy

### Unit Tests (very focused, simple, no mocks)
- Parses `system_prompt.content` correctly (with `\n` → newlines)
- Writes expected Markdown file name from config path
- Handles missing `exploration_prompts` gracefully

### Integration Test
- End-to-end: run script against current repo and assert files exist and contain key headings

## Risk Assessment

### Technical Risks
- **Complex JSON Parsing**: Nested structures and special characters
  - *Mitigation*: Robust parsing with comprehensive error handling
- **Markdown Formatting**: Preserving original formatting intent
  - *Mitigation*: Intelligent formatting rules and manual review

### Maintenance Risks
- **Configuration Changes**: Script breaks when config format changes
  - *Mitigation*: Flexible parsing and version detection
- **Documentation Drift**: Generated docs become outdated
  - *Mitigation*: Automated generation in CI/CD pipeline

## Future Enhancements

### Advanced Features
- **Interactive Documentation**: Generate interactive web documentation
- **Visual Persona Maps**: Diagram showing persona relationships
- **Prompt Analytics**: Usage statistics and effectiveness metrics
- **AI-Powered Summaries**: Auto-generate persona summaries

### Integration Possibilities
- **Documentation Website**: Integration with documentation platform
- **IDE Extensions**: Real-time prompt preview in development environment
- **Collaboration Tools**: Integration with content management systems
- **Version Control**: Advanced diff visualization for prompt changes

## Dependencies

### Internal
- `dart:io` for file operations
- `dart:convert` for JSON parsing
- Existing persona configuration files

### External
- No new external dependencies required
- Uses standard Dart libraries only

## Acceptance Criteria

1. **Script Functionality**
   - [ ] Discovers personas and generates one Markdown per config
   - [ ] System prompt text is normalized and readable
   - [ ] Optional exploration prompts included when present

2. **Developer Experience**
   - [ ] Single command runs end-to-end
   - [ ] Output path configurable via `--out`

3. **Maintenance**
   - [ ] Works with only Ari and Sergeant Oracle personas
   - [ ] Clear error if a `configPath` is missing or invalid

---

**Next Steps**: Implement Phase 1 - Core script development with JSON parsing and basic Markdown generation capabilities.
