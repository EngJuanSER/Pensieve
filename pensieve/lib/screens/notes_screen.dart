import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/note.dart';
import '../components/note_card.dart';
import '../components/note_list.dart';
import '../components/filter_bar.dart';
import 'dart:async';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  NotesScreenState createState() => NotesScreenState();
}

class NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];
  late Box<Note> _notesBox;
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedTags = [];
  bool _showOnlyFavorites = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'fecha_creacion';
  bool _ascending = true;
  bool _isListView = false;
  int _crossAxisCount = 3;

  @override
  void initState() {
    super.initState();
    _openBox();
    Image.asset('assets/images/lines_pattern.jpg')
        .image
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((_, __) {
            if (mounted) setState(() {});
          }),
        );
  }

  Future<void> _openBox() async {
    _notesBox = await Hive.openBox<Note>('notes');
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      notes = _notesBox.values.toList();
    });
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
    Color selectedColor = Colors.yellow;
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Crear'),
            onPressed: () {
              Navigator.of(context).pop();
              _createNote(selectedColor);
            },
          ),
        ],
      ),
    );
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
      setState(() {});
    }
  }

  void _updateTags(String id, List<String> newTags) {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final note = notes[noteIndex];
      note.tags = newTags;
      _notesBox.put(id, note);
      setState(() {});
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas'),
      ),
      body: Column(
        children: [
          FilterBar(
            searchController: _searchController,
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
    );
  }

  Widget _buildNoteList() {
    final filteredNotes = _getFilteredAndSortedNotes();
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];
        return NoteListItem(
          note: note,
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
        return NoteCard(
          note: note,
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

  @override
  void dispose() {
    _searchController.dispose();
    Hive.close();
    super.dispose();
  }
}