import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:async';
import '../models/document.dart';
import '../components/theme_toggle_button.dart';
import '../components/document_card.dart';
import '../components/document_list_item.dart';
import '../components/document_filter_bar.dart';
import '../components/document_details_dialog.dart';
import '../utils/file_utils.dart';

class DocumentLibraryScreen extends StatefulWidget {
  const DocumentLibraryScreen({super.key});

  @override
  DocumentLibraryScreenState createState() => DocumentLibraryScreenState();
}

class DocumentLibraryScreenState extends State<DocumentLibraryScreen> {
  List<Document> documents = [];
  late Box<Document> _documentsBox;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  FocusNode? _rootFocusNode;
  
  List<String> _selectedTags = [];
  List<String> _selectedTypes = [];
  bool _showOnlyFavorites = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'fecha_agregado';
  bool _ascending = false;
  int _gridColumns = 4;
  bool _isListView = false;
  bool _isAddDocumentDialogOpen = false;
  Map<String, int> _tagStats = {};
  Map<String, int> _typeStats = {};
  int _totalDocuments = 0;
  int _favoritesCount = 0;
  DateTime? _lastAdded;
  DateTime? _lastAccessed;

  @override
  void initState() {
    super.initState();
    _openBox();
    _rootFocusNode = FocusNode(
      onKey: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.keyN && 
              HardwareKeyboard.instance.isControlPressed) {
            if (mounted) {
              _addDocument();
            }
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyF && 
              HardwareKeyboard.instance.isControlPressed) {
            if (mounted) {
              _searchFocusNode.requestFocus();
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
    ServicesBinding.instance.keyboard.addHandler(_handleKeyPress);
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyN && 
          HardwareKeyboard.instance.isControlPressed) {
        _addDocument();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyF && 
          HardwareKeyboard.instance.isControlPressed) {
        FocusScope.of(context).requestFocus(_searchFocusNode);
        return true;
      }
    }
    return false;
  }

  Future<void> _openBox() async {
    _documentsBox = await Hive.openBox<Document>('documents');
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      documents = _documentsBox.values.toList();
    });
    _updateStats();
  }
  
  void _updateStats() {
    final allDocs = _documentsBox.values.toList();
    
    setState(() {
      _totalDocuments = allDocs.length;
      _favoritesCount = allDocs.where((doc) => doc.isFavorite).length;
      
      _lastAdded = allDocs.isEmpty ? null : 
                   allDocs.fold<DateTime?>(
                     null,
                     (maxDate, doc) => maxDate == null || doc.addedAt.isAfter(maxDate)
                         ? doc.addedAt
                         : maxDate
                   );
                   
      _lastAccessed = allDocs.isEmpty ? null : 
                     allDocs.fold<DateTime?>(
                       null,
                       (maxDate, doc) => doc.lastAccessed != null && 
                           (maxDate == null || doc.lastAccessed!.isAfter(maxDate))
                           ? doc.lastAccessed
                           : maxDate
                     );
      
      _tagStats = {};
      for (var doc in allDocs) {
        for (var tag in doc.tags) {
          _tagStats[tag] = (_tagStats[tag] ?? 0) + 1;
        }
      }
      
      _typeStats = {};
      for (var doc in allDocs) {
        final type = doc.fileType.toLowerCase();
        _typeStats[type] = (_typeStats[type] ?? 0) + 1;
      }
    });
  }

  List<Document> _getFilteredAndSortedDocuments() {
    return documents.where((doc) {
      bool matchesSearch = true;
      bool matchesTags = true;
      bool matchesTypes = true;
      bool matchesFavorites = true;
      bool matchesDateRange = true;

      // Filtro por búsqueda de texto
      if (_searchController.text.isNotEmpty) {
        matchesSearch = doc.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                        doc.tags.any((tag) => tag.toLowerCase().contains(_searchController.text.toLowerCase())) ||
                        (doc.description?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);
      }

      // Filtro por etiquetas
      if (_selectedTags.isNotEmpty) {
        matchesTags = _selectedTags.every((tag) => doc.tags.contains(tag));
      }

      // Filtro por tipos de archivo
      if (_selectedTypes.isNotEmpty) {
        matchesTypes = _selectedTypes.contains(doc.fileType.toLowerCase());
      }

      // Filtro por favoritos
      if (_showOnlyFavorites) {
        matchesFavorites = doc.isFavorite;
      }

      // Filtro por rango de fechas
      if (_startDate != null) {
        matchesDateRange = doc.addedAt.isAfter(_startDate!);
      }
      if (_endDate != null) {
        matchesDateRange = matchesDateRange && doc.addedAt.isBefore(_endDate!.add(const Duration(days: 1)));
      }

      return matchesSearch && matchesTags && matchesTypes && matchesFavorites && matchesDateRange;
    }).toList()
      ..sort((a, b) {
        switch (_sortBy) {
          case 'fecha_agregado':
            return _ascending ? a.addedAt.compareTo(b.addedAt) : b.addedAt.compareTo(a.addedAt);
          case 'fecha_acceso':
            final aDate = a.lastAccessed ?? a.addedAt;
            final bDate = b.lastAccessed ?? b.addedAt;
            return _ascending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
          case 'nombre':
            return _ascending ? a.name.toLowerCase().compareTo(b.name.toLowerCase()) 
                              : b.name.toLowerCase().compareTo(a.name.toLowerCase());
          case 'tamaño':
            return _ascending ? a.fileSize.compareTo(b.fileSize) : b.fileSize.compareTo(a.fileSize);
          default:
            return 0;
        }
      });
  }

  void _addDocument() async {
    if (_isAddDocumentDialogOpen) return;
    
    _isAddDocumentDialogOpen = true;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = path.basename(file.path);
        final fileType = path.extension(file.path).toLowerCase().replaceAll('.', '');
        final fileSize = await file.length();

        String? thumbnailPath = await FileUtils.generateThumbnail(file.path);
        
        final document = Document(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: fileName,
          path: file.path,
          addedAt: DateTime.now(),
          fileType: fileType,
          fileSize: fileSize,
          thumbnailPath: thumbnailPath,
        );
        
        await _documentsBox.put(document.id, document);
        
        if (mounted) {
          setState(() {
            documents = _documentsBox.values.toList();
            _updateStats();
          });
          
          _generateDocumentDescription(document.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar documento: $e')),
        );
      }
    } finally {
      _isAddDocumentDialogOpen = false;
    }
  }

  Future<void> _processDroppedFile(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = path.basename(file.path);
      final fileType = path.extension(file.path).toLowerCase().replaceAll('.', '');
      final fileSize = await file.length();

      String? thumbnailPath = await FileUtils.generateThumbnail(file.path);
      
      final document = Document(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        path: file.path,
        addedAt: DateTime.now(),
        fileType: fileType,
        fileSize: fileSize,
        thumbnailPath: thumbnailPath,
      );
      
      await _documentsBox.put(document.id, document);
      
      if (mounted) {
        setState(() {
          documents = _documentsBox.values.toList();
          _updateStats();
        });
        
        _generateDocumentDescription(document.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Documento "$fileName" agregado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el archivo: $e')),
        );
      }
    }
  }

  Future<void> _generateDocumentDescription(String documentId) async {
    final docIndex = documents.indexWhere((doc) => doc.id == documentId);
    if (docIndex != -1) {
      final doc = documents[docIndex];
      doc.description = "Documento ${doc.fileType.toUpperCase()} agregado el ${doc.addedAt.day}/${doc.addedAt.month}/${doc.addedAt.year}";
      await _documentsBox.put(doc.id, doc);
      
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _showDocumentDetails(Document document) async {
    document.lastAccessed = DateTime.now();
    await _documentsBox.put(document.id, document);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => DocumentDetailsDialog(
          document: document,
          onOpen: () => FileUtils.openFile(document.path),
          onToggleFavorite: () => _toggleFavorite(document.id),
          onUpdateTags: (tags) => _updateTags(document.id, tags),
          onDelete: () => _confirmDeleteDocument(context, document.id),
          onUpdateDescription: (description) => _updateDescription(document.id, description),
        ),
      );
    }
  }
  
  Future<void> _toggleFavorite(String id) async {
    final docIndex = documents.indexWhere((doc) => doc.id == id);
    if (docIndex != -1) {
      final doc = documents[docIndex];
      doc.isFavorite = !doc.isFavorite;
      await _documentsBox.put(id, doc);
      
      if (mounted) {
        setState(() {
          _updateStats();
        });
      }
    }
  }

  Future<void> _updateTags(String id, List<String> newTags) async {
    final docIndex = documents.indexWhere((doc) => doc.id == id);
    if (docIndex != -1) {
      final doc = documents[docIndex];
      doc.tags = newTags;
      await _documentsBox.put(id, doc);
      
      if (mounted) {
        setState(() {
          _updateStats();
        });
      }
    }
  }
  
  Future<void> _updateDescription(String id, String description) async {
    final docIndex = documents.indexWhere((doc) => doc.id == id);
    if (docIndex != -1) {
      final doc = documents[docIndex];
      doc.description = description;
      await _documentsBox.put(id, doc);
      
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _confirmDeleteDocument(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: const Text('¿Estás seguro de que quieres eliminar este documento? Esta acción no elimina el archivo original.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
            onPressed: () {
              Navigator.of(dialogContext).pop(); 
              _deleteDocument(id);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDocument(String id) async {
    try {
      final docToDelete = documents.firstWhere((doc) => doc.id == id);
      await _documentsBox.put(id, docToDelete); 
      
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      await _documentsBox.delete(id);
      
      if (mounted) {
        setState(() {
          documents = documents.where((doc) => doc.id != id).toList();
          _updateStats();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento eliminado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar documento: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _rootFocusNode,
      autofocus: true,
      child: GestureDetector(
        onTap: () {
          if (mounted) {
            _rootFocusNode?.requestFocus();
            _searchFocusNode.unfocus();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Biblioteca de Documentos'),
            actions: [
              const ThemeToggleButton(),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showStats(context),
              ),
            ],
          ),
          body: DropTarget(
          onDragDone: (details) async {
            for (final file in details.files) {
              await _processDroppedFile(file.path);
            }
          },
          onDragEntered: (details) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Suelta para agregar documentos'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
          child: Column(
              children: [
                DocumentFilterBar(
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  selectedTags: _selectedTags,
                  availableTags: documents.fold<Set<String>>(
                    {}, (set, doc) => set..addAll(doc.tags)
                  ).toList(),
                  selectedTypes: _selectedTypes,
                  availableTypes: documents.map((doc) => doc.fileType.toLowerCase()).toSet().toList(),
                  showOnlyFavorites: _showOnlyFavorites,
                  startDate: _startDate,
                  endDate: _endDate,
                  sortBy: _sortBy,
                  ascending: _ascending,
                  onSearch: (value) => setState(() {}),
                  onTagsChanged: (tags) => setState(() => _selectedTags = tags),
                  onTypesChanged: (types) => setState(() => _selectedTypes = types),
                  onFavoritesChanged: (value) => setState(() => _showOnlyFavorites = value),
                  onStartDateChanged: (date) => setState(() => _startDate = date),
                  onEndDateChanged: (date) => setState(() => _endDate = date),
                  onSortChanged: (sortBy, ascending) => setState(() {
                    _sortBy = sortBy;
                    _ascending = ascending;
                  }),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(_isListView ? Icons.grid_view : Icons.list),
                        onPressed: () => setState(() => _isListView = !_isListView),
                      ),
                      if (!_isListView)
                        Expanded(
                          child: Row(
                            children: [
                              const Text('Columnas: '),
                              Expanded(
                                child: Slider(
                                  value: _gridColumns.toDouble(),
                                  min: 2,
                                  max: 6,
                                  divisions: 4,
                                  label: '$_gridColumns',
                                  onChanged: (value) => setState(() => _gridColumns = value.toInt()),
                                ),
                              ),
                              Text('$_gridColumns'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    },
                    child: _isListView
                      ? _buildDocumentList()
                      : _buildDocumentGrid(),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addDocument,
            tooltip: 'Agregar documento',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentGrid() {
    final filteredDocuments = _getFilteredAndSortedDocuments();
    
    if (filteredDocuments.isEmpty) {
      return const Center(
        child: Text(
          'No hay documentos disponibles.\nAgrega documentos con el botón +',
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridColumns,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.75, 
      ),
      itemCount: filteredDocuments.length,
      itemBuilder: (context, index) {
        final document = filteredDocuments[index];
        return DocumentCard(
          document: document,
          onTap: () => _showDocumentDetails(document),
          onFavoriteToggle: () => _toggleFavorite(document.id),
          onDelete: () => _deleteDocument(document.id),
        );
      },
    );
  }

  Widget _buildDocumentList() {
    final filteredDocuments = _getFilteredAndSortedDocuments();
    
    if (filteredDocuments.isEmpty) {
      return const Center(
        child: Text(
          'No hay documentos disponibles.\nAgrega documentos con el botón +',
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredDocuments.length,
      itemBuilder: (context, index) {
        final document = filteredDocuments[index];
        return DocumentListItem(
          document: document,
          onTap: () => _showDocumentDetails(document),
          onFavoriteToggle: () => _toggleFavorite(document.id),
          onDelete: () => _deleteDocument(document.id),
        );
      },
    );
  }

  void _showStats(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas de la Biblioteca'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total de documentos: $_totalDocuments'),
              Text('Documentos favoritos: $_favoritesCount'),
              if (_lastAdded != null)
                Text('Último documento agregado: ${_lastAdded!.day}/${_lastAdded!.month}/${_lastAdded!.year}'),
              if (_lastAccessed != null)
                Text('Último documento accedido: ${_lastAccessed!.day}/${_lastAccessed!.month}/${_lastAccessed!.year}'),
              
              if (_typeStats.isNotEmpty) ...[
                const Divider(),
                const Text('Documentos por tipo:'),
                ..._typeStats.entries.map((e) => Text('${e.key.toUpperCase()}: ${e.value}')),
              ],
              
              if (_tagStats.isNotEmpty) ...[
                const Divider(),
                const Text('Documentos por etiqueta:'),
                ..._tagStats.entries.map((e) => Text('${e.key}: ${e.value}')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (mounted) {
      _searchController.dispose();
      _searchFocusNode.unfocus();
      _searchFocusNode.dispose();
      
      if (_rootFocusNode != null) {
        _rootFocusNode!.unfocus();
        ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);
        _rootFocusNode!.dispose();
      }
    }
    super.dispose();
  }
}