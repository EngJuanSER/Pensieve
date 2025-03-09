import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

import '../../models/document.dart';
import '../../utils/file_utils.dart';
import '../../services/ai_service.dart';

class DocumentLibraryController extends ChangeNotifier {
  List<Document> documents = [];
  Box<Document>? _documentsBox;
  bool _isInitialized = false;
  
  final Map<String, bool> _processingDocuments = {};
  
  Map<String, int> tagStats = {};
  Map<String, int> typeStats = {};
  int totalDocuments = 0;
  int favoritesCount = 0;
  DateTime? lastAdded;
  DateTime? lastAccessed;
  
  // Filtros
  List<String> selectedTags = [];
  List<String> selectedTypes = [];
  bool showOnlyFavorites = false;
  DateTime? startDate;
  DateTime? endDate;
  String sortBy = 'fecha_agregado';
  bool ascending = false;
  bool isAddDocumentDialogOpen = false;

  DocumentLibraryController();
  
  bool get isInitialized => _isInitialized;
  
  Future<void> loadDocuments() async {
    if (_documentsBox == null) {
      await _openBox();
    } else {
      documents = _documentsBox!.values.toList();
      updateStats();
      notifyListeners();
    }
  }
  
  Future<void> _openBox() async {
    try {

/*       await Hive.deleteBoxFromDisk('documents');
 */
      _documentsBox = await Hive.openBox<Document>('documents');
      documents = _documentsBox!.values.toList();
      updateStats();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al abrir Hive Box: $e');
      
      try {
        await Hive.deleteBoxFromDisk('documents');
        debugPrint('Caja eliminada tras error. Recreando...');
        _documentsBox = await Hive.openBox<Document>('documents');
        documents = [];
        updateStats();
        _isInitialized = true;
        notifyListeners();
      } catch (e2) {
        debugPrint('Error fatal con Hive: $e2');
        documents = [];
        _isInitialized = true;
        notifyListeners();
      }
    }
  }
  
  void updateStats() {
    final allDocs = documents;
    
    totalDocuments = allDocs.length;
    favoritesCount = allDocs.where((doc) => doc.isFavorite).length;
    
    lastAdded = allDocs.isEmpty ? null : 
              allDocs.fold<DateTime?>(
                null,
                (maxDate, doc) => maxDate == null || doc.addedAt.isAfter(maxDate)
                    ? doc.addedAt
                    : maxDate
              );
              
    lastAccessed = allDocs.isEmpty ? null : 
                allDocs.fold<DateTime?>(
                  null,
                  (maxDate, doc) => doc.lastAccessed != null && 
                      (maxDate == null || doc.lastAccessed!.isAfter(maxDate))
                      ? doc.lastAccessed
                      : maxDate
                );
    
    tagStats = {};
    for (var doc in allDocs) {
      for (var tag in doc.tags) {
        tagStats[tag] = (tagStats[tag] ?? 0) + 1;
      }
    }
    
    typeStats = {};
    for (var doc in allDocs) {
      final type = doc.fileType.toLowerCase();
      typeStats[type] = (typeStats[type] ?? 0) + 1;
    }
  }
  
  List<Document> getFilteredAndSortedDocuments(String searchText) {
    return documents.where((doc) {
      bool matchesSearch = true;
      bool matchesTags = true;
      bool matchesTypes = true;
      bool matchesFavorites = true;
      bool matchesDateRange = true;

      // Búsqueda
      if (searchText.isNotEmpty) {
        matchesSearch = doc.name.toLowerCase().contains(searchText.toLowerCase()) ||
                      doc.tags.any((tag) => tag.toLowerCase().contains(searchText.toLowerCase())) ||
                      (doc.description?.toLowerCase().contains(searchText.toLowerCase()) ?? false);
      }

      // Filtro por etiquetas
      if (selectedTags.isNotEmpty) {
        matchesTags = selectedTags.every((tag) => doc.tags.contains(tag));
      }

      // Filtro por tipos de archivo
      if (selectedTypes.isNotEmpty) {
        matchesTypes = selectedTypes.contains(doc.fileType.toLowerCase());
      }

      // Filtro por favoritos
      if (showOnlyFavorites) {
        matchesFavorites = doc.isFavorite;
      }

      // Filtro por rango de fechas
      if (startDate != null) {
        matchesDateRange = doc.addedAt.isAfter(startDate!);
      }
      if (endDate != null) {
        matchesDateRange = matchesDateRange && doc.addedAt.isBefore(endDate!.add(const Duration(days: 1)));
      }

      return matchesSearch && matchesTags && matchesTypes && matchesFavorites && matchesDateRange;
    }).toList()
      ..sort((a, b) {
        switch (sortBy) {
          case 'fecha_agregado':
            return ascending ? a.addedAt.compareTo(b.addedAt) : b.addedAt.compareTo(a.addedAt);
          case 'fecha_acceso':
            final aDate = a.lastAccessed ?? a.addedAt;
            final bDate = b.lastAccessed ?? b.addedAt;
            return ascending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
          case 'nombre':
            return ascending ? a.name.toLowerCase().compareTo(b.name.toLowerCase()) 
                          : b.name.toLowerCase().compareTo(a.name.toLowerCase());
          case 'tamaño':
            return ascending ? a.fileSize.compareTo(b.fileSize) : b.fileSize.compareTo(a.fileSize);
          default:
            return 0;
        }
      });
  }
  
  Future<bool> addDocument() async {
    if (!_isInitialized) await loadDocuments();
    if (_documentsBox == null) return false;
    if (isAddDocumentDialogOpen) return false;
    
    isAddDocumentDialogOpen = true;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = path.basename(file.path);
        final fileType = path.extension(file.path).toLowerCase().replaceAll('.', '');
        final fileSize = await file.length();

        String? thumbnailPath = await FileUtils.generateThumbnail(file.path);
        
        final documentId = DateTime.now().millisecondsSinceEpoch.toString();
        
        final document = Document(
          id: documentId,
          name: fileName,
          path: file.path,
          addedAt: DateTime.now(),
          fileType: fileType,
          fileSize: fileSize,
          thumbnailPath: thumbnailPath,
          tags: [], 
          isFavorite: false,
        );
        
        await _documentsBox!.put(document.id, document);
        await loadDocuments();
        
        Future.microtask(() => generateDocumentDescription(documentId));
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al agregar documento: $e');
      return false;
    } finally {
      isAddDocumentDialogOpen = false;
    }
  }
  
  Future<bool> processDroppedFile(String filePath) async {
    if (!_isInitialized) await loadDocuments();
    if (_documentsBox == null) return false;
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }
      
      final fileName = path.basename(file.path);
      final fileType = path.extension(file.path).toLowerCase().replaceAll('.', '');
      final fileSize = await file.length();

      String? thumbnailPath = await FileUtils.generateThumbnail(file.path);
      
      final documentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final document = Document(
        id: documentId,
        name: fileName,
        path: file.path,
        addedAt: DateTime.now(),
        fileType: fileType,
        fileSize: fileSize,
        thumbnailPath: thumbnailPath,
        tags: [], 
        isFavorite: false,
      );
      
      await _documentsBox!.put(document.id, document);
      await loadDocuments();
      
      Future.microtask(() => generateDocumentDescription(documentId));
      
      return true;
    } catch (e) {
      debugPrint('Error al procesar archivo arrastrado: $e');
      return false;
    }
  }
  
  Future<void> generateDocumentDescription(String documentId) async {
    if (!_isInitialized) await loadDocuments();
    if (_documentsBox == null) return;
    
    if (_processingDocuments[documentId] == true) {
      debugPrint('Documento $documentId ya está siendo procesado');
      return;
    }
    
    _processingDocuments[documentId] = true;
    
    try {
      final docIndex = documents.indexWhere((doc) => doc.id == documentId);
      if (docIndex == -1) {
        _processingDocuments.remove(documentId);
        return;
      }
      
      final doc = documents[docIndex];
      
      if (doc.description != null && 
          doc.description!.isNotEmpty && 
          doc.description!.length > 30 &&
          doc.tags.isNotEmpty) {
        debugPrint('Documento ya tiene descripción completa y etiquetas');
        _processingDocuments.remove(documentId);
        return;
      }
      
      String description = "Documento ${doc.fileType.toUpperCase()} agregado el ${doc.addedAt.day}/${doc.addedAt.month}/${doc.addedAt.year}";
      
      final file = File(doc.path);
      if (!await file.exists()) {
        doc.description = description;
        await _documentsBox!.put(doc.id, doc);
        _processingDocuments.remove(documentId);
        return;
      }
      
      final aiService = AIService();
      
      final aiDescription = await aiService.generateDocumentDescriptionFromFile(file);
      if (aiDescription != null && aiDescription.isNotEmpty) {
        description = aiDescription;
      }
      
      if (doc.tags.isEmpty) {
        final suggestedTags = await aiService.generateDocumentTagsFromFile(file);
        if (suggestedTags != null && suggestedTags.isNotEmpty) {
          doc.tags = suggestedTags;
        } else {
          doc.tags = [
            aiService.normalizeTag(doc.fileType.toUpperCase()), 
            'Documento'
          ];
        }
      }
      
      doc.description = description;
      await _documentsBox!.put(doc.id, doc);
      await loadDocuments(); 
      
    } catch (e) {
      debugPrint('Error al generar descripción: $e');
    } finally {
      _processingDocuments.remove(documentId);
    }
  }
  
  Future<void> viewDocument(Document document) async {
    if (!_isInitialized) await loadDocuments();
    if (_documentsBox == null) return;
    
    document.lastAccessed = DateTime.now();
    await _documentsBox!.put(document.id, document);
    updateStats();
  }
  
  Future<void> toggleFavorite(String id) async {
    if (!_isInitialized) await loadDocuments();
    if (_documentsBox == null) return;
    
    final docIndex = documents.indexWhere((doc) => doc.id == id);
    if (docIndex != -1) {
      final doc = documents[docIndex];
      doc.isFavorite = !doc.isFavorite;
      await _documentsBox!.put(id, doc);
      await loadDocuments();
    }
  }
  
  Future<void> updateTags(String id, List<String> newTags) async {
    if (!_isInitialized) await loadDocuments();
    if (_documentsBox == null) return;
    
    final docIndex = documents.indexWhere((doc) => doc.id == id);
    if (docIndex != -1) {
      final doc = documents[docIndex];
      final aiService = AIService();
      doc.tags = aiService.normalizeTagList(newTags);
      await _documentsBox!.put(id, doc);
      await loadDocuments();
    }
  }
  Future<void> updateDescription(String id, String description) async {
    if (!_isInitialized) await loadDocuments();
    if (_documentsBox == null) return;
    
    final docIndex = documents.indexWhere((doc) => doc.id == id);
    if (docIndex != -1) {
      final doc = documents[docIndex];
      doc.description = description;
      await _documentsBox!.put(id, doc);
      await loadDocuments();
    }
  }
  
  Future<bool> deleteDocument(String id) async {
    if (!_isInitialized) await loadDocuments();
    if (_documentsBox == null) return false;
    
    try {
      final docIndex = documents.indexWhere((doc) => doc.id == id);
      if (docIndex == -1) return false;
      
      await _documentsBox!.delete(id);
      await loadDocuments();
      return true;
    } catch (e) {
      debugPrint('Error al eliminar documento: $e');
      return false;
    }
  }

  List<String> getAvailableTags() {
    return documents.fold<Set<String>>(
      {}, (set, doc) => set..addAll(doc.tags)
    ).toList();
  }
  
  List<String> getAvailableTypes() {
    return documents.map((doc) => doc.fileType.toLowerCase()).toSet().toList();
  }
  
  void updateFilter({
    List<String>? tags,
    List<String>? types,
    bool? onlyFavorites,
    DateTime? start,
    DateTime? end,
    String? sort,
    bool? asc,
  }) {
    if (tags != null) selectedTags = tags;
    if (types != null) selectedTypes = types;
    if (onlyFavorites != null) showOnlyFavorites = onlyFavorites;
    if (start != null) startDate = start;
    if (end != null) endDate = end;
    if (sort != null) sortBy = sort;
    if (asc != null) ascending = asc;
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    _processingDocuments.clear();
    super.dispose();
  }
}