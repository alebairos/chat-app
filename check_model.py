import os
import json

def check_model_files():
    """Verify all required Vosk model files are present and properly configured."""
    base_path = 'assets/models/vosk-model-small-en-us'
    required_files = {
        'am/final.mdl',
        'conf/mfcc.conf',
        'graph/Grph',
        'graph/disambig.int',
        'graph/phones/word_boundary.int',
        'ivector/final.ie',
        'README'
    }
    
    # Check file existence
    missing = []
    for rel_path in required_files:
        full_path = os.path.join(base_path, rel_path)
        if not os.path.exists(full_path):
            missing.append(full_path)
    
    # Check pubspec.yaml entries
    with open('pubspec.yaml') as f:
        pubspec = f.read()
    
    missing_in_pubspec = []
    for path in required_files:
        yaml_entry = f'assets/models/vosk-model-small-en-us/{path}'
        if yaml_entry not in pubspec:
            missing_in_pubspec.append(yaml_entry)
    
    # Report results
    if not missing and not missing_in_pubspec:
        print("✅ Model files are correctly set up!")
        return True
    
    if missing:
        print("❌ Missing model files:")
        for path in missing:
            print(f"  - {path}")
    
    if missing_in_pubspec:
        print("❌ Missing pubspec.yaml entries:")
        for entry in missing_in_pubspec:
            print(f"  - {entry}")
    
    return False

if __name__ == "__main__":
    check_model_files() 