import 'package:flutter/material.dart';
import '../models/note.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  NotesScreenState createState() => NotesScreenState();
}

class NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
  }

  void _addNote() {
    setState(() {
      notes.add(
        Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '',
          backgroundColor: Colors.yellow,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  void _updateNote(String id, String content) {
    setState(() {
      final noteIndex = notes.indexWhere((note) => note.id == id);
      if (noteIndex != -1) {
        notes[noteIndex].content = content;
      }
    });
  }

  void deleteNote(String id) {
    setState(() {
      notes.removeWhere((note) => note.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return Container(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: note.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Escribe algo...',
                  ),
                  controller: TextEditingController(text: note.content),
                  onChanged: (text) => _updateNote(note.id, text),
                  maxLines: null,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        tooltip: 'Añadir nota',
        child: const Icon(Icons.add),
      ),
    );
  }
}