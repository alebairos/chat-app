#!/usr/bin/env python3
"""
Oracle Preprocessing Script for FT-062

Parses Oracle markdown files and generates structured JSON templates
for reliable activity detection in the Flutter chat app.

Usage:
    python3 scripts/preprocess_oracle.py assets/config/oracle/oracle_prompt_2.1.md
    python3 scripts/preprocess_oracle.py --all
    python3 scripts/preprocess_oracle.py --validate
"""

import re
import json
import sys
import os
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from datetime import datetime, timezone


class OraclePreprocessor:
    """Preprocesses Oracle markdown files into structured JSON"""
    
    def __init__(self):
        self.dimensions = {}
        self.activities = {}
        self.trilha_activities = set()
        self.errors = []
        self.warnings = []
    
    def parse_oracle_file(self, file_path: str) -> Dict:
        """Parse Oracle markdown file and return structured data"""
        print(f"🔍 Parsing Oracle file: {file_path}")
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            self.errors.append(f"Failed to read file {file_path}: {e}")
            return self._create_empty_result(file_path)
        
        # Parse dimensions from dimension headers
        self._parse_dimensions(content)
        
        # Parse activities from BIBLIOTECA section
        self._parse_biblioteca_activities(content)
        
        # Parse additional activities from trilhas
        self._parse_trilha_activities(content)
        
        # Create structured result
        result = self._create_result(file_path)
        
        # Log parsing summary
        self._log_summary()
        
        return result
    
    def _parse_dimensions(self, content: str):
        """Parse dimension definitions from Oracle content"""
        print("📊 Parsing dimensions...")
        
        # Pattern for dimension headers in biblioteca section
        dimension_patterns = [
            (r'####\s*RELACIONAMENTOS\s*\(R\)', 'R', 'RELACIONAMENTOS', 'Relacionamentos'),
            (r'####\s*SAÚDE FÍSICA\s*\(SF\)', 'SF', 'SAÚDE FÍSICA', 'Saúde Física'),
            (r'####\s*TRABALHO GRATIFICANTE\s*\(TG\)', 'TG', 'TRABALHO GRATIFICANTE', 'Trabalho Gratificante'),
            (r'####\s*ESPIRITUALIDADE\s*\(E\)', 'E', 'ESPIRITUALIDADE', 'Espiritualidade'),
            (r'####\s*SAÚDE MENTAL\s*\(SM\)', 'SM', 'SAÚDE MENTAL', 'Saúde Mental'),
        ]
        
        for pattern, code, full_name, display_name in dimension_patterns:
            if re.search(pattern, content, re.IGNORECASE):
                self.dimensions[code] = {
                    'code': code,
                    'name': full_name,
                    'display_name': display_name,
                    'id': code.lower()
                }
                print(f"✓ Found dimension: {code} - {display_name}")
        
        print(f"📊 Total dimensions found: {len(self.dimensions)}")
    
    def _parse_biblioteca_activities(self, content: str):
        """Parse activities from BIBLIOTECA DE HÁBITOS section"""
        print("📚 Parsing biblioteca activities...")
        
        # Find the biblioteca section
        biblioteca_match = re.search(r'### BIBLIOTECA DE HÁBITOS POR DIMENSÃO(.*?)(?=\n### |\n## |\Z)', 
                                   content, re.DOTALL | re.IGNORECASE)
        
        if not biblioteca_match:
            self.warnings.append("BIBLIOTECA section not found")
            return
        
        biblioteca_content = biblioteca_match.group(1)
        
        # Pattern for activity lines: - **CODE**: Description [scores]
        activity_pattern = r'-\s*\*\*([A-Z]+\d+)\*\*:\s*([^[]+)\s*\[([^\]]+)\]'
        
        activities = re.findall(activity_pattern, biblioteca_content)
        
        for code, name, scores in activities:
            # Clean up name
            name = name.strip()
            
            # Determine dimension from code prefix
            dimension_code = re.match(r'^([A-Z]+)', code).group(1)
            
            # Handle TG dimension (T -> TG mapping)
            if dimension_code == 'T':
                dimension_code = 'TG'
            
            if dimension_code in self.dimensions:
                self.activities[code] = {
                    'code': code,
                    'name': name,
                    'dimension': dimension_code,
                    'scores': self._parse_scores(scores),
                    'source': 'biblioteca'
                }
                print(f"✓ {code}: {name} [{dimension_code}]")
            else:
                self.warnings.append(f"Unknown dimension for activity {code}: {dimension_code}")
        
        print(f"📚 Total biblioteca activities: {len([a for a in self.activities.values() if a['source'] == 'biblioteca'])}")
    
    def _parse_trilha_activities(self, content: str):
        """Parse additional activities referenced in trilhas but not in biblioteca"""
        print("🎯 Parsing trilha activities...")
        
        # Pattern for activity references in trilhas: CODE (frequency) - Description
        trilha_pattern = r'-\s*([A-Z]+\d+)\s*\([^)]+\)\s*-\s*([^-\n]+)'
        
        trilha_activities = re.findall(trilha_pattern, content)
        
        discovered = 0
        for code, description in trilha_activities:
            if code not in self.activities:
                # Determine dimension from code prefix
                dimension_code = re.match(r'^([A-Z]+)', code).group(1)
                
                # Handle TG dimension (T -> TG mapping)
                if dimension_code == 'T':
                    dimension_code = 'TG'
                
                if dimension_code in self.dimensions:
                    self.activities[code] = {
                        'code': code,
                        'name': description.strip(),
                        'dimension': dimension_code,
                        'scores': {'R': 0, 'T': 0, 'SF': 0, 'E': 0, 'SM': 0},  # Default scores
                        'source': 'trilha'
                    }
                    self.trilha_activities.add(code)
                    discovered += 1
                    print(f"✓ Discovered {code}: {description.strip()} [{dimension_code}]")
        
        print(f"🎯 Total trilha activities discovered: {discovered}")
    
    def _parse_scores(self, scores_str: str) -> Dict[str, int]:
        """Parse score string like '5:1:0:0:2' into dimension scores"""
        scores = scores_str.split(':')
        if len(scores) == 5:
            return {
                'R': int(scores[0]),
                'T': int(scores[1]),  # Will be mapped to TG
                'SF': int(scores[2]),
                'E': int(scores[3]),
                'SM': int(scores[4])
            }
        return {'R': 0, 'T': 0, 'SF': 0, 'E': 0, 'SM': 0}
    
    def _create_result(self, file_path: str) -> Dict:
        """Create structured JSON result"""
        return {
            'version': self._extract_version(file_path),
            'source_file': os.path.basename(file_path),
            'generated_at': datetime.now(timezone.utc).isoformat(),
            'dimensions': self.dimensions,
            'activities': self.activities,
            'metadata': {
                'total_activities': len(self.activities),
                'biblioteca_activities': len([a for a in self.activities.values() if a['source'] == 'biblioteca']),
                'trilha_activities': len([a for a in self.activities.values() if a['source'] == 'trilha']),
                'total_dimensions': len(self.dimensions),
                'parsing_status': 'success' if not self.errors else 'error',
                'warnings': len(self.warnings),
                'errors': len(self.errors)
            },
            'warnings': self.warnings,
            'errors': self.errors
        }
    
    def _create_empty_result(self, file_path: str) -> Dict:
        """Create empty result for failed parsing"""
        return {
            'version': self._extract_version(file_path),
            'source_file': os.path.basename(file_path),
            'generated_at': datetime.now(timezone.utc).isoformat(),
            'dimensions': {},
            'activities': {},
            'metadata': {
                'total_activities': 0,
                'biblioteca_activities': 0,
                'trilha_activities': 0,
                'total_dimensions': 0,
                'parsing_status': 'error',
                'warnings': len(self.warnings),
                'errors': len(self.errors)
            },
            'warnings': self.warnings,
            'errors': self.errors
        }
    
    def _extract_version(self, file_path: str) -> str:
        """Extract version from filename"""
        filename = os.path.basename(file_path)
        version_match = re.search(r'(\d+\.\d+)', filename)
        return version_match.group(1) if version_match else 'unknown'
    
    def _log_summary(self):
        """Log parsing summary"""
        print("\n📋 Parsing Summary:")
        print(f"✓ Dimensions: {len(self.dimensions)}")
        print(f"✓ Total Activities: {len(self.activities)}")
        
        biblioteca_count = len([a for a in self.activities.values() if a['source'] == 'biblioteca'])
        trilha_count = len([a for a in self.activities.values() if a['source'] == 'trilha'])
        
        print(f"  - Biblioteca: {biblioteca_count}")
        print(f"  - Trilha: {trilha_count}")
        
        if self.warnings:
            print(f"⚠️  Warnings: {len(self.warnings)}")
            for warning in self.warnings[:5]:  # Show first 5 warnings
                print(f"   - {warning}")
        
        if self.errors:
            print(f"❌ Errors: {len(self.errors)}")
            for error in self.errors:
                print(f"   - {error}")


def process_oracle_file(input_path: str, output_path: str = None) -> bool:
    """Process a single Oracle file"""
    if not os.path.exists(input_path):
        print(f"❌ File not found: {input_path}")
        return False
    
    if output_path is None:
        output_path = input_path.replace('.md', '.json')
    
    processor = OraclePreprocessor()
    result = processor.parse_oracle_file(input_path)
    
    # Write JSON output
    try:
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(result, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Generated JSON: {output_path}")
        
        # Show success summary
        metadata = result['metadata']
        if metadata['parsing_status'] == 'success':
            print(f"🎉 Successfully parsed Oracle {result['version']}: {metadata['total_dimensions']} dimensions, {metadata['total_activities']} total activities")
        else:
            print(f"⚠️  Parsed with issues: {metadata['errors']} errors, {metadata['warnings']} warnings")
        
        return metadata['parsing_status'] == 'success'
        
    except Exception as e:
        print(f"❌ Failed to write JSON: {e}")
        return False


def process_all_oracle_files(oracle_dir: str = "assets/config/oracle/"):
    """Process all Oracle files in directory"""
    print("🔄 Processing all Oracle files...")
    
    oracle_path = Path(oracle_dir)
    if not oracle_path.exists():
        print(f"❌ Oracle directory not found: {oracle_dir}")
        return
    
    oracle_files = list(oracle_path.glob("oracle_prompt_*.md"))
    
    if not oracle_files:
        print(f"❌ No Oracle files found in {oracle_dir}")
        return
    
    success_count = 0
    for oracle_file in oracle_files:
        print(f"\n{'='*60}")
        if process_oracle_file(str(oracle_file)):
            success_count += 1
    
    print(f"\n🎉 Processed {success_count}/{len(oracle_files)} Oracle files successfully")


def validate_json_output(json_path: str):
    """Validate generated JSON output"""
    print(f"🔍 Validating: {json_path}")
    
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Validate structure
        required_keys = ['version', 'source_file', 'dimensions', 'activities', 'metadata']
        missing_keys = [key for key in required_keys if key not in data]
        
        if missing_keys:
            print(f"❌ Missing keys: {missing_keys}")
            return False
        
        # Validate content
        dimensions = data['dimensions']
        activities = data['activities']
        metadata = data['metadata']
        
        print(f"✓ Version: {data['version']}")
        print(f"✓ Dimensions: {len(dimensions)}")
        print(f"✓ Activities: {len(activities)}")
        print(f"✓ Status: {metadata['parsing_status']}")
        
        if metadata['parsing_status'] == 'success':
            print("✅ JSON validation passed")
            return True
        else:
            print(f"⚠️  JSON has parsing issues: {metadata['errors']} errors")
            return False
            
    except Exception as e:
        print(f"❌ JSON validation failed: {e}")
        return False


def train_activity_model(json_file_path, portuguese_only=False):
    """Train activity detection model after Oracle preprocessing"""
    try:
        model_type = "Portuguese-only" if portuguese_only else "Multilingual (Portuguese + English)"
        print(f"\n🤖 Training {model_type} activity detection model for {json_file_path}...")
        
        # Check if training script exists
        train_script = Path("scripts/train_activity_model.py")
        if not train_script.exists():
            print("⚠️  Training script not found, skipping model training")
            return False
        
        # Build command
        cmd = ["python3", str(train_script), json_file_path]
        if portuguese_only:
            cmd.append("--portuguese-only")
        
        # Run training script
        import subprocess
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"✅ {model_type} activity detection model training completed!")
            return True
        else:
            print(f"❌ Model training failed: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Model training error: {e}")
        return False


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python3 scripts/preprocess_oracle.py <oracle_file.md>")
        print("  python3 scripts/preprocess_oracle.py <oracle_file.md> --with-model")
        print("  python3 scripts/preprocess_oracle.py <oracle_file.md> --with-model --pt-only")
        print("  python3 scripts/preprocess_oracle.py --all")
        print("  python3 scripts/preprocess_oracle.py --all --with-model")
        print("  python3 scripts/preprocess_oracle.py --validate <oracle_file.json>")
        sys.exit(1)
    
    # Check for model training flags
    with_model = "--with-model" in sys.argv
    portuguese_only = "--pt-only" in sys.argv
    
    if with_model:
        sys.argv.remove("--with-model")
    if portuguese_only:
        sys.argv.remove("--pt-only")
    
    arg = sys.argv[1]
    
    if arg == "--all":
        success = process_all_oracle_files()
        if success and with_model:
            # Train models for all Oracle versions
            oracle_dir = Path("assets/config/oracle")
            for json_file in oracle_dir.glob("oracle_prompt_*.json"):
                train_activity_model(json_file, portuguese_only)
    elif arg == "--validate":
        if len(sys.argv) < 3:
            print("❌ Please specify JSON file to validate")
            sys.exit(1)
        validate_json_output(sys.argv[2])
    else:
        # Process single file
        input_file = arg
        output_file = sys.argv[2] if len(sys.argv) > 2 else None
        
        success = process_oracle_file(input_file, output_file)
        
        # Train model if requested and preprocessing succeeded
        if success and with_model and output_file:
            train_activity_model(output_file, portuguese_only)
        elif success and with_model:
            # Default output file pattern
            json_file = input_file.replace('.md', '.json')
            if Path(json_file).exists():
                train_activity_model(json_file, portuguese_only)
        
        sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
