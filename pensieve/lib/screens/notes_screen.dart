import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/note.dart';
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

  @override
  void initState() {
    super.initState();
    _openBox();
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

  void _updateNote(String id, String content) {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final note = notes[noteIndex];
      note.content = content;
      _notesBox.put(id, note); // Update in Hive
    }
  }

  Future<void> _deleteNote(String id) async {
    try {
      final noteToDelete = notes.firstWhere((note) => note.id == id);
      
      // Eliminar de Hive
      await _notesBox.delete(noteToDelete.id);
      
      // Actualizar la lista local
      setState(() {
        notes = notes.where((note) => note.id != id).toList();
      });
      
      // Opcional: Mostrar confirmación
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
    if (_searchText.isEmpty) {
      return notes;
    } else {
      return notes
          .where((note) =>
              note.content.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
          padding: const EdgeInsets.all(16.0),
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
        // Lista de notas filtradas
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              itemCount: _getFilteredNotes().length,
              itemBuilder: (context, index) {
                  final note = _getFilteredNotes()[index];
                  String lastContent = note.content;
                  Timer? saveTimer;
                  final TextEditingController textController = TextEditingController(text: note.content);
                
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    color: Color(note.backgroundColor),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: TextField(
                            controller: textController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Escribe algo...',
                            ),
                              onChanged: (text) {
                              if (text != lastContent) {
                                lastContent = text;
                                if (saveTimer?.isActive ?? false) {
                                  saveTimer?.cancel();
                                }
                                saveTimer = Timer(const Duration(seconds: 1), () {
                                  _updateNote(note.id, text);
                                });
                              }
                            },                     
                            maxLines: null,
                            style: TextStyle(fontSize: note.fontSize, color: Color(note.textColor)),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.color_lens),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Selecciona un color'),
                                        content: SingleChildScrollView(
                                          child: ColorPicker(
                                            pickerColor: Color(note.backgroundColor),
                                            onColorChanged: (color) {
                                              _changeColor(note.id, color);
                                            },
                                          ),
                                        ),
                                        actions: <Widget>[
                                          ElevatedButton(
                                            child: const Text('Cerrar'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_size),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return _FontSizeDialog(
                                        initialFontSize: note.fontSize,
                                        onFontSizeChanged: (fontSize) {
                                          _changeFontSize(note.id, fontSize);
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_color_text),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Selecciona un color de texto'),
                                        content: SingleChildScrollView(
                                          child: ColorPicker(
                                            pickerColor: Color(note.textColor),
                                            onColorChanged: (color) {
                                              _changeTextColor(note.id, color);
                                            },
                                          ),
                                        ),
                                        actions: <Widget>[
                                          ElevatedButton(
                                            child: const Text('Cerrar'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _showDeleteConfirmationDialog(context, note.id),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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

class _FontSizeDialog extends StatefulWidget {
  final Function(double) onFontSizeChanged;
  final double initialFontSize;

  const _FontSizeDialog({
    required this.onFontSizeChanged,
    required this.initialFontSize,
  });

  @override
  State<_FontSizeDialog> createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<_FontSizeDialog> {
  late double currentFontSize;

  @override
  void initState() {
    super.initState();
    currentFontSize = widget.initialFontSize;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajustar tamaño de fuente'),
      content: SizedBox(
        height: 100,
        child: Column(
          children: [
            Text('Tamaño actual: ${currentFontSize.toStringAsFixed(1)}'),
            Slider(
              value: currentFontSize,
              min: 8.0,
              max: 50.0,
              divisions: 42,
              label: currentFontSize.toStringAsFixed(1),
              onChanged: (double value) {
                setState(() {
                  currentFontSize = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('Aceptar'),
          onPressed: () {
            widget.onFontSizeChanged(currentFontSize);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}