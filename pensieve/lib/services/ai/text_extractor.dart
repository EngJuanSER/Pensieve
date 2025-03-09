import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'mime_utils.dart';

class TextExtractor {
  static final List<String> textFormats = [
    'txt', 'md', 'json', 'csv', 'xml', 'html', 'htm', 
    'css', 'js', 'dart', 'py', 'java', 'c', 'cpp', 'cs',
    'sh', 'bat', 'ps1', 'yaml', 'yml', 'toml', 'ini', 'cfg',
    'log', 'sql', 'r', 'rb', 'pl', 'php', 'ts', 'tsx', 'jsx'
  ];

  static Future<String?> extractTextFromFile(String filePath, String mimeType) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      final extension = filePath.split('.').last.toLowerCase();
      final bytes = await file.readAsBytes();
      
      if (textFormats.contains(extension)) {
        return await _readTextFile(file);
      }
      
      if (['docx', 'xlsx', 'pptx'].contains(extension)) {
        return await _extractFromOfficeDocument(bytes);
      }
      
      if (extension == 'html' || extension == 'htm') {
        return await _extractFromHtml(file);
      }
      
      return 'No se pudo extraer contenido de este archivo ${extension.toUpperCase()}. '
             'Tamaño: ${MimeUtils.formatFileSize(bytes.length)}. '
             'Tipo MIME: $mimeType.';
    } catch (e) {
      debugPrint('Error al extraer texto de archivo: $e');
      return null;
    }
  }

  static Future<String?> _readTextFile(File file) async {
    try {
      try {
        return await file.readAsString(encoding: utf8);
      } catch (e) {
        try {
          return await file.readAsString(encoding: latin1);
        } catch (e2) {
          debugPrint('Error al leer archivo como texto: $e2');
          return null;
        }
      }
    } catch (e) {
      debugPrint('Error general al leer archivo: $e');
      return null;
    }
  }
  
  static Future<String?> _extractFromOfficeDocument(List<int> bytes) async {
    debugPrint('Intentando extraer contenido de archivo Office');
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
                       .replaceAll(RegExp(r'\{[^}]*\}'), ' ')
                       .trim();
        
        if (content.length > 40000) {
          content = '${content.substring(0, 39700)}... [contenido truncado]';
        }
        
        return content;
      }
      return null;
    } catch (e) {
      debugPrint('Error al procesar archivo Office: $e');
      return null;
    }
  }
  
  static Future<String?> _extractFromHtml(File file) async {
    try {
      String content;
      try {
        content = await file.readAsString(encoding: utf8);
      } catch (_) {
        try {
          content = await file.readAsString(encoding: latin1);
        } catch (e) {
          debugPrint('Error al leer HTML: $e');
          return null;
        }
      }
      
      content = content.replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>'), ' ')
                     .replaceAll(RegExp(r'<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>'), ' ')
                     .replaceAll(RegExp(r'<head\b[^<]*(?:(?!<\/head>)<[^<]*)*<\/head>'), ' ')
                     .replaceAll(RegExp(r'<[^>]*>'), ' ')
                     .replaceAll(RegExp(r'\s+'), ' ')
                     .trim();
      
      if (content.length > 40000) {
        content = '${content.substring(0, 39700)}... [contenido truncado]';
      }
      
      return content.isNotEmpty ? content : null;
    } catch (e) {
      debugPrint('Error al procesar HTML: $e');
      return null;
    }
  }
}