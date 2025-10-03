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
        
        # Parse objective codes (OPP1, OGM1, etc.)
        self._parse_objective_codes(content)
        
        # Parse trilha level codes (VG1B, CX1A, etc.)
        self._parse_trilha_level_codes(content)
        
        # Parse trilha sub-level codes (PR1IN, TT1CO, etc.)
        self._parse_trilha_sublevel_codes(content)
        
        # Parse strategy framework codes (MEEDDS, PLOW, GLOWS)
        self._parse_strategy_codes(content)
        
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
            (r'####\s*TRABALHO GRATIFICANTE\s*\(T\)', 'TG', 'TRABALHO GRATIFICANTE', 'Trabalho Gratificante'),
            (r'####\s*ESPIRITUALIDADE\s*\(E\)', 'E', 'ESPIRITUALIDADE', 'Espiritualidade'),
            (r'####\s*SAÚDE MENTAL\s*\(SM\)', 'SM', 'SAÚDE MENTAL', 'Saúde Mental'),
            (r'####\s*TEMPO DE TELA\s*\(TT\)', 'TT', 'TEMPO DE TELA', 'Tempo de Tela'),
            (r'####\s*PROCRASTINAÇÃO\s*\(PR\)', 'PR', 'PROCRASTINAÇÃO', 'Procrastinação'),
            (r'####\s*FINANÇAS\s*\(F\)', 'F', 'FINANÇAS', 'Finanças'),
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
        biblioteca_match = re.search(r'## BIBLIOTECA DE HÁBITOS POR DIMENSÃO(.*?)(?=\n### |\n## |\Z)', 
                                   content, re.DOTALL | re.IGNORECASE)
        
        if not biblioteca_match:
            self.warnings.append("BIBLIOTECA section not found")
            return
        
        biblioteca_content = biblioteca_match.group(1)
        
        # Pattern for activity lines: - **CODE**: Description (without scores in BIBLIOTECA)
        activity_pattern = r'-\s*\*\*([A-Z]+\d+)\*\*:\s*([^\n]+)'
        
        activities = re.findall(activity_pattern, biblioteca_content)
        
        for code, name in activities:
            # Clean up name
            name = name.strip()
            
            # Determine dimension from code prefix
            dimension_code = re.match(r'^([A-Z]+)', code).group(1)
            
            # Handle TG dimension (T -> TG mapping, but preserve TT, PR, F)
            if dimension_code == 'T' and not code.startswith(('TT', 'PR', 'F')):
                dimension_code = 'TG'
            
            if dimension_code in self.dimensions:
                self.activities[code] = {
                    'code': code,
                    'name': name,
                    'dimension': dimension_code,
                    'scores': {'R': 0, 'T': 0, 'SF': 0, 'E': 0, 'SM': 0, 'TT': 0, 'PR': 0, 'F': 0},  # Default scores for BIBLIOTECA
                    'source': 'biblioteca'
                }
                print(f"✓ {code}: {name} [{dimension_code}]")
            else:
                self.warnings.append(f"Unknown dimension for activity {code}: {dimension_code}")
        
        print(f"📚 Total biblioteca activities: {len([a for a in self.activities.values() if a['source'] == 'biblioteca'])}")
    
    def _parse_objective_codes(self, content: str):
        """Parse objective codes like OPP1, OGM1, etc."""
        print("🎯 Parsing objective codes...")
        
        # Pattern for objective codes: - **CODE**: Description → Trilha
        objective_pattern = r'-\s*\*\*([A-Z]+\d+)\*\*:\s*([^→]+)→\s*Trilha\s*([A-Z0-9]+)'
        
        objectives = re.findall(objective_pattern, content)
        
        discovered = 0
        for code, description, trilha_code in objectives:
            if code not in self.activities:
                # Determine dimension from objective code prefix
                dimension_code = self._map_objective_to_dimension(code)
                
                if dimension_code and dimension_code in self.dimensions:
                    self.activities[code] = {
                        'code': code,
                        'name': description.strip(),
                        'dimension': dimension_code,
                        'scores': {'R': 0, 'T': 0, 'SF': 0, 'E': 0, 'SM': 0, 'TT': 0, 'PR': 0, 'F': 0},
                        'source': 'objective',
                        'trilha': trilha_code
                    }
                    discovered += 1
                    print(f"✓ {code}: {description.strip()} [{dimension_code}] → {trilha_code}")
        
        print(f"🎯 Total objective codes discovered: {discovered}")
    
    def _parse_trilha_level_codes(self, content: str):
        """Parse trilha level codes like VG1B, CX1A, etc."""
        print("📋 Parsing trilha level codes...")
        
        # Pattern for trilha level codes: - **CODE** (Nível X): Description
        trilha_level_pattern = r'-\s*\*\*([A-Z0-9]+)\*\*\s*\([^)]*\):\s*([^\n]+)'
        
        trilha_levels = re.findall(trilha_level_pattern, content)
        
        discovered = 0
        for code, description in trilha_levels:
            if code not in self.activities:
                # Determine dimension from trilha code prefix
                dimension_code = self._map_trilha_to_dimension(code)
                
                if dimension_code and dimension_code in self.dimensions:
                    self.activities[code] = {
                        'code': code,
                        'name': description.strip(),
                        'dimension': dimension_code,
                        'scores': {'R': 0, 'T': 0, 'SF': 0, 'E': 0, 'SM': 0, 'TT': 0, 'PR': 0, 'F': 0},
                        'source': 'trilha_level'
                    }
                    discovered += 1
                    print(f"✓ {code}: {description.strip()} [{dimension_code}]")
        
        print(f"📋 Total trilha level codes discovered: {discovered}")
    
    def _parse_trilha_sublevel_codes(self, content: str):
        """Parse trilha sub-level codes like PR1IN, TT1CO, etc."""
        print("🔧 Parsing trilha sub-level codes...")
        
        # Pattern for trilha sub-level codes: - **CODE** (Nível X): Description
        sublevel_pattern = r'-\s*\*\*([A-Z0-9]+)\*\*\s*\([^)]*\):\s*([^\n]+)'
        
        sublevels = re.findall(sublevel_pattern, content)
        
        discovered = 0
        for code, description in sublevels:
            if code not in self.activities and len(code) > 4:  # Sub-level codes are longer
                # Determine dimension from sublevel code prefix
                dimension_code = self._map_sublevel_to_dimension(code)
                
                if dimension_code and dimension_code in self.dimensions:
                    self.activities[code] = {
                        'code': code,
                        'name': description.strip(),
                        'dimension': dimension_code,
                        'scores': {'R': 0, 'T': 0, 'SF': 0, 'E': 0, 'SM': 0, 'TT': 0, 'PR': 0, 'F': 0},
                        'source': 'trilha_sublevel'
                    }
                    discovered += 1
                    print(f"✓ {code}: {description.strip()} [{dimension_code}]")
        
        print(f"🔧 Total trilha sub-level codes discovered: {discovered}")
    
    def _map_sublevel_to_dimension(self, code: str) -> str:
        """Map trilha sub-level codes to dimensions"""
        sublevel_mapping = {
            'TT1CO': 'TT',    # Tempo Tela 1 - Consciência
            'TT2LI': 'TT',    # Tempo Tela 2 - Limites Iniciais
            'TT2INT': 'TT',   # Tempo Tela 2 - Uso Intencional
            'TT3SUB': 'TT',   # Tempo Tela 3 - Substituição Ativa
            'PR1IN': 'PR',    # Procrastinação 1 - Início Imediato
            'PR2FO': 'PR',    # Procrastinação 2 - Foco Estruturado
            'PR2AM': 'PR',    # Procrastinação 2 - Ambiente Otimizado
            'PR3SO': 'PR',    # Procrastinação 3 - Suporte e Organização
            'MenE1B': 'SF',   # Manhã Energética 1 - Básico
            'MenE1I': 'SF',   # Manhã Energética 1 - Intermediário
            'MenE1A': 'SF',   # Manhã Energética 1 - Avançado
        }
        
        if code in sublevel_mapping:
            return sublevel_mapping[code]
        
        # Try prefix matching for patterns we might have missed
        for prefix in ['TT', 'PR', 'MenE', 'SegF']:
            if code.startswith(prefix):
                if prefix == 'TT':
                    return 'TT'
                elif prefix == 'PR':
                    return 'PR'
                elif prefix == 'MenE':
                    return 'SF'
                elif prefix == 'SegF':
                    return 'F'
        
        return None
    
    def _map_objective_to_dimension(self, code: str) -> str:
        """Map objective codes to dimensions"""
        objective_mapping = {
            'OPP': 'SF',    # Perder peso
            'OGM': 'SF',    # Ganhar massa
            'ODM': 'SF',    # Dormir melhor
            'OMMA': 'SF',   # Melhorar alimentação
            'OME': 'SF',    # Manhã energética
            'OLV': 'SF',    # Longevidade
            'OCX': 'SF',    # Correr X Km
            'OAE': 'TG',    # Aprender eficaz
            'OSPM': 'TG',   # Gerenciar tempo/liderar
            'OSF': 'F',     # Segurança financeira
            'ORA': 'SM',    # Reduzir ansiedade
            'OLM': 'TG',    # Ler mais
            'OVG': 'E',     # Virtude gratidão
            'OME2': 'R',    # Melhor esposo(a)
            'OMF': 'R',     # Melhor pai/mãe
            'ODE': 'E',     # Desenvolver espiritualidade
            'OREQ': 'R',    # Relacionamento entes queridos
        }
        
        for prefix, dimension in objective_mapping.items():
            if code.startswith(prefix):
                return dimension
        return None
    
    def _map_trilha_to_dimension(self, code: str) -> str:
        """Map trilha level codes to dimensions"""
        trilha_mapping = {
            'VG1': 'E',     # Virtude gratidão
            'CX1': 'SF',    # Correr X Km
            'SME1': 'R',    # Ser melhor esposo(a)
            'SMP1': 'R',    # Ser melhor pai/mãe
            'EE1': 'E',     # Evolução espiritual
            'EE2': 'E',     # Evolução espiritual avançado
            'MMV1': 'R',    # Minha melhor versão
            'MMV2': 'R',    # Minha melhor versão avançado
            'DTD1': 'SM',   # Detox dopamina
            'DTD2': 'SM',   # Detox dopamina avançado
            'DD1': 'SM',    # Domine dopamina
            'ED1': 'SM',    # Eleve dopamina
            'MenE1': 'SF',  # Manhã energética
            'SegF1': 'F',   # Segurança financeira
            'TempoTela1': 'TT',  # Tempo tela 1
            'TempoTela2': 'TT',  # Tempo tela 2
            'TempoTela3': 'TT',  # Tempo tela 3
            'Procrastinação1': 'PR',  # Procrastinação 1
            'Procrastinação2': 'PR',  # Procrastinação 2
            'Procrastinação3': 'PR',  # Procrastinação 3
        }
        
        for prefix, dimension in trilha_mapping.items():
            if code.startswith(prefix):
                return dimension
        return None
    
    def _parse_strategy_codes(self, content: str):
        """Parse strategy framework codes (MEEDDS, PLOW, GLOWS)"""
        print("🎯 Parsing strategy framework codes...")
        
        # Pattern for strategy codes: **X** (Description): activities
        strategy_pattern = r'\*\*([A-Z])\*\*([^:]+):\s*([^\n]+)'
        
        strategies = re.findall(strategy_pattern, content)
        
        discovered = 0
        for code, description, activities_list in strategies:
            if code not in self.activities and len(code) == 1:  # Single letter strategy codes
                # Determine dimension from strategy code
                dimension_code = self._map_strategy_to_dimension(code, description)
                
                if dimension_code and dimension_code in self.dimensions:
                    self.activities[code] = {
                        'code': code,
                        'name': description.strip().replace('(', '').replace(')', ''),
                        'dimension': dimension_code,
                        'scores': {'R': 0, 'T': 0, 'SF': 0, 'E': 0, 'SM': 0, 'TT': 0, 'PR': 0, 'F': 0},
                        'source': 'strategy',
                        'activities': activities_list.strip()
                    }
                    discovered += 1
                    print(f"✓ {code}: {description.strip()} [{dimension_code}]")
        
        print(f"🎯 Total strategy codes discovered: {discovered}")
    
    def _map_strategy_to_dimension(self, code: str, description: str) -> str:
        """Map strategy codes to dimensions based on context"""
        strategy_mapping = {
            'M': 'SM',  # Meditation -> Saúde Mental
            'E': 'SF',  # Exercise/Eating -> Saúde Física  
            'D': 'SF',  # Digital Detoxing/Deep Sleep -> Saúde Física (sleep) or TT (digital)
            'S': 'SM',  # Stillness -> Saúde Mental
            'P': 'TG',  # Planning -> Trabalho Gratificante
            'L': 'TG',  # Learning -> Trabalho Gratificante
            'O': 'TG',  # Orchestration -> Trabalho Gratificante
            'W': 'TG',  # Work -> Trabalho Gratificante
            'G': 'E',   # Gratitude -> Espiritualidade
        }
        
        # Special handling for context-dependent codes
        if code == 'D':
            if 'Digital' in description:
                return 'TT'  # Digital Detoxing -> Tempo de Tela
            else:
                return 'SF'  # Deep Sleep -> Saúde Física
        
        return strategy_mapping.get(code, 'SM')  # Default to Saúde Mental
    
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
                
                # Handle TG dimension (T -> TG mapping, but preserve TT, PR, F)
                if dimension_code == 'T' and not code.startswith(('TT', 'PR', 'F')):
                    dimension_code = 'TG'
                
                if dimension_code in self.dimensions:
                    self.activities[code] = {
                        'code': code,
                        'name': description.strip(),
                        'dimension': dimension_code,
                        'scores': {'R': 0, 'T': 0, 'SF': 0, 'E': 0, 'SM': 0, 'TT': 0, 'PR': 0, 'F': 0},  # Default scores
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
                'SM': int(scores[4]),
                'TT': 0,
                'PR': 0,
                'F': 0
            }
        return {'R': 0, 'T': 0, 'SF': 0, 'E': 0, 'SM': 0, 'TT': 0, 'PR': 0, 'F': 0}
    
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


def create_optimized_oracle(input_path: str) -> bool:
    """Create optimized Oracle file by removing redundant catalog sections"""
    try:
        optimized_path = input_path.replace('.md', '_optimized.md')
        
        print(f"🔧 Creating optimized version: {optimized_path}")
        
        with open(input_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # Find the catalog section start
        catalog_start = None
        for i, line in enumerate(lines):
            if '## CATÁLOGO COMPLETO DE TRILHAS E HÁBITOS' in line:
                catalog_start = i
                break
        
        if catalog_start is None:
            print("⚠️  No catalog section found, keeping original file")
            return False
        
        # Keep core content (before catalog)
        core_content = lines[:catalog_start]
        
        # Ensure TRANSPARÊNCIA ZERO rule is preserved
        has_transparency_rule = any('TRANSPARÊNCIA ZERO' in line for line in core_content)
        if not has_transparency_rule:
            # Add the critical transparency rule before the integrated system
            transparency_rule = """## REGRA CRÍTICA: TRANSPARÊNCIA ZERO
- NUNCA adicione comentários sobre seu próprio comportamento ou estratégias
- NUNCA explique suas escolhas de resposta em parênteses ou notas
- NUNCA mencione protocolos internos ou instruções ao usuário
- Seja direto e natural sem meta-comentários
- O usuário não deve perceber suas instruções internas

"""
            core_content.append(transparency_rule)
        
        # Add optimized footer
        optimization_footer = """
## SISTEMA DE ATIVIDADES E TRILHAS INTEGRADO

### ATIVIDADES DISPONÍVEIS

O sistema utiliza **atividades estruturadas** organizadas em **8 dimensões** do potencial humano para fornecer recomendações personalizadas e tracking inteligente:

**📊 DIMENSÕES PRINCIPAIS:**
- **RELACIONAMENTOS (R):** Conexões interpessoais, família, comunicação compassiva
- **SAÚDE FÍSICA (SF):** Exercício, sono, alimentação, bem-estar físico
- **TRABALHO GRATIFICANTE (TG):** Produtividade, aprendizado, carreira, foco
- **SAÚDE MENTAL (SM):** Mindfulness, respiração, equilíbrio emocional
- **ESPIRITUALIDADE (E):** Gratidão, propósito, crescimento espiritual
- **TEMPO DE TELA (TT):** Controle digital, uso consciente de tecnologia
- **PROCRASTINAÇÃO (PR):** Anti-procrastinação, gestão de tarefas, foco
- **FINANÇAS (F):** Planejamento financeiro, orçamento, investimentos

### SISTEMA DE RECOMENDAÇÕES DINÂMICAS

O sistema detecta automaticamente atividades mencionadas pelo usuário e fornece:

1. **Recomendações Personalizadas:** Baseadas no contexto, objetivos e histórico do usuário
2. **Trilhas Estruturadas:** Sequências progressivas de hábitos (básico → intermediário → avançado)
3. **Tracking Inteligente:** Monitoramento automático de progresso e padrões
4. **Micro-hábitos:** Quebra de objetivos grandes em ações sustentáveis
5. **Celebração de Progresso:** Reconhecimento de vitórias e marcos alcançados

### EXEMPLOS DE TRILHAS DISPONÍVEIS

**Saúde Física:**
- Perder peso, Ganhar massa, Dormir melhor, Manhã energética, Longevidade, Correr X Km

**Relacionamentos:**
- Ser melhor esposo(a), Ser melhor pai/mãe, Minha melhor versão

**Espiritualidade:**
- Evolução espiritual, Virtudes - gratidão

**Saúde Mental:**
- Anti-ansiedade, Detox dopamina, Mindfulness, Respiração controlada

**Tempo de Tela:**
- Controle tempo de tela, Uso consciente digital, Detox tecnológico

**Procrastinação:**
- Anti-procrastinação, Foco estruturado, Gestão de tarefas

**Trabalho Gratificante:**
- Aprendizado eficiente, Gerencie sua vida, Líder de sucesso

**Finanças:**
- Segurança financeira, Planejamento orçamentário, Educação financeira

### COMO FUNCIONA

1. **Detecção Automática:** O sistema identifica atividades mencionadas nas conversas
2. **Contextualização:** Analisa objetivos, nível de experiência e disponibilidade
3. **Recomendação Inteligente:** Sugere trilhas e hábitos específicos do catálogo
4. **Acompanhamento:** Monitora progresso e ajusta recomendações dinamicamente
5. **Celebração:** Reconhece conquistas e mantém motivação alta

**Todas as atividades específicas, frequências e descrições detalhadas estão disponíveis através do sistema integrado, permitindo recomendações precisas e personalizadas baseadas no framework Oracle.**

---

*Sistema otimizado para máxima eficiência de tokens mantendo 100% da funcionalidade através de dados estruturados.*
"""
        
        # Write optimized file
        with open(optimized_path, 'w', encoding='utf-8') as f:
            f.writelines(core_content)
            f.write(optimization_footer)
        
        # Calculate savings
        original_words = len(' '.join(lines).split())
        optimized_words = len(' '.join(core_content).split()) + len(optimization_footer.split())
        reduction = original_words - optimized_words
        percentage = (reduction / original_words) * 100
        token_savings = int(reduction * 1.33)  # Estimate tokens
        
        print(f"✅ Generated optimized Oracle: {optimized_path}")
        print(f"📊 Token optimization: {reduction} words ({percentage:.1f}%) = ~{token_savings} tokens saved")
        
        # Create corresponding optimized JSON file (copy from original)
        original_json = input_path.replace('.md', '.json')
        optimized_json = optimized_path.replace('.md', '.json')
        
        if os.path.exists(original_json):
            import shutil
            shutil.copy2(original_json, optimized_json)
            print(f"✅ Generated optimized JSON: {optimized_json}")
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to create optimized version: {e}")
        return False


def process_oracle_file(input_path: str, output_path: str = None, create_optimized: bool = False) -> bool:
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
        
        # Create optimized version if requested
        if create_optimized and metadata['parsing_status'] == 'success':
            create_optimized_oracle(input_path)
        
        return metadata['parsing_status'] == 'success'
        
    except Exception as e:
        print(f"❌ Failed to write JSON: {e}")
        return False


def process_all_oracle_files(oracle_dir: str = "assets/config/oracle/", create_optimized: bool = False, goals_mapping: bool = False):
    """Process all Oracle files in directory"""
    print("🔄 Processing all Oracle files...")
    
    oracle_path = Path(oracle_dir)
    if not oracle_path.exists():
        print(f"❌ Oracle directory not found: {oracle_dir}")
        return False
    
    oracle_files = list(oracle_path.glob("oracle_prompt_*.md"))
    # Exclude already optimized files
    oracle_files = [f for f in oracle_files if '_optimized' not in f.name]
    
    if not oracle_files:
        print(f"❌ No Oracle files found in {oracle_dir}")
        return False
    
    success_count = 0
    for oracle_file in oracle_files:
        print(f"\n{'='*60}")
        if process_oracle_file(str(oracle_file), create_optimized=create_optimized):
            success_count += 1
            
            # Generate goals mapping if requested
            if goals_mapping:
                json_file = str(oracle_file).replace('.md', '.json')
                if Path(json_file).exists():
                    print(f"\n🎯 Generating goals mapping for {json_file}...")
                    generate_goals_mapping(json_file)
    
    print(f"\n🎉 Processed {success_count}/{len(oracle_files)} Oracle files successfully")
    return success_count > 0


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


def generate_goals_mapping(oracle_json_path: str, output_path: str = None) -> bool:
    """Generate goals mapping JSON from Oracle JSON"""
    print(f"🎯 Generating goals mapping from: {oracle_json_path}")
    
    try:
        # Load Oracle JSON
        with open(oracle_json_path, 'r', encoding='utf-8') as f:
            oracle_data = json.load(f)
        
        # Extract goal-trilha relationships
        goal_trilha_data = extract_goal_trilha_relationships(oracle_data)
        
        # Build activity-goal mapping
        activity_goal_data = build_activity_goal_mapping(goal_trilha_data, oracle_data)
        
        # Build goal categories
        goal_categories = build_goal_categories(goal_trilha_data, oracle_data['dimensions'])
        
        # Build trilha hierarchy
        trilha_hierarchy = build_trilha_hierarchy(oracle_data)
        
        # Validate mapping
        validation_report = validate_goals_mapping(goal_trilha_data, activity_goal_data, oracle_data)
        
        # Create output structure
        goals_mapping = {
            'version': oracle_data.get('version', 'unknown'),
            'source_file': os.path.basename(oracle_json_path),
            'generated_at': datetime.now(timezone.utc).isoformat(),
            'metadata': {
                'total_goals': len(goal_trilha_data),
                'total_mapped_activities': len(activity_goal_data),
                'coverage_percentage': calculate_coverage_percentage(activity_goal_data, oracle_data),
                'generation_status': 'success' if not validation_report['errors'] else 'warning'
            },
            'goal_trilha_mapping': goal_trilha_data,
            'activity_goal_mapping': activity_goal_data,
            'goal_categories': goal_categories,
            'trilha_hierarchy': trilha_hierarchy,
            'validation_report': validation_report
        }
        
        # Determine output path
        if output_path is None:
            output_path = oracle_json_path.replace('.json', '_goals_mapping.json')
            # Handle optimized files
            output_path = output_path.replace('_optimized_goals_mapping.json', '_goals_mapping.json')
        
        # Write goals mapping JSON
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(goals_mapping, f, indent=2, ensure_ascii=False)
        
        # Print success summary
        metadata = goals_mapping['metadata']
        print(f"✅ Generated goals mapping: {output_path}")
        print(f"📊 Mapped {metadata['total_goals']} goals to {metadata['total_mapped_activities']} activities")
        print(f"🎯 Coverage: {metadata['coverage_percentage']:.1f}% of Oracle activities mapped to goals")
        print(f"⚡ Optimized for FT-175 goal-aware detection")
        
        if validation_report['warnings']:
            print(f"⚠️  {len(validation_report['warnings'])} warnings (see validation_report in JSON)")
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to generate goals mapping: {e}")
        return False


def extract_goal_trilha_relationships(oracle_data: Dict) -> Dict:
    """Extract goal-trilha-activity relationships from Oracle data"""
    print("🔍 Extracting goal-trilha relationships...")
    
    goal_trilha_mapping = {}
    activities = oracle_data.get('activities', {})
    
    # Find all objectives (codes starting with 'O')
    objectives = {code: activity for code, activity in activities.items() 
                  if activity.get('source') == 'objective' and code.startswith('O')}
    
    print(f"📊 Found {len(objectives)} objectives")
    
    for obj_code, obj_data in objectives.items():
        trilha = obj_data.get('trilha')
        if not trilha:
            continue
            
        # Find related activities based on trilha and dimension
        related_activities = find_related_activities(trilha, obj_data.get('dimension'), activities)
        
        # Find trilha levels (Basic, Intermediate, Advanced)
        trilha_levels = find_trilha_levels(trilha, activities)
        
        goal_trilha_mapping[obj_code] = {
            'objective_code': obj_code,
            'objective_name': obj_data.get('name', ''),
            'trilha': trilha,
            'dimension': obj_data.get('dimension', ''),
            'related_activities': related_activities,
            'trilha_levels': trilha_levels
        }
        
        print(f"✓ {obj_code}: {obj_data.get('name')} → {trilha} → {len(related_activities)} activities")
    
    print(f"🎯 Extracted {len(goal_trilha_mapping)} goal-trilha mappings")
    return goal_trilha_mapping


def find_related_activities(trilha: str, dimension: str, activities: Dict) -> List[str]:
    """Find activities related to a trilha and dimension"""
    related = []
    
    for code, activity in activities.items():
        # Skip objectives and trilha levels themselves
        if activity.get('source') in ['objective', 'trilha_level']:
            continue
            
        # Match by dimension and activity patterns
        if activity.get('dimension') == dimension:
            # Add core dimension activities
            if activity.get('source') == 'biblioteca':
                related.append(code)
        
        # Add trilha-specific activities
        if trilha in code or code.startswith(trilha):
            related.append(code)
    
    return sorted(list(set(related)))


def find_trilha_levels(trilha: str, activities: Dict) -> List[str]:
    """Find trilha level codes (Basic, Intermediate, Advanced)"""
    levels = []
    
    for code, activity in activities.items():
        if activity.get('source') == 'trilha_level' and code.startswith(trilha):
            levels.append(code)
    
    return sorted(levels)


def build_activity_goal_mapping(goal_trilha_data: Dict, oracle_data: Dict) -> Dict:
    """Build reverse mapping from activities to goals"""
    print("🔄 Building activity→goals mapping...")
    
    activity_goal_mapping = {}
    
    for goal_code, goal_info in goal_trilha_data.items():
        for activity_code in goal_info.get('related_activities', []):
            if activity_code not in activity_goal_mapping:
                activity_goal_mapping[activity_code] = []
            activity_goal_mapping[activity_code].append(goal_code)
    
    # Sort goals for each activity
    for activity_code in activity_goal_mapping:
        activity_goal_mapping[activity_code] = sorted(activity_goal_mapping[activity_code])
    
    print(f"🔄 Built reverse mapping for {len(activity_goal_mapping)} activities")
    return activity_goal_mapping


def build_goal_categories(goal_trilha_data: Dict, dimensions: Dict) -> Dict:
    """Build goal categories by dimension"""
    print("📂 Building goal categories...")
    
    goal_categories = {}
    
    for dimension_code, dimension_info in dimensions.items():
        goals_in_dimension = [goal_code for goal_code, goal_info in goal_trilha_data.items() 
                             if goal_info.get('dimension') == dimension_code]
        
        if goals_in_dimension:
            # Get primary activities for this dimension
            primary_activities = set()
            for goal_code in goals_in_dimension:
                primary_activities.update(goal_trilha_data[goal_code].get('related_activities', []))
            
            goal_categories[dimension_code] = {
                'name': dimension_info.get('display_name', dimension_info.get('name', '')),
                'goals': sorted(goals_in_dimension),
                'primary_activities': sorted(list(primary_activities))
            }
    
    print(f"📂 Built {len(goal_categories)} goal categories")
    return goal_categories


def build_trilha_hierarchy(oracle_data: Dict) -> Dict:
    """Build trilha hierarchy with levels"""
    print("📋 Building trilha hierarchy...")
    
    trilha_hierarchy = {}
    activities = oracle_data.get('activities', {})
    
    # Group trilha levels
    for code, activity in activities.items():
        if activity.get('source') == 'trilha_level':
            # Extract base trilha from level code (e.g., CX1B → CX1)
            base_trilha = code.rstrip('BIA')  # Remove Basic/Intermediate/Advanced suffixes
            
            if base_trilha not in trilha_hierarchy:
                trilha_hierarchy[base_trilha] = {
                    'basic': [],
                    'intermediate': [],
                    'advanced': []
                }
            
            if code.endswith('B'):
                trilha_hierarchy[base_trilha]['basic'].append(code)
            elif code.endswith('I'):
                trilha_hierarchy[base_trilha]['intermediate'].append(code)
            elif code.endswith('A'):
                trilha_hierarchy[base_trilha]['advanced'].append(code)
    
    print(f"📋 Built hierarchy for {len(trilha_hierarchy)} trilhas")
    return trilha_hierarchy


def calculate_coverage_percentage(activity_goal_data: Dict, oracle_data: Dict) -> float:
    """Calculate percentage of Oracle activities mapped to goals"""
    total_biblioteca_activities = len([a for a in oracle_data.get('activities', {}).values() 
                                      if a.get('source') == 'biblioteca'])
    mapped_activities = len(activity_goal_data)
    
    if total_biblioteca_activities == 0:
        return 0.0
    
    return (mapped_activities / total_biblioteca_activities) * 100


def validate_goals_mapping(goal_trilha_data: Dict, activity_goal_data: Dict, oracle_data: Dict) -> Dict:
    """Validate goals mapping completeness and consistency"""
    print("✅ Validating goals mapping...")
    
    warnings = []
    errors = []
    
    # Check for orphaned trilhas
    referenced_trilhas = set(goal['trilha'] for goal in goal_trilha_data.values() if goal.get('trilha'))
    for trilha in referenced_trilhas:
        if not any(code.startswith(trilha) for code in oracle_data.get('activities', {})):
            warnings.append(f"Trilha '{trilha}' referenced but no matching activities found")
    
    # Check bidirectional consistency
    for activity_code, goal_codes in activity_goal_data.items():
        for goal_code in goal_codes:
            if goal_code in goal_trilha_data:
                if activity_code not in goal_trilha_data[goal_code].get('related_activities', []):
                    errors.append(f"Bidirectional inconsistency: {activity_code} → {goal_code} missing reverse mapping")
    
    # Check for goals without activities
    for goal_code, goal_info in goal_trilha_data.items():
        if not goal_info.get('related_activities'):
            warnings.append(f"Goal '{goal_code}' has no related activities")
    
    print(f"✅ Validation complete: {len(errors)} errors, {len(warnings)} warnings")
    
    return {
        'errors': errors,
        'warnings': warnings,
        'validated_at': datetime.now(timezone.utc).isoformat()
    }


def validate_goals_mapping_file(json_path: str) -> bool:
    """Validate generated goals mapping JSON file"""
    print(f"🔍 Validating goals mapping: {json_path}")
    
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Validate structure
        required_keys = ['version', 'source_file', 'goal_trilha_mapping', 'activity_goal_mapping', 'metadata']
        missing_keys = [key for key in required_keys if key not in data]
        
        if missing_keys:
            print(f"❌ Missing keys: {missing_keys}")
            return False
        
        # Validate content
        goal_mapping = data['goal_trilha_mapping']
        activity_mapping = data['activity_goal_mapping']
        metadata = data['metadata']
        
        print(f"✓ Version: {data['version']}")
        print(f"✓ Goals: {len(goal_mapping)}")
        print(f"✓ Mapped Activities: {len(activity_mapping)}")
        print(f"✓ Coverage: {metadata.get('coverage_percentage', 0):.1f}%")
        print(f"✓ Status: {metadata['generation_status']}")
        
        # Check validation report
        validation_report = data.get('validation_report', {})
        errors = validation_report.get('errors', [])
        warnings = validation_report.get('warnings', [])
        
        if errors:
            print(f"❌ Validation errors: {len(errors)}")
            for error in errors[:3]:  # Show first 3 errors
                print(f"   - {error}")
            return False
        
        if warnings:
            print(f"⚠️  Validation warnings: {len(warnings)}")
            for warning in warnings[:3]:  # Show first 3 warnings
                print(f"   - {warning}")
        
        if metadata['generation_status'] == 'success':
            print("✅ Goals mapping validation passed")
            return True
        else:
            print(f"⚠️  Goals mapping has issues: {metadata['generation_status']}")
            return False
            
    except Exception as e:
        print(f"❌ Goals mapping validation failed: {e}")
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
        print("  python3 scripts/preprocess_oracle.py <oracle_file.md> --optimize")
        print("  python3 scripts/preprocess_oracle.py --goals-mapping <oracle_file.json>")
        print("  python3 scripts/preprocess_oracle.py --all")
        print("  python3 scripts/preprocess_oracle.py --all --with-model")
        print("  python3 scripts/preprocess_oracle.py --all --optimize")
        print("  python3 scripts/preprocess_oracle.py --all --goals-mapping")
        print("  python3 scripts/preprocess_oracle.py --validate <oracle_file.json>")
        sys.exit(1)
    
    # Check for flags first
    with_model = "--with-model" in sys.argv
    portuguese_only = "--pt-only" in sys.argv
    create_optimized = "--optimize" in sys.argv
    goals_mapping_flag = "--goals-mapping" in sys.argv
    
    # Handle goals mapping as primary command (not just a flag)
    if goals_mapping_flag and len(sys.argv) >= 3:
        json_file_path = None
        for i, arg in enumerate(sys.argv):
            if arg == "--goals-mapping" and i + 1 < len(sys.argv):
                json_file_path = sys.argv[i + 1]
                break
        
        if json_file_path:
            success = generate_goals_mapping(json_file_path)
            sys.exit(0 if success else 1)
        else:
            print("❌ Please specify Oracle JSON file for goals mapping")
            sys.exit(1)
    
    # Remove flags from argv for normal processing
    if with_model:
        sys.argv.remove("--with-model")
    if portuguese_only:
        sys.argv.remove("--pt-only")
    if create_optimized:
        sys.argv.remove("--optimize")
    if goals_mapping_flag:
        sys.argv.remove("--goals-mapping")
    
    arg = sys.argv[1]
    
    if arg == "--all":
        success = process_all_oracle_files(create_optimized=create_optimized, goals_mapping=goals_mapping_flag)
        if success and with_model:
            # Train models for all Oracle versions
            oracle_dir = Path("assets/config/oracle")
            for json_file in oracle_dir.glob("oracle_prompt_*.json"):
                train_activity_model(json_file, portuguese_only)
    elif arg == "--goals-mapping":
        if len(sys.argv) < 3:
            print("❌ Please specify Oracle JSON file for goals mapping")
            sys.exit(1)
        success = generate_goals_mapping(sys.argv[2])
        sys.exit(0 if success else 1)
    elif arg == "--validate":
        if len(sys.argv) < 3:
            print("❌ Please specify JSON file to validate")
            sys.exit(1)
        
        json_file = sys.argv[2]
        if 'goals_mapping' in json_file:
            success = validate_goals_mapping_file(json_file)
        else:
            success = validate_json_output(json_file)
        sys.exit(0 if success else 1)
    else:
        # Process single file
        input_file = arg
        output_file = sys.argv[2] if len(sys.argv) > 2 else None
        
        success = process_oracle_file(input_file, output_file, create_optimized=create_optimized)
        
        # Generate goals mapping if requested and processing succeeded
        if success and goals_mapping_flag:
            json_file = input_file.replace('.md', '.json')
            if Path(json_file).exists():
                generate_goals_mapping(json_file)
        
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
