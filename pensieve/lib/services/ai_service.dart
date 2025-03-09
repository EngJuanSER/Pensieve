import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:mime/mime.dart' as mime;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:archive/archive.dart';

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
  
  static const List<String> _supportedMimeTypesForGemini = [
    'text/plain',
    'text/csv',
    'application/json',
    'application/xml',
    'text/html',
    'text/css',
    'text/javascript',
    'text/x-python',
    'text/x-java',
    'text/x-c',
    'text/x-c++',
    'text/x-csharp',
    'text/x-dart',
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/bmp',
    'image/webp',
    'application/pdf'
  ];
  
  bool isMimeTypeSupportedByGemini(String mimeType) {
    return _supportedMimeTypesForGemini.contains(mimeType);
  }
  
  String getMimeType(String filePath, List<int> headerBytes) {
    String? detectedType = mime.lookupMimeType(filePath, headerBytes: headerBytes.take(16).toList());
    
    if (detectedType != null) {
      return detectedType;
    }
    
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt': return 'application/vnd.ms-powerpoint';
      case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      
      case 'odt': return 'application/vnd.oasis.opendocument.text';
      case 'ods': return 'application/vnd.oasis.opendocument.spreadsheet';
      case 'odp': return 'application/vnd.oasis.opendocument.presentation';
      
      case 'txt': return 'text/plain';
      case 'csv': return 'text/csv';
      case 'json': return 'application/json';
      case 'xml': return 'application/xml';
      case 'html': 
      case 'htm': return 'text/html';
      case 'css': return 'text/css';
      case 'js': return 'text/javascript';
      case 'py': return 'text/x-python';
      case 'java': return 'text/x-java';
      case 'c': return 'text/x-c';
      case 'cpp': return 'text/x-c++';
      case 'cs': return 'text/x-csharp';
      case 'dart': return 'text/x-dart';
      
      case 'jpg': 
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'bmp': return 'image/bmp';
      case 'webp': return 'image/webp';
      case 'svg': return 'image/svg+xml';
      
      case 'pdf': return 'application/pdf';
      
      case 'zip': return 'application/zip';
      case 'rar': return 'application/x-rar-compressed';
      case '7z': return 'application/x-7z-compressed';
      
      case 'md': return 'text/markdown';
      case 'rtf': return 'application/rtf';
      case 'mp3': return 'audio/mpeg';
      case 'mp4': return 'video/mp4';
      case 'wav': return 'audio/wav';
      case 'avi': return 'video/x-msvideo';
      case 'sql': return 'application/sql';
      case 'yaml': 
      case 'yml': return 'application/x-yaml';
      
      default: return 'application/octet-stream';
    }
  }

  Future<String?> extractTextFromUnsupportedFile(String filePath, String mimeType) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      final extension = filePath.split('.').last.toLowerCase();
      final bytes = await file.readAsBytes();
      
      List<String> textFormats = [
        'txt', 'md', 'json', 'csv', 'xml', 'html', 'htm', 
        'css', 'js', 'dart', 'py', 'java', 'c', 'cpp', 'cs',
        'sh', 'bat', 'ps1', 'yaml', 'yml', 'toml', 'ini', 'cfg',
        'log', 'sql', 'r', 'rb', 'pl', 'php', 'ts', 'tsx', 'jsx'
      ];
      
      if (textFormats.contains(extension)) {
        try {
          try {
            return await file.readAsString(encoding: utf8);
          } catch (e) {
            try {
              return await file.readAsString(encoding: latin1);
            } catch (e2) {
              debugPrint('Error al leer archivo como texto con latin1: $e2');
              return null;
            }
          }
        } catch (e) {
          debugPrint('Error al leer archivo como texto: $e');
          return null;
        }
      }
      
      if (['docx', 'xlsx', 'pptx'].contains(extension)) {
        debugPrint('Intentando extraer contenido básico de archivo Office: $extension');
        try {
          final archive = ZipDecoder().decodeBytes(bytes);
          
          String? content;
          for (final file in archive) {
            if (file.isFile) {
              String filename = file.name.toLowerCase();
              if (filename.contains('document.xml') || 
                  filename.contains('content.xml') ||
                  filename.contains('/word/document.xml') ||
                  filename.contains('/word/') ||
                  filename.contains('/xl/worksheets/') ||
                  filename.contains('/xl/sharedStrings.xml') ||
                  filename.contains('ppt/slides/')) {
                final data = file.content as List<int>;
                try {
                  final text = utf8.decode(data);
                  content ??= "";
                  content += "$text\n";
                } catch (e) {
                  try {
                    final text = latin1.decode(data);
                    content ??= "";
                    content += "$text\n";
                  } catch (_) {
                  }
                }
              }
            }
          }
          
          if (content != null && content.isNotEmpty) {
            content = content.replaceAll(RegExp(r'<[^>]*>'), ' ')
                           .replaceAll(RegExp(r'\s+'), ' ')
                           .replaceAll(RegExp(r'\{[^}]*\}'), ' ') // Eliminar bloques entre llaves
                           .trim();
            
            if (content.length > 40000) {
              content = '${content.substring(0, 39700)}... [contenido truncado]';
            }
            
            return content;
          }
        } catch (e) {
          debugPrint('Error al procesar archivo Office: $e');
        }
      }
      
      if (extension == 'html' || extension == 'htm') {
        try {
          String content;
          try {
            content = await file.readAsString(encoding: utf8);
          } catch (_) {
            try {
              content = await file.readAsString(encoding: latin1);
            } catch (e) {
              debugPrint('Error al leer HTML con encodings conocidos: $e');
              return null;
            }
          }
          
          content = content.replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>'), ' ')
                         .replaceAll(RegExp(r'<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>'), ' ')
                         .replaceAll(RegExp(r'<head\b[^<]*(?:(?!<\/head>)<[^<]*)*<\/head>'), ' ')
                         .replaceAll(RegExp(r'<[^>]*>'), ' ')
                         .replaceAll(RegExp(r'\s+'), ' ')
                         .trim();
          
          if (content.isNotEmpty) {
            if (content.length > 40000) {
              content = '${content.substring(0, 39700)}... [contenido truncado]';
            }
            return content;
          }
        } catch (e) {
          debugPrint('Error al procesar HTML: $e');
        }
      }
      
      return 'No se pudo extraer contenido de este archivo ${extension.toUpperCase()}. '
             'Tamaño: ${_formatFileSize(bytes.length)}. '
             'Tipo MIME: $mimeType.';
             
    } catch (e) {
      debugPrint('Error al extraer texto de archivo no soportado: $e');
      return null;
    }
  }
  
  String _formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    if (bytes == 0) return '0 B';
    
    final i = (log(bytes) / log(1024)).floor();
    final size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
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
    
    try {
      bool isImage = fileType.toLowerCase() == 'jpg' || 
                    fileType.toLowerCase() == 'jpeg' || 
                    fileType.toLowerCase() == 'png' || 
                    fileType.toLowerCase() == 'gif' ||
                    fileType.toLowerCase() == 'bmp' ||
                    fileType.toLowerCase() == 'webp';
      
      final model = GenerativeModel(
        model: 'gemini-2.0-pro-exp-02-05', 
        apiKey: _apiKey,
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
          - No incluyas información confidencial
          - No menciones que esto es una descripción generada por IA
          - Mantén la descripción breve pero descriptiva
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
      
      final content = [
        Content.text(prompt)
      ];
      
      final response = await model.generateContent(content);
      return response.text;
    } catch (e) {
      debugPrint('Error al generar descripción con IA: $e');
      return null;
    }
  }
  
  Future<String?> generateDocumentDescriptionFromFile(File file) async {
    if (!hasValidApiKey) {
      debugPrint('⚠️ No se encontró una clave de API válida');
      return null;
    }
    
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final fileExtension = fileName.contains('.') 
          ? fileName.split('.').last.toLowerCase() 
          : '';
      
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        debugPrint('Archivo vacío: ${file.path}');
        return null;
      }
      
      final mimeType = getMimeType(file.path, bytes);
      
      debugPrint('Analizando archivo: $fileName ($mimeType) con extensión $fileExtension');
      
      if (isMimeTypeSupportedByGemini(mimeType)) {
        debugPrint('Usando método directo para analizar el archivo');
        final directResult = await _generateDescriptionDirectMethod(file, fileName, fileExtension, bytes, mimeType);
        if (directResult != null && directResult.isNotEmpty) {
          return directResult;
        }
        debugPrint('Método directo falló, intentando extracción de texto');
      }
      
      debugPrint('Intentando extraer texto del archivo...');
      final extractedText = await extractTextFromUnsupportedFile(file.path, mimeType);
      
      if (extractedText != null && extractedText.isNotEmpty) {
        debugPrint('Texto extraído exitosamente (${extractedText.length} caracteres). Generando descripción...');
        return await generateDocumentDescription(
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
  }
  
  Future<String?> _generateDescriptionDirectMethod(
      File file, String fileName, String fileExtension, List<int> bytes, String mimeType) async {
    try {
      bool isImage = mimeType.startsWith('image/');
      
      final model = GenerativeModel(
        model: 'gemini-2.0-pro-exp-02-05', 
        apiKey: _apiKey,
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
        - No incluyas información confidencial
        - No menciones que esto es una descripción generada por IA
        - Mantén la descripción breve pero descriptiva
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
      debugPrint('Error en método directo: $e');
      return null;
    }
  }
  
  Future<List<String>?> generateDocumentTagsFromFile(File file) async {
    if (!hasValidApiKey) {
      debugPrint('⚠️ No se encontró una clave de API válida');
      return null;
    }
    
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final fileExtension = fileName.contains('.') 
          ? fileName.split('.').last.toLowerCase() 
          : '';
      
      final bytes = await file.readAsBytes();
      final mimeType = getMimeType(file.path, bytes);
      
      debugPrint('Generando etiquetas para: $fileName ($mimeType) con extensión $fileExtension');
      
      if (isMimeTypeSupportedByGemini(mimeType)) {
        final directTags = await _generateTagsDirectMethod(file, fileName, fileExtension, bytes, mimeType);
        if (directTags != null && directTags.isNotEmpty) {
          return directTags;
        }
      }
      
      debugPrint('Intentando extraer texto para generar etiquetas...');
      final extractedText = await extractTextFromUnsupportedFile(file.path, mimeType);
      
      if (extractedText != null && extractedText.isNotEmpty) {
        debugPrint('Texto extraído para etiquetas. Generando etiquetas basadas en texto...');
        return await generateDocumentTags(
          fileName: fileName,
          fileType: fileExtension,
          fileContent: extractedText,
        );
      } else {
        return [fileExtension.toUpperCase(), 'Documento', 'Archivo'];
      }
    } catch (e) {
      debugPrint('Error al generar etiquetas desde archivo: $e');
      return ['Documento', 'Archivo'];
    }
  }
  
  Future<List<String>?> _generateTagsDirectMethod(
      File file, String fileName, String fileExtension, List<int> bytes, String mimeType) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-pro-exp-02-05',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.1,
          maxOutputTokens: 100,
        ),
      );
      
      String promptText = '''
        Genera entre 3 y 5 etiquetas relevantes para este archivo.
        Nombre del archivo: $fileName
        Tipo de archivo: $fileExtension
        
        Instrucciones:
        - Las etiquetas deben reflejar el contenido y el propósito del archivo
        - Las etiquetas DEBEN estar ÚNICAMENTE en español (no en inglés)
        - Cada etiqueta debe tener una o dos palabras como máximo
        - Devuelve solo las etiquetas separadas por comas, sin ningún otro texto o explicación
        - Ejemplo de formato correcto: "documento, análisis, informe, datos, estadística"
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
  
  Future<List<String>?> generateDocumentTags({
    required String fileName, 
    required String fileType,
    required String fileContent,
  }) async {
    if (!hasValidApiKey) {
      debugPrint('⚠️ No se encontró una clave de API válida');
      return null;
    }
    
    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-pro-exp-02-05',
        apiKey: _apiKey,
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
          Genera entre 3 y 5 etiquetas relevantes para este documento.
          
          Instrucciones:
          - Las etiquetas deben reflejar fielmente el contenido y el propósito del documento
          - Las etiquetas DEBEN estar ÚNICAMENTE en español (NO en inglés)
          - Cada etiqueta debe tener una o dos palabras como máximo
          - Devuelve solo las etiquetas separadas por comas sin ningún otro texto
          - Ejemplo de formato correcto: "documento, análisis, informe, datos, estadística"
          
          Nombre del archivo: $fileName
          Tipo de archivo: $fileType
          
          Contenido del documento:
          $limitedContent
        ''')
      ];
      
      final response = await model.generateContent(content);
      final tagsText = response.text?.trim() ?? '';
      
      return tagsText
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error al generar etiquetas con IA: $e');
      return null;
    }
  }
  
  String generateBasicDescription(String fileName, {String? fileExtension}) {
    final extension = fileExtension ?? (fileName.contains('.') ? fileName.split('.').last : 'desconocido');
    final baseName = fileName.contains('.') ? fileName.split('.').first : fileName;
    
    final DateTime now = DateTime.now();
    return "Documento ${extension.toUpperCase()} agregado el ${now.day}/${now.month}/${now.year}. "
           "Posiblemente contiene información relacionada con $baseName.";
  }
  
  double log(num x, [num? base]) {
    return base == null 
        ? math.log(x) 
        : math.log(x) / math.log(base);
  }
  
  num pow(num x, num exponent) {
    return math.pow(x, exponent);
  }
}