class TextNormalizer {
  static List<String> normalizeTagList(List<String> tags) {
    if (tags.isEmpty) return ['Documento'];
    
    final commonWords = {
      'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
      'del', 'al', 'y', 'o', 'a', 'de', 'en', 'con', 'por', 'para'
    };
    
    final normalizedTags = <String>{};
    
    for (final tag in tags) {
      final normalized = normalizeTag(tag);
      if (normalized.isNotEmpty && !commonWords.contains(normalized.toLowerCase())) {
        normalizedTags.add(normalized);
      }
    }
    
    return normalizedTags.isEmpty ? ['Documento'] : normalizedTags.toList();
  }
  
  static String normalizeTag(String tag) {
    if (tag.isEmpty) return tag;
    
    tag = tag.replaceAll(RegExp(r'[^\w\s]'), '');
    
    tag = tag.replaceAll('á', 'a')
             .replaceAll('é', 'e')
             .replaceAll('í', 'i')
             .replaceAll('ó', 'o')
             .replaceAll('ú', 'u')
             .replaceAll('ü', 'u')
             .replaceAll('ñ', 'n')
             .replaceAll('Á', 'A')
             .replaceAll('É', 'E')
             .replaceAll('Í', 'I')
             .replaceAll('Ó', 'O')
             .replaceAll('Ú', 'U')
             .replaceAll('Ü', 'U')
             .replaceAll('Ñ', 'N');
             
    final parts = tag.trim().split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    
    return parts
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
  }
}