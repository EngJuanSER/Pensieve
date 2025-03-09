import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:mime/mime.dart';
import 'dart:ui' as ui;

class FileUtils {
  static Future<void> openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final uri = Uri.file(file.path);
        if (!await launchUrl(uri)) {
          throw 'No se pudo abrir el archivo $filePath';
        }
      } else {
        throw 'El archivo no existe: $filePath';
      }
    } catch (e) {
      debugPrint('Error al abrir archivo: $e');
      rethrow;
    }
  }

  static Future<String?> generateThumbnail(String filePath) async {
    try {
      final fileExtension = path.extension(filePath).toLowerCase();
      final file = File(filePath);
      
      if (!await file.exists()) {
        return null;
      }

      if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(fileExtension)) {
        try {
          final bytes = await file.readAsBytes();
          await decodeImageFromList(bytes);
          return filePath; 
        } catch (e) {
          debugPrint('Error al verificar imagen: $e');
          return null; 
        }
      }
      
      final thumbnailDir = await _getThumbnailDirectory();
      final thumbnailFileName = '${path.basenameWithoutExtension(filePath)}_thumb.png';
      final thumbnailPath = path.join(thumbnailDir.path, thumbnailFileName);
      
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        return thumbnailPath;
      }
      
      final mimeType = lookupMimeType(filePath) ?? '';
      
      if (mimeType.startsWith('text/')) {
        await _generateTextFileThumbnail(filePath, thumbnailPath);
        return thumbnailPath;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error al generar miniatura: $e');
      return null;
    }
  }
  
  static Future<void> _generateTextFileThumbnail(String sourceFilePath, String outputPath) async {
    try {
      final file = File(sourceFilePath);
      final content = await file.readAsString();
      final lines = content.split('\n').take(5)
                           .map((line) => line.length > 100 ? '${line.substring(0, 97)}...' : line)
                           .join('\n');
      
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = Colors.white;
      
      canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 300), paint);
      
      final textStyle = ui.TextStyle(
        color: Colors.black,
        fontSize: 14,
      );
      
      final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 14,
      ))
        ..pushStyle(textStyle)
        ..addText(lines);
      
      final paragraph = paragraphBuilder.build()
        ..layout(const ui.ParagraphConstraints(width: 380));
      
      canvas.drawParagraph(paragraph, const Offset(10, 10));
      
      final picture = recorder.endRecording();
      final img = await picture.toImage(400, 300);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();
      
      await File(outputPath).writeAsBytes(buffer);
    } catch (e) {
      debugPrint('Error al crear miniatura de texto: $e');
    }
  }

  static Future<Directory> _getThumbnailDirectory() async {
    final tempDir = Directory.systemTemp;
    final thumbnailPath = path.join(tempDir.path, 'pensieve_thumbnails');
    final dir = Directory(thumbnailPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String?> extractTextFromFile(String filePath, String fileType) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      final extension = fileType.toLowerCase();
      
      List<String> textFormats = [
        'txt', 'md', 'json', 'csv', 'xml', 'html', 'htm', 
        'css', 'js', 'dart', 'py', 'java', 'c', 'cpp', 'cs',
        'sh', 'bat', 'ps1', 'yaml', 'yml', 'toml', 'ini', 'cfg',
        'log', 'sql', 'r', 'rb', 'pl', 'php', 'ts'
      ];
      
      if (textFormats.contains(extension)) {
        return await file.readAsString();
      }
      
      return null;
    } catch (e) {
      debugPrint('Error al extraer texto: $e');
      return null;
    }
  }

  static String formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    if (bytes == 0) return '0 B';
    
    final i = (log(bytes) / log(1024)).floor();
    final size = bytes / pow(1024, i);
    
    return '${size.toStringAsFixed(i > 0 ? 2 : 0)} ${suffixes[i]}';
  }

  static String formatFileDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static IconData getIconForFileType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
      case 'odt':
        return Icons.description;
      case 'xls':
      case 'xlsx':
      case 'ods':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
      case 'odp':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'md':
        return Icons.article;
      case 'csv':
        return Icons.view_list;
      case 'json':
      case 'xml':
        return Icons.data_object;
      case 'html':
      case 'htm':
      case 'css':
      case 'js':
        return Icons.web;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'wmv':
      case 'flv':
        return Icons.movie;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
      case 'm4a':
      case 'aac':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip;
      case 'exe':
      case 'msi':
      case 'dmg':
      case 'app':
        return Icons.app_shortcut;
      case 'dll':
      case 'so':
      case 'dylib':
        return Icons.settings_applications;
      default:
        return Icons.insert_drive_file;
    }
  }

  static Color getColorForFileType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red.shade700;
      case 'doc':
      case 'docx':
      case 'odt':
        return Colors.blue.shade700;
      case 'xls':
      case 'xlsx':
      case 'ods':
      case 'csv':
        return Colors.green.shade700;
      case 'ppt':
      case 'pptx':
      case 'odp':
        return Colors.deepOrange;
      case 'txt':
      case 'md':
        return Colors.purple;
      case 'json':
      case 'xml':
        return Colors.teal;
      case 'html':
      case 'htm':
      case 'css':
      case 'js':
        return Colors.blue.shade800;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return Colors.amber;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'wmv':
      case 'flv':
        return Colors.pink;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
      case 'm4a':
      case 'aac':
        return Colors.indigo;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Colors.brown;
      case 'exe':
      case 'msi':
      case 'dmg':
      case 'app':
        return Colors.deepPurple;
      case 'dll':
      case 'so':
      case 'dylib':
        return Colors.grey.shade700;
      default:
        return Colors.blueGrey;
    }
  }
}