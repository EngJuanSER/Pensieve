import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../ai/rate_limiter.dart';
import '../ai/text_extractor.dart';
import '../ai/text_normalizer.dart';
import '../ai/mime_utils.dart';

class TagGenerator {
  static const String _aiModel = 'gemini-2.0-pro-exp-02-05';

  static Future<List<String>?> generateTags({
    required String apiKey,
    required String fileName, 
    required String fileType,
    required String fileContent,
  }) async {
    if (apiKey.isEmpty) {
      debugPrint('⚠️ No se proporcionó una clave de API válida');
      return null;
    }
    
    final requestId = 'tags_text_${fileName}_${DateTime.now().millisecondsSinceEpoch}';
    
    return RateLimiter.enqueueRequest(requestId, () async {
      try {
        final model = GenerativeModel(
          model: _aiModel,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.1,
            maxOutputTokens: 100,
          ),
        );
        
        String limitedContent = fileContent;
        if (fileContent.length > 40000) {
          limitedContent = '${fileContent.substring(0, 39700)}... [contenido truncado]';
        }
        
        final content = [
          Content.text('''
            Genera exactamente 5 etiquetas relevantes y específicas para este documento.
            
            Instrucciones:
            - Las etiquetas deben reflejar fielmente el contenido y el propósito del documento
            - Las etiquetas DEBEN estar ÚNICAMENTE en español (NO en inglés)
            - Cada etiqueta debe tener una o dos palabras como máximo
            - NO uses etiquetas genéricas como "documento", "archivo" o similares
            - Devuelve solo las etiquetas separadas por comas sin ningún otro texto
            - Ejemplo de formato correcto: "análisis, estadísticas, resultados, presupuesto, informe"
            
            Nombre del archivo: $fileName
            Tipo de archivo: $fileType
            
            Contenido del documento:
            $limitedContent
          ''')
        ];
        
        final response = await model.generateContent(content);
        final tagsText = response.text?.trim() ?? '';
        
        final rawTags = tagsText
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();
        
        return TextNormalizer.normalizeTagList(rawTags);
      } catch (e) {
        debugPrint('Error al generar etiquetas con IA: $e');
        return null;
      }
    });
  }
  
  static Future<List<String>?> generateFromFile({
    required String apiKey,
    required File file,
  }) async {
    if (apiKey.isEmpty) {
      debugPrint('⚠️ No se proporcionó una clave de API válida');
      return null;
    }
    
    final requestId = 'tags_file_${file.path}_${DateTime.now().millisecondsSinceEpoch}';
    
    return RateLimiter.enqueueRequest(requestId, () async {
      try {
        final fileName = file.path.split(Platform.pathSeparator).last;
        final fileExtension = fileName.contains('.') 
            ? fileName.split('.').last.toLowerCase() 
            : '';
        
        final bytes = await file.readAsBytes();
        final mimeType = MimeUtils.getMimeType(file.path, bytes);
        final isImage = mimeType.startsWith('image/');
        
        debugPrint('Generando etiquetas para: $fileName ($mimeType) con extensión $fileExtension');
        
        if (MimeUtils.isMimeTypeSupportedByGemini(mimeType)) {
          final directTags = await _generateTagsDirectMethod(
            apiKey, file, fileName, fileExtension, bytes, mimeType, isImage);
            
          if (directTags != null && directTags.isNotEmpty) {
            return TextNormalizer.normalizeTagList(directTags);
          }
        }
        
        if (isImage) {
          debugPrint('Usando etiquetas por defecto para imagen');
          return TextNormalizer.normalizeTagList([
            TextNormalizer.normalizeTag(fileExtension.toUpperCase()),
            'Imagen', 
            'Visual',
            fileName.split('.').first 
          ]);
        }
        
        debugPrint('Intentando extraer texto para generar etiquetas...');
        final extractedText = await TextExtractor.extractTextFromFile(file.path, mimeType);
        
        if (extractedText != null && extractedText.isNotEmpty) {
          debugPrint('Texto extraído para etiquetas. Generando etiquetas basadas en texto...');
          final tags = await generateTags(
            apiKey: apiKey,
            fileName: fileName,
            fileType: fileExtension,
            fileContent: extractedText,
          );
          
          if (tags != null && tags.isNotEmpty) {
            return tags;
          }
        }
        
        final String categoryTag = _getCategoryTagByFileType(fileExtension);
        final defaultTags = [
          TextNormalizer.normalizeTag(fileExtension.toUpperCase()), 
          categoryTag,
          'Documento'
        ];
        
        return TextNormalizer.normalizeTagList(defaultTags);
      } catch (e) {
        debugPrint('Error al generar etiquetas desde archivo: $e');
        return ['Documento'];
      }
    });
  }
  
  static String _getCategoryTagByFileType(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case 'pdf': return 'Informe';
      case 'doc':
      case 'docx':
      case 'odt': return 'Texto';
      case 'xls':
      case 'xlsx':
      case 'csv': return 'Datos';
      case 'ppt':
      case 'pptx': return 'Presentación';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp': return 'Imagen';
      case 'mp4':
      case 'avi':
      case 'mov': return 'Video';
      case 'mp3':
      case 'wav': return 'Audio';
      default: return 'Archivo';
    }
  }
  
  static Future<List<String>?> _generateTagsDirectMethod(
      String apiKey,
      File file, 
      String fileName, 
      String fileExtension, 
      List<int> bytes, 
      String mimeType,
      bool isImage) async {
    try {
      final model = GenerativeModel(
        model: _aiModel,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.1,
          maxOutputTokens: 100,
        ),
      );
      
      String promptText = isImage
      ? '''
        Genera exactamente 5 etiquetas específicas para esta imagen.
        Nombre del archivo: $fileName
        
        Instrucciones:
        - Las etiquetas deben describir específicamente lo que se ve en la imagen
        - NO uses etiquetas genéricas como "imagen", "foto", "fotografía", "jpeg" o "jpg"
        - Enfócate en objetos, escenarios, personas, colores o temas específicos visibles
        - Las etiquetas DEBEN estar ÚNICAMENTE en español (no en inglés)
        - Cada etiqueta debe tener una o dos palabras como máximo
        - Devuelve solo las etiquetas separadas por comas, sin ningún otro texto
        - Ejemplo de formato para una foto de un perro: "Perro, Mascota, Animal, Exterior, Naturaleza"
      '''
      : '''
        Genera exactamente 5 etiquetas relevantes para este archivo.
        Nombre del archivo: $fileName
        Tipo de archivo: $fileExtension
        
        Instrucciones:
        - Las etiquetas deben reflejar el contenido y el propósito específico del archivo
        - NO uses etiquetas genéricas como "documento", "archivo" o "$fileExtension"
        - Las etiquetas DEBEN estar ÚNICAMENTE en español (no en inglés)
        - Cada etiqueta debe tener una o dos palabras como máximo
        - Devuelve solo las etiquetas separadas por comas, sin ningún otro texto o explicación
      ''';
      
      final maxBytes = 5 * 1024 * 1024; 
      final fileBytes = bytes.length > maxBytes ? bytes.sublist(0, maxBytes) : bytes;
      
      final content = [
        Content.multi([
          TextPart(promptText),
          DataPart(mimeType, Uint8List.fromList(fileBytes)),
        ]),
      ];
      
      final response = await model.generateContent(content);
      final tagsText = response.text?.trim() ?? '';
      
      return tagsText
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error en método directo para etiquetas: $e');
      return null;
    }
  }
}