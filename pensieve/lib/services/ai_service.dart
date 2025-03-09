import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'ai/mime_utils.dart';
import 'ai/text_extractor.dart';
import 'ai/text_normalizer.dart';
import 'ai/description_generator.dart';
import 'ai/tag_generator.dart';

class AIService {
  static String get _apiKey {
    final envKey = dotenv.env['API-KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    debugPrint('⚠️ Advertencia: Usando clave API por defecto. No recomendado para producción.');
    return 'API-KEY';
  }
  
  bool get hasValidApiKey => _apiKey != 'API-KEY' && _apiKey.isNotEmpty;
  
  bool isMimeTypeSupportedByGemini(String mimeType) {
    return MimeUtils.isMimeTypeSupportedByGemini(mimeType);
  }
  
  String getMimeType(String filePath, List<int> headerBytes) {
    return MimeUtils.getMimeType(filePath, headerBytes);
  }
  
  List<String> normalizeTagList(List<String> tags) {
    return TextNormalizer.normalizeTagList(tags);
  }
  
  String normalizeTag(String tag) {
    return TextNormalizer.normalizeTag(tag);
  }
  
  Future<String?> extractTextFromUnsupportedFile(String filePath, String mimeType) async {
    return TextExtractor.extractTextFromFile(filePath, mimeType);
  }
  
  Future<String?> generateDocumentDescription({
    required String fileName, 
    required String fileType,
    required String fileContent,
  }) async {
    if (!hasValidApiKey) {
      debugPrint('⚠️ No se encontró una clave de API válida');
      return null;
    }
    
    return DescriptionGenerator.generateDescription(
      apiKey: _apiKey,
      fileName: fileName,
      fileType: fileType,
      fileContent: fileContent,
    );
  }
  
  Future<String?> generateDocumentDescriptionFromFile(File file) async {
    if (!hasValidApiKey) {
      debugPrint('⚠️ No se encontró una clave de API válida');
      return null;
    }
    
    return DescriptionGenerator.generateFromFile(
      apiKey: _apiKey,
      file: file,
    );
  }
  
  Future<List<String>?> generateDocumentTags({
    required String fileName, 
    required String fileType,
    required String fileContent,
  }) async {
    if (!hasValidApiKey) {
      debugPrint('⚠️ No se encontró una clave de API válida');
      return null;
    }
    
    return TagGenerator.generateTags(
      apiKey: _apiKey,
      fileName: fileName,
      fileType: fileType,
      fileContent: fileContent,
    );
  }
  
  Future<List<String>?> generateDocumentTagsFromFile(File file) async {
    if (!hasValidApiKey) {
      debugPrint('⚠️ No se encontró una clave de API válida');
      return null;
    }
    
    return TagGenerator.generateFromFile(
      apiKey: _apiKey,
      file: file,
    );
  }
  
  String generateBasicDescription(String fileName, {String? fileExtension}) {
    return DescriptionGenerator.generateBasicDescription(fileName, fileExtension: fileExtension);
  }
}