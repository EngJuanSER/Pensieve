import 'package:mime/mime.dart' as mime;
import 'dart:math' as math;

class MimeUtils {
  static const List<String> supportedMimeTypesForGemini = [
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
  
  static bool isMimeTypeSupportedByGemini(String mimeType) {
    return supportedMimeTypesForGemini.contains(mimeType);
  }
  
  static String getMimeType(String filePath, List<int> headerBytes) {
    String? detectedType = mime.lookupMimeType(filePath, headerBytes: headerBytes.take(16).toList());
    
    if (detectedType != null) {
      return detectedType;
    }
    
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      // Documentos de Office
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt': return 'application/vnd.ms-powerpoint';
      case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      
      // Documentos OpenDocument
      case 'odt': return 'application/vnd.oasis.opendocument.text';
      case 'ods': return 'application/vnd.oasis.opendocument.spreadsheet';
      case 'odp': return 'application/vnd.oasis.opendocument.presentation';
      
      // Formatos de texto/código
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
      
      // Imágenes
      case 'jpg': 
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'bmp': return 'image/bmp';
      case 'webp': return 'image/webp';
      case 'svg': return 'image/svg+xml';
      
      // PDF
      case 'pdf': return 'application/pdf';
      
      // Archivos comprimidos
      case 'zip': return 'application/zip';
      case 'rar': return 'application/x-rar-compressed';
      case '7z': return 'application/x-7z-compressed';
      
      // Otros formatos
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
  
  static String formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    if (bytes == 0) return '0 B';
    
    final i = (math.log(bytes) / math.log(1024)).floor();
    final size = bytes / math.pow(1024, i);
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }
}