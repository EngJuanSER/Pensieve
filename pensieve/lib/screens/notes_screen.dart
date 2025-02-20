import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/note.dart';
import '../components/note_card.dart';
import '../components/note_list.dart';
import 'dart:async';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  NotesScreenState createState() => NotesScreenState();
}

class NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];
  late Box<Note> _notesBox;
  String _searchText = '';
  String _sortOrder = 'fecha_creacion';
  bool _isListView = false;
  int _crossAxisCount = 5;
  bool _showOnlyFavorites = false;
  String _selectedTag = '';
  Set<String> _allTags = {};

  @override
  void initState() {
    super.initState();
//   _clearAndOpenBox();
    _openBox();
    _updateAllTags();
    Image.asset('assets/images/lines_pattern.jpg')
          .image
          .resolve(const ImageConfiguration())
          .addListener(
            ImageStreamListener((_, __) {
              if (mounted) {
                setState(() {});
              }
            }),
          );
  }

/*   Future<void> _clearAndOpenBox() async {
    await Hive.deleteBoxFromDisk('notes');
    _notesBox = await Hive.openBox<Note>('notes');
    _loadNotes();
  } */

  void _toggleFavorite(String id) {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final note = notes[noteIndex];
      note.isFavorite = !note.isFavorite;
      _notesBox.put(id, note);
      setState(() {}); // Trigger rebuild
    }
  }

  void _updateAllTags() {
    _allTags = notes.fold<Set<String>>({}, (set, note) {
      set.addAll(note.tags);
      return set;
    });
  }

  void _updateTags(String id, List<String> newTags) {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final note = notes[noteIndex];
      note.tags = newTags;
      _notesBox.put(id, note);
      setState(() {}); // Trigger rebuild
    }
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

  void _addNote({Color? selectedColor}) {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '',
      backgroundColor: selectedColor?.value ?? Colors.yellow.value,
      createdAt: DateTime.now(),
      fontSize: 16.0,
      textColor: Colors.black.value,
    );
    _notesBox.put(newNote.id, newNote);
    setState(() {
      notes.add(newNote);
    });
  }

  void _updateNote(String id, String content, {List<String>? imageUrls}) {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final note = notes[noteIndex];
      note.content = content;
      note.modifiedAt = DateTime.now(); 
      if (imageUrls != null) {
      note.imageUrls = imageUrls;
     }
      _notesBox.put(id, note); 
    }
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
          const SnackBar(
            content: Text('Nota eliminada correctamente'),
            duration: Duration(seconds: 2),
          ),
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


  void _changeColor(String id, Color color) {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final note = notes[noteIndex];
      note.backgroundColor = color.value;
      _notesBox.put(id, note); // Update in Hive
      setState(() {}); // Trigger rebuild
    }
  }

  void _changeFontSize(String id, double fontSize) {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final note = notes[noteIndex];
      note.fontSize = fontSize;
      _notesBox.put(id, note); // Update in Hive
        setState(() {}); // Trigger rebuild
    }
  }

  void _changeTextColor(String id, Color color) {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final note = notes[noteIndex];
      note.textColor = color.value;
      _notesBox.put(id, note); // Update in Hive
      setState(() {}); // Trigger rebuild
    }
  }

  List<Note> _getFilteredNotes() {
    List<Note> filteredNotes = notes;

    if (_showOnlyFavorites) {
      filteredNotes = filteredNotes.where((note) => note.isFavorite).toList();
    }

    if (_selectedTag.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) => 
        note.tags.contains(_selectedTag)
      ).toList();
    }

    if (_searchText.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) =>
        note.content.toLowerCase().contains(_searchText.toLowerCase()) ||
        note.tags.any((tag) => tag.toLowerCase().contains(_searchText.toLowerCase()))
      ).toList();
    }

    return filteredNotes;
  }

  List<Note> _getFilteredAndSortedNotes() {
    List<Note> filteredNotes = _getFilteredNotes();

    switch (_sortOrder) {
      case 'fecha_creacion':
        filteredNotes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'fecha_modificacion':
        filteredNotes.sort((a, b) => (b.modifiedAt ?? b.createdAt).compareTo(a.modifiedAt ?? a.createdAt));
      break;
      case 'alfabeticamente':
        filteredNotes.sort((a, b) => a.content.toLowerCase().compareTo(b.content.toLowerCase()));
        break;
      default:
        filteredNotes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return filteredNotes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas'),
        actions: [
          // Filtro de favoritos
          IconButton(
            icon: Icon(
              _showOnlyFavorites ? Icons.star : Icons.star_border,
              color: _showOnlyFavorites ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() {
                _showOnlyFavorites = !_showOnlyFavorites;
              });
            },
          ),
          // Menú de etiquetas
          PopupMenuButton<String>(
            icon: const Icon(Icons.label),
            onSelected: (String tag) {
              setState(() {
                _selectedTag = tag == _selectedTag ? '' : tag;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: '',
                child: Text('Todas las notas'),
              ),
              ..._allTags.map((tag) => PopupMenuItem<String>(
                value: tag,
                child: Row(
                  children: [
                    Icon(
                      Icons.label,
                      color: _selectedTag == tag ? Colors.blue : null,
                    ),
                    const SizedBox(width: 8),
                    Text(tag),
                  ],
                ),
              )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar notas...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchText = value;
                        });
                      },
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort),
                    onSelected: (String value) {
                      setState(() {
                        _sortOrder = value;
                      });
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'fecha_creacion',
                        child: Text('Fecha de creación'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'fecha_modificacion',
                        child: Text('Fecha de modificación'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'alfabeticamente',
                        child: Text('Alfabéticamente'),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(_isListView ? Icons.grid_view : Icons.list),
                    onPressed: () {
                      setState(() {
                        _isListView = !_isListView;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (!_isListView)
              Slider(
                value: _crossAxisCount.toDouble(),
                min: 2,
                max: 8,
                divisions: 6,
                label: 'Columnas: $_crossAxisCount',
                onChanged: (value) {
                  setState(() {
                    _crossAxisCount = value.toInt();
                  });
                },
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
              ? ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _getFilteredAndSortedNotes().length,
                itemBuilder: (context, index) {
                  final note = _getFilteredAndSortedNotes()[index];
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
              )
              : GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: _getFilteredAndSortedNotes().length,
                itemBuilder: (context, index) {
                  final note = _getFilteredAndSortedNotes()[index];
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
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "addColor",
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  Color selectedColor = Colors.yellow;
                  return AlertDialog(
                    title: const Text('Selecciona un color'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: selectedColor,
                        onColorChanged: (color) {
                          selectedColor = color;
                        },
                      ),
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        child: const Text('Cancelar'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        child: const Text('Aceptar'),
                        onPressed: () {
                          _addNote(selectedColor: selectedColor);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            tooltip: 'Añadir nota',
            child: const Icon(Icons.add),
          ),
        ],
      ),
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
            ElevatedButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Eliminar'),
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

  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }
}
