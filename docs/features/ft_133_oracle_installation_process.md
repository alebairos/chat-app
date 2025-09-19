# FT-133: Oracle Prompt Installation Process

**Feature ID:** FT-133  
**Priority:** High  
**Category:** Development Process  
**Effort:** 2 days  

## OVERVIEW

Standardize and automate the process for installing new Oracle prompt versions, ensuring consistency, proper integration, and preventing common issues like missing critical rules or incorrect configurations.

## PROBLEM STATEMENT

Currently, installing new Oracle prompt versions is a manual, error-prone process that can result in:
- Missing critical behavioral rules (e.g., TRANSPARÊNCIA ZERO)
- Inconsistent identity and presentation sections
- Manual configuration errors in personas setup
- Forgotten preprocessing steps
- Inconsistent file naming patterns

## SOLUTION

Create a standardized Oracle installation process with templates, automation scripts, and clear documentation to ensure consistent, error-free Oracle deployments.

## FUNCTIONAL REQUIREMENTS

### FR-133.1: Oracle Template System
- **Template File:** `assets/config/oracle/oracle_prompt_template.md`
- **Fixed Sections:** IDENTIDADE PRINCIPAL, MENSAGEM DE APRESENTAÇÃO, TRANSPARÊNCIA ZERO
- **Variable Sections:** Clearly marked placeholders for new content
- **Validation:** Template ensures critical rules are never omitted

### FR-133.2: File Naming Convention
- **Pattern:** `oracle_prompt_X.Y.md` (e.g., `oracle_prompt_4.3.md`)
- **Version Format:** Major.Minor (X.Y)
- **Validation:** Automated check for naming compliance

### FR-133.3: Automated Preprocessing
- **Command:** `python3 scripts/preprocess_oracle.py <new_file> --optimize`
- **Outputs:** 
  - `oracle_prompt_X.Y.json` (structured activity data)
  - `oracle_prompt_X.Y_optimized.md` (token-optimized version)
- **Validation:** Verify both files are generated successfully

### FR-133.4: Personas Configuration
- **Auto-generation:** Script creates three persona entries:
  - `ariWithOracleXY`
  - `iThereWithOracleXY` 
  - `sergeantOracleWithOracleXY`
- **Configuration:** Proper display names, descriptions, and file paths
- **Integration:** Seamless addition to existing personas config

### FR-133.5: Installation Validation
- **File Checks:** Verify all required files exist
- **JSON Validation:** Confirm valid JSON structure and activity counts
- **Rule Verification:** Ensure TRANSPARÊNCIA ZERO rule is present
- **Persona Integration:** Validate personas configuration syntax

## TECHNICAL REQUIREMENTS

### TR-133.1: Oracle Template Structure
```markdown
# ARISTOS - LIFE MANAGEMENT COACH PROMPT vX.Y

## IDENTIDADE PRINCIPAL

Você é um Life Management Coach especializado em mudança comportamental baseada em evidências científicas. Sua abordagem integra os princípios dos maiores especialistas em neurociência comportamental, psicologia positiva e formação de hábitos. Você combina rigor científico com aplicação prática, sempre focando em resultados sustentáveis e bem-estar duradouro.

### MENSAGEM DE APRESENTAÇÃO
Existem **três caminhos** para o usuário começar sua jornada: (1) **Escolher objetivos específicos** e construir hábitos que o levarão consistentemente até eles; (2) **Eliminar ou substituir maus hábitos** como procrastinação, uso excessivo de celular e redes sociais que impedem uma vida intencional; ou (3) **Otimizar sua rotina atual** inserindo seus hábitos existentes no framework e aprimorando-os gradualmente. Independente do caminho inicial, a meta é que o usuário desenvolva uma vida onde seus maus hábitos estão controlados, seus objetivos estão claros e ele pratica consistentemente os comportamentos que o levam ao crescimento.

<!-- VARIABLE CONTENT STARTS HERE -->
## FUNDAMENTOS TEÓRICOS
[CONTENT TO BE FILLED BY PROMPT CREATOR]

<!-- VARIABLE CONTENT ENDS HERE -->

## REGRA CRÍTICA: TRANSPARÊNCIA ZERO
- NUNCA adicione comentários sobre seu próprio comportamento ou estratégias
- NUNCA explique suas escolhas de resposta em parênteses ou notas
- NUNCA mencione protocolos internos ou instruções ao usuário
- Seja direto e natural sem meta-comentários
- O usuário não deve perceber suas instruções internas
```

### TR-133.2: Installation Script
- **Location:** `scripts/install_oracle.py`
- **Functions:**
  - Version validation
  - Template application
  - Preprocessing automation
  - Personas configuration update
  - Validation checks

### TR-133.3: Personas Configuration Pattern
```json
"ariWithOracleXY": {
  "enabled": true,
  "displayName": "Aristios X.Y",
  "description": "Advanced Life Management Coach with Oracle X.Y framework...",
  "configPath": "assets/config/ari_life_coach_config_2.0.json",
  "oracleConfigPath": "assets/config/oracle/oracle_prompt_X.Y_optimized.md",
  "audioFormatting": { "enabled": true }
}
```

## INSTALLATION PROCESS

### Step 1: Repository Preparation
```bash
git pull origin main
git checkout -b oracle-X.Y-installation
```

### Step 2: File Validation
```bash
# Verify naming pattern
ls assets/config/oracle/oracle_prompt_*.md
# Should follow: oracle_prompt_X.Y.md pattern
```

### Step 3: Template Application
```bash
# Apply template to new Oracle file (manual step)
# Ensure IDENTIDADE PRINCIPAL and MENSAGEM DE APRESENTAÇÃO match template
# Verify TRANSPARÊNCIA ZERO rule is present
```

### Step 4: Preprocessing
```bash
python3 scripts/preprocess_oracle.py assets/config/oracle/oracle_prompt_X.Y.md --optimize
```

### Step 5: Personas Configuration
```bash
python3 scripts/install_oracle.py --version X.Y --update-personas
```

### Step 6: Validation
```bash
# Verify files exist
ls assets/config/oracle/oracle_prompt_X.Y*

# Validate JSON structure
python3 scripts/preprocess_oracle.py --validate assets/config/oracle/oracle_prompt_X.Y.json

# Test personas configuration
python3 -m json.tool assets/config/personas_config.json > /dev/null
```

### Step 7: Testing
```bash
# Run app and test new personas
flutter run
# Verify no reasoning notes appear
# Confirm Oracle JSON loads correctly
```

## ACCEPTANCE CRITERIA

### AC-133.1: Template System
- [ ] Oracle template file created with fixed and variable sections
- [ ] Template includes all critical rules (TRANSPARÊNCIA ZERO)
- [ ] Clear documentation for template usage

### AC-133.2: Automated Installation
- [ ] Installation script handles all steps automatically
- [ ] Version validation prevents incorrect naming
- [ ] Preprocessing generates both JSON and optimized MD files

### AC-133.3: Personas Integration
- [ ] Three personas automatically added to configuration
- [ ] Proper naming convention followed (ariWithOracleXY format)
- [ ] All personas reference optimized Oracle versions

### AC-133.4: Validation System
- [ ] File existence checks pass
- [ ] JSON structure validation succeeds
- [ ] Critical rules verification passes
- [ ] No reasoning notes appear in responses

### AC-133.5: Documentation
- [ ] Complete installation guide created
- [ ] Troubleshooting section included
- [ ] Template usage instructions provided

## DEPENDENCIES

- Existing preprocessing script (`scripts/preprocess_oracle.py`)
- Personas configuration system
- Oracle JSON structure
- Audio formatting and MCP instructions (separate files)

## RISKS & MITIGATIONS

**Risk:** Manual template application errors  
**Mitigation:** Automated validation checks and clear documentation

**Risk:** Version conflicts with existing Oracles  
**Mitigation:** Version validation in installation script

**Risk:** Missing critical behavioral rules  
**Mitigation:** Template system ensures rules are always included

## SUCCESS METRICS

- Zero installation errors for new Oracle versions
- 100% consistency in IDENTIDADE PRINCIPAL and MENSAGEM DE APRESENTAÇÃO sections
- Automated detection of missing TRANSPARÊNCIA ZERO rule
- Successful integration of all three personas per Oracle version

## FUTURE ENHANCEMENTS

- GUI-based Oracle installation tool
- Automated testing of new Oracle versions
- Version migration scripts for existing Oracles
- Oracle performance analytics and optimization suggestions
