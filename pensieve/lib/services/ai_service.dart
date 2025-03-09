import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'ai/mime_utils.dart';
import 'ai/text_extractor.dart';
import 'ai/text_normalizer.dart';
import 'ai/description_generator.dart';
import 'ai/tag_generator.dart';

class AIService {
  static const String _apiKeyStorage = 'gemini_api_key';
  static final _storage = FlutterSecureStorage();
  
  static Future<String> get _apiKey async {
    try {
      final savedKey = await _storage.read(key: _apiKeyStorage);
      if (savedKey != null && savedKey.isNotEmpty) {
        return savedKey;
      }
      
      final envKey = dotenv.env['API-KEY'];
      if (envKey != null && envKey.isNotEmpty) {
        await _storage.write(key: _apiKeyStorage, value: envKey);
        return envKey;
      }
    } catch (e) {
      debugPrint('Error al acceder al almacenamiento seguro: $e');
    }
    
    return ''; 
  }
  
  static Future<bool> saveApiKey(String apiKey) async {
    try {
      await _storage.write(key: _apiKeyStorage, value: apiKey);
      return true;
    } catch (e) {
      debugPrint('Error al guardar API Key: $e');
      return false;
    }
  }
  
  static Future<bool> hasApiKey() async {
    try {
      final key = await _apiKey;
      return key.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  static Future<String> getCurrentApiKey() async {
    try {
      return await _apiKey;
    } catch (e) {
      return '';
    }
  }
  
  Future<bool> get hasValidApiKey async {
    final key = await _apiKey;
    return key.isNotEmpty;
  }
  
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
    final apiKeyValue = await _apiKey;
    if (apiKeyValue.isEmpty) {
      debugPrint('⚠️ No se encontró una clave de API válida');
      return null;
    }
    
    return DescriptionGenerator.generateDescription(
      apiKey: apiKeyValue,
      fileName: fileName,
      fileType: fileType,
      fileContent: fileContent,
    );
  }
  
  Future<String?> generateDocumentDescriptionFromFile(File file) async {
    final apiKeyValue = await _apiKey;
    if (apiKeyValue.isEmpty) {
      debugPrint('⚠️ No se encontró una clave de API válida');
      return null;
    }
    
    return DescriptionGenerator.generateFromFile(
      apiKey: apiKeyValue,
      file: file,
    );
  }
  
  Future<List<String>?> generateDocumentTags({
    required String fileName, 
    required String fileType,
    required String fileContent,
  }) async {
    final apiKeyValue = await _apiKey;
    if (apiKeyValue.isEmpty) {
      debugPrint('⚠️ No se encontró una clave de API válida');
      return null;
    }
    
    return TagGenerator.generateTags(
      apiKey: apiKeyValue,
      fileName: fileName,
      fileType: fileType,
      fileContent: fileContent,
    );
  }
  
  Future<List<String>?> generateDocumentTagsFromFile(File file) async {
    final apiKeyValue = await _apiKey;
    if (apiKeyValue.isEmpty) {
      debugPrint('⚠️ No se encontró una clave de API válida');
      return null;
    }
    
    return TagGenerator.generateFromFile(
      apiKey: apiKeyValue,
      file: file,
    );
  }
  
  String generateBasicDescription(String fileName, {String? fileExtension}) {
    return DescriptionGenerator.generateBasicDescription(fileName, fileExtension: fileExtension);
  }
}