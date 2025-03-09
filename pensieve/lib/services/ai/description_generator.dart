import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../ai/rate_limiter.dart';
import '../ai/text_extractor.dart';
import '../ai/mime_utils.dart';

class DescriptionGenerator {
  static const String _aiModelFull = 'gemini-2.0-pro-exp-02-05';
  
  static Future<String?> generateDescription({
    required String apiKey,
    required String fileName,
    required String fileType,
    required String fileContent,
  }) async {
    if (apiKey.isEmpty) {
      debugPrint('⚠️ No se proporcionó una clave de API válida');
      return null;
    }
    
    final requestId = 'desc_text_${fileName}_${DateTime.now().millisecondsSinceEpoch}';
    
    return RateLimiter.enqueueRequest(requestId, () async {
      try {
        bool isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(
          fileType.toLowerCase()
        );
        
        final modelName = _aiModelFull;
        
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.2,
            maxOutputTokens: isImage ? 800 : 4000,
          ),
        );
        
        String limitedContent = fileContent;
        if (fileContent.length > 40000) {  
          limitedContent = '${fileContent.substring(0, 39700)}... [contenido truncado]';
        }
        
        String prompt = isImage
          ? '''
            Genera una descripción breve y concisa de esta imagen.
            
            Nombre del archivo: $fileName
            Tipo de archivo: $fileType
            
            Contenido del documento:
            $limitedContent
            
            Instrucciones:
            - La descripción debe ser breve y concisa (máximo 3-4 frases)
            - Menciona los elementos principales visibles
            - Sé específico y descriptivo
            - No incluyas información confidencial
            - No menciones que esto es una descripción generada por IA
            - La descripción debe estar en español
            '''
          : '''
            Genera una descripción detallada y completa de este documento.
            
            Nombre del archivo: $fileName
            Tipo de archivo: $fileType
            
            Contenido del documento:
            $limitedContent
            
            Instrucciones:
            - La descripción debe ser muy completa, detallada y precisa
            - Incluye el propósito y función principal del documento
            - Menciona los puntos clave y temas principales
            - No incluyas información confidencial
            - No menciones que esto es una descripción generada por IA
            - Si es un documento académico, incluye un resumen detallado y completo de su contenido
            - No hay límite de longitud para la descripción, sé tan exhaustivo como sea necesario
            - Las descripciones deben estar siempre en español
            ''';
        
        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        return response.text;
      } catch (e) {
        debugPrint('Error al generar descripción con IA: $e');
        return null;
      }
    });
  }
  
  static Future<String?> generateFromFile({
    required String apiKey, 
    required File file,
  }) async {
    if (apiKey.isEmpty) {
      debugPrint('⚠️ No se proporcionó una clave de API válida');
      return null;
    }
    
    final requestId = 'desc_file_${file.path}_${DateTime.now().millisecondsSinceEpoch}';
    
    return RateLimiter.enqueueRequest(requestId, () async {
      try {
        final fileName = file.path.split(Platform.pathSeparator).last;
        final fileExtension = fileName.contains('.') 
            ? fileName.split('.').last.toLowerCase() 
            : '';
        
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          debugPrint('Archivo vacío: ${file.path}');
          return generateBasicDescription(fileName, fileExtension: fileExtension);
        }
        
        final mimeType = MimeUtils.getMimeType(file.path, bytes);
        final isImage = mimeType.startsWith('image/');
        
        debugPrint('Analizando archivo: $fileName ($mimeType) con extensión $fileExtension');
        
        final String modelToUse = _aiModelFull;
        
        if (MimeUtils.isMimeTypeSupportedByGemini(mimeType)) {
          debugPrint('Usando método directo para analizar el archivo');
          final directResult = await _generateDescriptionDirectMethod(
            apiKey, file, fileName, fileExtension, bytes, mimeType, modelToUse, isImage
          );
          
          if (directResult != null && directResult.isNotEmpty) {
            return directResult;
          }
          debugPrint('Método directo falló, intentando extracción de texto');
        }
        
        if (isImage) {
          return generateEnhancedImageDescription(fileName);
        }
        
        debugPrint('Intentando extraer texto del archivo...');
        final extractedText = await TextExtractor.extractTextFromFile(file.path, mimeType);
        
        if (extractedText != null && extractedText.isNotEmpty) {
          debugPrint('Texto extraído exitosamente (${extractedText.length} caracteres). Generando descripción...');
          return await generateDescription(
            apiKey: apiKey,
            fileName: fileName,
            fileType: fileExtension,
            fileContent: extractedText,
          );
        } else {
          debugPrint('No se pudo extraer texto del archivo. Generando descripción básica.');
          return generateBasicDescription(fileName, fileExtension: fileExtension);
        }
      } catch (e) {
        debugPrint('Error al generar descripción desde archivo: $e');
        return generateBasicDescription(file.path.split(Platform.pathSeparator).last, 
                                fileExtension: file.path.split('.').last);
      }
    });
  }
  
  static String generateBasicDescription(String fileName, {String? fileExtension}) {
    final extension = fileExtension ?? (fileName.contains('.') ? fileName.split('.').last : 'desconocido');
    final baseName = fileName.contains('.') ? fileName.split('.').first : fileName;
    
    String typeSpecificDesc = "";
    switch (extension.toLowerCase()) {
      case "pdf":
        typeSpecificDesc = "Este PDF puede contener un informe, documento académico o publicación formal.";
        break;
      case "jpg": case "jpeg": case "png": case "gif": case "webp": case "bmp":
        typeSpecificDesc = "Esta imagen puede mostrar contenido visual relevante relacionado con el tema.";
        break;
      case "doc": case "docx": case "odt":
        typeSpecificDesc = "Este documento de texto puede contener un reporte, carta o información textual estructurada.";
        break;
      case "xls": case "xlsx": case "csv":
        typeSpecificDesc = "Esta hoja de cálculo puede contener datos estadísticos, tablas o información numérica organizada.";
        break;
      case "ppt": case "pptx":
        typeSpecificDesc = "Esta presentación puede contener diapositivas informativas o material para exposiciones.";
        break;
      case "mp4": case "avi": case "mov": case "mkv":
        typeSpecificDesc = "Este video puede mostrar contenido audiovisual como entrevistas, tutoriales o grabaciones.";
        break;
      default:
        typeSpecificDesc = "Este archivo puede contener información relevante";
    }
    
    final DateTime now = DateTime.now();
    return "Documento ${extension.toUpperCase()} agregado el ${now.day}/${now.month}/${now.year}. "
           "$typeSpecificDesc relacionado con $baseName.";
  }

  static String generateEnhancedImageDescription(String fileName) {
    final baseName = fileName.contains('.') ? fileName.split('.').first : fileName;
    final nameParts = baseName.replaceAll(RegExp(r'[_-]'), ' ').split(' ');
    
    // Crear una descripción más contextual basada en el nombre del archivo
    final description = "Esta imagen muestra contenido visual relacionado con ${nameParts.join(' ')}. "
                       "La imagen fue agregada a la biblioteca de documentos y puede contener elementos "
                       "visuales relevantes para el contexto del archivo.";
    
    return description;
  }

  static Future<String?> _generateDescriptionDirectMethod(
      String apiKey, 
      File file, 
      String fileName, 
      String fileExtension, 
      List<int> bytes, 
      String mimeType,
      String modelName,
      bool isImage) async {
    try {
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.2,
          maxOutputTokens: isImage ? 800 : 4000,
        ),
      );
      
      String promptText = isImage 
      ? '''
        Analiza esta imagen y genera una descripción breve y concisa.
        Nombre del archivo: $fileName
        
        Instrucciones:
        - Genera una descripción concisa del contenido de la imagen (máximo 3-4 frases)
        - Menciona los elementos principales visibles
        - Sé específico sobre colores, objetos, personas o escenas
        - No incluyas información confidencial
        - No menciones que esto es una descripción generada por IA
        - La descripción debe estar en español
      '''
      : '''
        Analiza este archivo y genera una descripción completa y detallada.
        Nombre del archivo: $fileName
        Tipo de archivo: $fileExtension
        
        Instrucciones:
        - Genera una descripción detallada del contenido del archivo
        - Incluye el propósito principal y la función del archivo
        - Menciona los puntos clave y temas principales que contiene
        - No incluyas información confidencial
        - No menciones que esto es una descripción generada por IA
        - Si es un documento académico, incluye un resumen completo de su contenido
        - Sé exhaustivo, no hay límite de longitud para la descripción
        - Las descripciones deben estar siempre en español
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
      return response.text;
    } catch (e) {
      debugPrint('Error en método directo de descripción: $e');
      return null;
    }
  }
}