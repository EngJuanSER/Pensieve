import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as path;
import '../models/document.dart';
import '../components/controllers/document_library_controller.dart';
import '../components/theme_toggle_button.dart';
import '../components/document_filter_bar.dart';
import '../components/document_view_options.dart';
import '../components/document_grid.dart';
import '../components/document_list.dart';
import '../components/document_grouped.dart';
import '../components/document_details_dialog.dart';
import '../utils/file_utils.dart';

class DocumentLibraryScreen extends StatefulWidget {
  const DocumentLibraryScreen({super.key});

  @override
  DocumentLibraryScreenState createState() => DocumentLibraryScreenState();
}

class DocumentLibraryScreenState extends State<DocumentLibraryScreen> {
  final DocumentLibraryController _controller = DocumentLibraryController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  FocusNode? _rootFocusNode;
  
  String _viewMode = 'grid'; 
  int _gridColumns = 4;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _setupKeyboardHandlers();
  }

  Future<void> _initializeController() async {
    try {
      await _controller.loadDocuments();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error al inicializar el controlador de documentos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar la biblioteca de documentos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  void _setupKeyboardHandlers() {
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

  Future<void> _addDocument() async {
    final success = await _controller.addDocument();
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento agregado correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo agregar el documento')),
        );
      }
      setState(() {}); // Actualizar la UI
    }
  }

  Future<void> _processDroppedFile(String filePath) async {
    final success = await _controller.processDroppedFile(filePath);
    
    if (mounted) {
      if (success) {
        final fileName = path.basename(filePath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Documento "$fileName" agregado correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar el archivo')),
        );
      }
      setState(() {}); // Actualizar la UI
    }
  }

  void _showDocumentDetails(Document document) async {
    await _controller.viewDocument(document);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => DocumentDetailsDialog(
          document: document,
          onOpen: () => FileUtils.openFile(document.path),
          onToggleFavorite: () {
            _toggleFavorite(document.id);
            Navigator.of(context).pop();
          },
          onUpdateTags: (tags) {
            _updateTags(document.id, tags);
          },
          onDelete: () {
            Navigator.of(context).pop();
            _confirmDeleteDocument(context, document.id);
          },
          onUpdateDescription: (description) => _updateDescription(document.id, description),
        ),
      );
    }
  }
  
  Future<void> _toggleFavorite(String id) async {
    await _controller.toggleFavorite(id);
    if (mounted) setState(() {});
  }

  Future<void> _updateTags(String id, List<String> newTags) async {
    await _controller.updateTags(id, newTags);
    if (mounted) setState(() {});
  }
  
  Future<void> _updateDescription(String id, String description) async {
    await _controller.updateDescription(id, description);
    if (mounted) setState(() {});
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
    final success = await _controller.deleteDocument(id);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento eliminado correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el documento')),
        );
      }
      setState(() {}); // Actualizar la UI
    }
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
              Text('Total de documentos: ${_controller.totalDocuments}'),
              Text('Documentos favoritos: ${_controller.favoritesCount}'),
              if (_controller.lastAdded != null)
                Text('Último documento agregado: ${_controller.lastAdded!.day}/${_controller.lastAdded!.month}/${_controller.lastAdded!.year}'),
              if (_controller.lastAccessed != null)
                Text('Último documento accedido: ${_controller.lastAccessed!.day}/${_controller.lastAccessed!.month}/${_controller.lastAccessed!.year}'),
              
              if (_controller.typeStats.isNotEmpty) ...[
                const Divider(),
                const Text('Documentos por tipo:'),
                ..._controller.typeStats.entries.map((e) => Text('${e.key.toUpperCase()}: ${e.value}')),
              ],
              
              if (_controller.tagStats.isNotEmpty) ...[
                const Divider(),
                const Text('Documentos por etiqueta:'),
                ..._controller.tagStats.entries.map((e) => Text('${e.key}: ${e.value}')),
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
              setState(() => _dragging = false);
              for (final file in details.files) {
                await _processDroppedFile(file.path);
              }
            },
            onDragEntered: (details) {
              setState(() => _dragging = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Suelta para agregar documentos'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            onDragExited: (details) {
              setState(() => _dragging = false);
            },
            child: Stack(
              children: [
                Column(
                  children: [
                    // Barra de filtro
                    DocumentFilterBar(
                      searchController: _searchController,
                      searchFocusNode: _searchFocusNode,
                      selectedTags: _controller.selectedTags,
                      availableTags: _controller.getAvailableTags(),
                      selectedTypes: _controller.selectedTypes,
                      availableTypes: _controller.getAvailableTypes(),
                      showOnlyFavorites: _controller.showOnlyFavorites,
                      startDate: _controller.startDate,
                      endDate: _controller.endDate,
                      sortBy: _controller.sortBy,
                      ascending: _controller.ascending,
                      onSearch: (value) => setState(() {}),
                      onTagsChanged: (tags) {
                        _controller.updateFilter(tags: tags);
                        setState(() {});
                      },
                      onTypesChanged: (types) {
                        _controller.updateFilter(types: types);
                        setState(() {});
                      },
                      onFavoritesChanged: (value) {
                        _controller.updateFilter(onlyFavorites: value);
                        setState(() {});
                      },
                      onStartDateChanged: (date) {
                        _controller.updateFilter(start: date);
                        setState(() {});
                      },
                      onEndDateChanged: (date) {
                        _controller.updateFilter(end: date);
                        setState(() {});
                      },
                      onSortChanged: (sortBy, ascending) {
                        _controller.updateFilter(sort: sortBy, asc: ascending);
                        setState(() {});
                      },
                    ),
                    
                    // Opciones de vista
                    DocumentLibraryViewOptions(
                      viewMode: _viewMode,
                      gridColumns: _gridColumns,
                      onViewModeChanged: (mode) {
                        setState(() => _viewMode = mode);
                      },
                      onGridColumnsChanged: (columns) {
                        setState(() => _gridColumns = columns);
                      },
                    ),
                    
                    // Contenido principal
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
                        child: _buildDocumentView(),
                      ),
                    ),
                  ],
                ),
                
                // Overlay cuando se arrastra un archivo
                if (_dragging)
                  Container(
                    color: Colors.blue.withOpacity(0.2),
                    child: const Center(
                      child: Text(
                        'Suelta aquí los archivos para agregarlos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildDocumentView() {
    final filteredDocuments = _controller.getFilteredAndSortedDocuments(_searchController.text);
    
    switch (_viewMode) {
      case 'list':
        return DocumentListView(
          documents: filteredDocuments,
          onDocumentTap: _showDocumentDetails,
          onFavoriteToggle: _toggleFavorite,
          onDelete: _deleteDocument,
        );
      case 'grouped_type':
        return DocumentGroupedView(
          documents: filteredDocuments,
          groupBy: 'type',
          onDocumentTap: _showDocumentDetails,
          onFavoriteToggle: _toggleFavorite,
          onDelete: _deleteDocument,
        );
      case 'grouped_tag':
        return DocumentGroupedView(
          documents: filteredDocuments,
          groupBy: 'tag',
          onDocumentTap: _showDocumentDetails,
          onFavoriteToggle: _toggleFavorite,
          onDelete: _deleteDocument,
        );
      case 'grid':
      default:
        return DocumentGridView(
          documents: filteredDocuments,
          gridColumns: _gridColumns,
          onDocumentTap: _showDocumentDetails,
          onFavoriteToggle: _toggleFavorite,
          onDelete: _deleteDocument,
        );
    }
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