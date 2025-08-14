# Prompt Documentation

This directory contains auto-generated documentation for AI persona configurations used in the chat application.

## Overview

These Markdown files are automatically generated from JSON configuration files to provide human-readable documentation of the prompts and settings for each AI persona.

## Generated Files

- `ari_life_coach_config_2.0.md` - Documentation for Ari Life Coach persona (v2.0)
- `sergeant_oracle_config.md` - Documentation for Sergeant Oracle persona

## Generation Process

The documentation is generated using the `scripts/generate_prompt_docs.py` script, which:

1. Reads persona configurations from `assets/config/personas_config.json`
2. Loads each persona's JSON configuration file
3. Extracts the system prompt content and exploration prompts
4. Converts to readable Markdown format with **strict content preservation**

### Content Integrity

**IMPORTANT**: The generated documentation preserves the original prompt content exactly as written in the JSON files:

- No word changes or rewording
- No punctuation or capitalization modifications  
- No structural changes to headings or lists
- Only transformation: Converting literal `\n` sequences to real newlines
- Content order remains identical to source

## Usage

### Generate all persona documentation:
```bash
python3 scripts/generate_prompt_docs.py
```

### Generate documentation for specific persona:
```bash
python3 scripts/generate_prompt_docs.py --persona ariLifeCoach
python3 scripts/generate_prompt_docs.py --persona sergeantOracle
```

### Custom output directory:
```bash
python3 scripts/generate_prompt_docs.py --out custom/path/
```

## File Structure

Each generated file follows this template:

```markdown
# [Persona Display Name]

## Overview
- **Description**: [persona description]
- **Config File**: `[path to JSON config]`

## System Prompt
[exact content from system_prompt.content with newlines normalized]

## Exploration Prompts
- **physical**: [prompt text]
- **mental**: [prompt text]
- **relationships**: [prompt text]
- **work**: [prompt text]
- **spirituality**: [prompt text]
```

## Maintenance

These files are auto-generated and should not be manually edited. To update the documentation:

1. Modify the source JSON configuration files
2. Re-run the generation script
3. Commit both the JSON changes and the updated documentation

## Source Files

The documentation is generated from these source configurations:

- `assets/config/personas_config.json` - Main persona registry
- `assets/config/ari_life_coach_config_2.0.json` - Ari Life Coach configuration
- `assets/config/sergeant_oracle_config.json` - Sergeant Oracle configuration

---

*This README and all documentation files are automatically generated. Last updated when the script was run.*
