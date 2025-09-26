/// UTF-8 encoding fix utility
/// 
/// Fixes common UTF-8 double-encoding issues where Portuguese characters
/// are corrupted during LLM processing
class UTF8Fix {
  /// Fix common UTF-8 double-encoding issues
  /// 
  /// Corrects patterns like:
  /// - "repetiÃ§Ãµes" → "repetições"
  /// - "exercÃ­cio" → "exercício"  
  /// - "forÃ§a" → "força"
  static String fix(String text) {
    if (text.isEmpty) return text;
    
    // Common Portuguese character corrections
    final corrections = {
      'Ã§': 'ç',    // ç (cedilla)
      'Ã£': 'ã',    // ã (tilde)
      'Ã¡': 'á',    // á (acute)
      'Ã©': 'é',    // é (acute)
      'Ã­': 'í',    // í (acute)
      'Ã³': 'ó',    // ó (acute)
      'Ãº': 'ú',    // ú (acute)
      'Ã ': 'à',    // à (grave)
      'Ã¨': 'è',    // è (grave)
      'Ã¬': 'ì',    // ì (grave)
      'Ã²': 'ò',    // ò (grave)
      'Ã¹': 'ù',    // ù (grave)
      'Ã¢': 'â',    // â (circumflex)
      'Ãª': 'ê',    // ê (circumflex)
      'Ã®': 'î',    // î (circumflex)
      'Ã´': 'ô',    // ô (circumflex)
      'Ã»': 'û',    // û (circumflex)
      'Ã¤': 'ä',    // ä (diaeresis)
      'Ã«': 'ë',    // ë (diaeresis)
      'Ã¯': 'ï',    // ï (diaeresis)
      'Ã¶': 'ö',    // ö (diaeresis)
      'Ã¼': 'ü',    // ü (diaeresis)
      'Ãµ': 'õ',    // õ (tilde)
      'Ã±': 'ñ',    // ñ (tilde)
    };
    
    String fixed = text;
    corrections.forEach((corrupted, correct) {
      fixed = fixed.replaceAll(corrupted, correct);
    });
    
    return fixed;
  }
  
  /// Fix UTF-8 issues in JSON strings
  /// 
  /// Specifically handles JSON values while preserving JSON structure
  static String fixJsonValues(String jsonString) {
    if (jsonString.isEmpty) return jsonString;
    
    // Fix values in JSON strings (between quotes)
    return jsonString.replaceAllMapped(
      RegExp(r'"([^"]*)"'),
      (match) {
        final value = match.group(1)!;
        final fixed = fix(value);
        return '"$fixed"';
      },
    );
  }
}
