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
    for key, persona_data in personas.items():
        if persona_filter and key != persona_filter:
            continue
        # Add the key to the persona data for reference
        persona_data['key'] = key
        generate_persona_doc(persona_data, out_dir)


def load_personas_config():
    cfg_path = Path('assets/config/personas_config.json')
    data = json.loads(cfg_path.read_text(encoding='utf-8'))
    return data.get('personas', {})


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
