import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/note.dart';
import '../components/note_card.dart';
import '../components/note_list.dart';
import '../components/filter_bar.dart';
import '../components/note_header.dart';
import '../components/note_list_header.dart';
import '../components/theme_toggle_button.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  NotesScreenState createState() => NotesScreenState();
}

class NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];
  late Box<Note> _notesBox;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  FocusNode? _rootFocusNode;
  List<String> _selectedTags = [];
  bool _showOnlyFavorites = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'fecha_creacion';
  bool _ascending = true;
  bool _isListView = false;
  int _crossAxisCount = 3;
  Map<String, int> _tagStats = {};
  int _totalNotes = 0;
  int _favoritesCount = 0;
  DateTime? _lastModified;
  bool _isAddNoteDialogOpen = false;
  final Map<String, GlobalKey<NoteHeaderState>> _noteHeaderKeys = {};
  final Map<String, GlobalKey<NoteListHeaderState>> _noteListHeaderKeys = {};
  String? _focusedNoteId;

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
                _addNote();
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

    Image.asset('assets/images/lines_pattern.jpg')
        .image
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((_, __) {
            if (mounted) setState(() {});
          }),
        );
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyN && 
          HardwareKeyboard.instance.isControlPressed) {
        _addNote();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyF && 
          HardwareKeyboard.instance.isControlPressed) {
        FocusScope.of(context).requestFocus(_searchFocusNode);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyE && 
          HardwareKeyboard.instance.isControlPressed &&
          _focusedNoteId != null) {
        final headerKey = _noteHeaderKeys[_focusedNoteId];
        if (headerKey?.currentState != null) {
          headerKey!.currentState!.showOptionsMenu();
        }
        return true;
      }
    }
    return false;
  }

  void _onNoteFocusChanged(String noteId, bool hasFocus) {
    if (hasFocus) {
      setState(() {
        _focusedNoteId = noteId;
      });
    } else if (_focusedNoteId == noteId) {
      setState(() {
        _focusedNoteId = null;
      });
    }
  }

  Future<void> _openBox() async {
    _notesBox = await Hive.openBox<Note>('notes');
    _loadNotes();
  }

  void _updateStats() {
    final allNotes = _notesBox.values.toList();
    setState(() {
      _totalNotes = allNotes.length;
      _favoritesCount = allNotes.where((note) => note.isFavorite).length;
      _lastModified = allNotes.fold<DateTime?>(
        null,
        (maxDate, note) => maxDate == null || (note.modifiedAt ?? note.createdAt).isAfter(maxDate)
            ? (note.modifiedAt ?? note.createdAt)
            : maxDate
      );
      
      _tagStats = {};
      for (var note in allNotes) {
        for (var tag in note.tags) {
          _tagStats[tag] = (_tagStats[tag] ?? 0) + 1;
        }
      }
    });
  }

  Future<void> _loadNotes() async {
    setState(() {
      notes = _notesBox.values.toList();
    });
    _updateStats();
  }

  List<Note> _getFilteredAndSortedNotes() {
    return List<Note>.from(notes).where((note) {
      bool matchesSearch = true;
      bool matchesTags = true;
      bool matchesFavorites = true;
      bool matchesDateRange = true;

      if (_searchController.text.isNotEmpty) {
        matchesSearch = note.content.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            note.tags.any((tag) => tag.toLowerCase().contains(_searchController.text.toLowerCase()));
      }

      if (_selectedTags.isNotEmpty) {
        matchesTags = _selectedTags.every((tag) => note.tags.contains(tag));
      }

      if (_showOnlyFavorites) {
        matchesFavorites = note.isFavorite;
      }

      if (_startDate != null) {
        matchesDateRange = note.createdAt.isAfter(_startDate!);
      }
      if (_endDate != null) {
        matchesDateRange = matchesDateRange && note.createdAt.isBefore(_endDate!);
      }

      return matchesSearch && matchesTags && matchesFavorites && matchesDateRange;
    }).toList()
      ..sort((a, b) {
        switch (_sortBy) {
          case 'fecha_creacion':
            return _ascending
                ? a.createdAt.compareTo(b.createdAt)
                : b.createdAt.compareTo(a.createdAt);
          case 'fecha_modificacion':
            final aDate = a.modifiedAt ?? a.createdAt;
            final bDate = b.modifiedAt ?? b.createdAt;
            return _ascending
                ? aDate.compareTo(bDate)
                : bDate.compareTo(aDate);
          case 'alfabeticamente':
            return _ascending
                ? a.content.toLowerCase().compareTo(b.content.toLowerCase())
                : b.content.toLowerCase().compareTo(a.content.toLowerCase());
          default:
            return 0;
        }
      });
  }

  void _addNote() {
    if (_isAddNoteDialogOpen) return;
    Color selectedColor = Colors.yellow;
    _isAddNoteDialogOpen = true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona un color para la nota'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (color) => selectedColor = color,
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () {
              _isAddNoteDialogOpen = false;
            },          
          ),
          TextButton(
            child: const Text('Crear'),
            onPressed: () {
              _isAddNoteDialogOpen = false;
              Navigator.of(context).pop();
              _createNote(selectedColor);
            },
          ),
        ],
      ),
    ).then((_) {
      _isAddNoteDialogOpen = false;
    });
  }

  void _createNote(Color color) async {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '',
      backgroundColor: color.value,
      createdAt: DateTime.now(),
      fontSize: 16.0,
      textColor: Colors.black.value,
    );
    await _notesBox.put(newNote.id, newNote);
    if (mounted) {
      setState(() {
        notes = _notesBox.values.toList();
        _updateStats();
      });
    }
  }

  void _updateNote(String id, String content, {List<String>? imageUrls}) async {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final note = notes[noteIndex];
      note.content = content;
      note.modifiedAt = DateTime.now();
      if (imageUrls != null) {
        note.imageUrls = imageUrls;
      }
      await _notesBox.put(id, note);
      if (mounted) {
        setState(() {
          notes[noteIndex] = note;
          _updateStats();
        });
      }
    }
  }

  void _toggleFavorite(String id) {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final note = notes[noteIndex];
      note.isFavorite = !note.isFavorite;
      _notesBox.put(id, note);
      setState(() {
        _updateStats();
      });
    }
  }

  void _updateTags(String id, List<String> newTags) {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final note = notes[noteIndex];
      note.tags = newTags;
      _notesBox.put(id, note);
      setState(() {
        _updateStats();
      });
    }
  }

  void _changeColor(String id, Color color) {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final note = notes[noteIndex];
      note.backgroundColor = color.value;
      _notesBox.put(id, note);
      setState(() {});
    }
  }

  void _changeTextColor(String id, Color color) {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final note = notes[noteIndex];
      note.textColor = color.value;
      _notesBox.put(id, note);
      setState(() {});
    }
  }

  void _changeFontSize(String id, double fontSize) {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final note = notes[noteIndex];
      note.fontSize = fontSize;
      _notesBox.put(id, note);
      setState(() {});
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
            title: const Text('Notas'),
            actions: [
              const ThemeToggleButton(),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showStats(context),
              ),
            ],
          ),
          body: Column(
            children: [
              FilterBar(
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                selectedTags: _selectedTags,
                availableTags: notes.fold<Set<String>>(
                  {}, (set, note) => set..addAll(note.tags)
                ).toList(),
                showOnlyFavorites: _showOnlyFavorites,
                startDate: _startDate,
                endDate: _endDate,
                sortBy: _sortBy,
                ascending: _ascending,
                onSearch: (value) => setState(() {}),
                onTagsChanged: (tags) => setState(() => _selectedTags = tags),
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
                                value: _crossAxisCount.toDouble(),
                                min: 1,
                                max: 5,
                                divisions: 4,
                                label: '$_crossAxisCount',
                                onChanged: (value) => setState(() => 
                                  _crossAxisCount = value.toInt()
                                ),
                              ),
                            ),
                            Text('$_crossAxisCount'),
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
                    ? _buildNoteList()
                    : _buildNoteGrid(),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addNote(),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteList() {
    final filteredNotes = _getFilteredAndSortedNotes();
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];
        if (!_noteListHeaderKeys.containsKey(note.id)) {
          _noteListHeaderKeys[note.id] = GlobalKey<NoteListHeaderState>();
        }
        return NoteListItem(
          note: note,
          headerKey: _noteListHeaderKeys[note.id],
          onFocusChanged: (hasFocus) => _onNoteFocusChanged(note.id, hasFocus),
          updateNote: _updateNote,
          changeColor: _changeColor,
          changeFontSize: _changeFontSize,
          changeTextColor: _changeTextColor,
          showDeleteConfirmationDialog: _showDeleteConfirmationDialog,
          toggleFavorite: _toggleFavorite,
          updateTags: _updateTags,
        );
      },
    );
  }

  Widget _buildNoteGrid() {
    final filteredNotes = _getFilteredAndSortedNotes();
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];
        if (!_noteHeaderKeys.containsKey(note.id)) {
          _noteHeaderKeys[note.id] = GlobalKey<NoteHeaderState>();
        }
        return NoteCard(
          note: note,
          headerKey: _noteHeaderKeys[note.id],
          onFocusChanged: (hasFocus) => _onNoteFocusChanged(note.id, hasFocus),
          updateNote: _updateNote,
          changeColor: _changeColor,
          changeFontSize: _changeFontSize,
          changeTextColor: _changeTextColor,
          showDeleteConfirmationDialog: _showDeleteConfirmationDialog,
          toggleFavorite: _toggleFavorite,
          updateTags: _updateTags,
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar nota'),
          content: const Text('¿Estás seguro de que quieres eliminar esta nota?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Eliminar'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                _deleteNote(id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNote(String id) async {
    try {
      final noteToDelete = notes.firstWhere((note) => note.id == id);
      await _notesBox.delete(noteToDelete.id);
      setState(() {
        _updateStats();
        notes = notes.where((note) => note.id != id).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota eliminada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar la nota'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStats(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total de notas: $_totalNotes'),
            Text('Notas favoritas: $_favoritesCount'),
            if (_lastModified != null)
              Text('Última modificación: ${_lastModified!.toLocal()}'),
            const Divider(),
            const Text('Notas por etiqueta:'),
            ...(_tagStats.entries
              .map((e) => Text('${e.key}: ${e.value}'))
              .toList()
            ),
          ],
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
    _noteHeaderKeys.clear();
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