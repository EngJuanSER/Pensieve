import 'package:flutter/material.dart';

class TagManager extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onTagsChanged;
  final Color iconColor;

  const TagManager({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    required this.iconColor,
  });

  @override
  TagManagerState createState() => TagManagerState();
}

class TagManagerState extends State<TagManager> {
  final TextEditingController _tagController = TextEditingController();
  late List<String> _currentTags;

  @override
  void initState() {
    super.initState();
    _currentTags = List<String>.from(widget.tags);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 400,
      child: Column(
        children: [
          // Campo para agregar nueva etiqueta
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Nueva etiqueta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ],
            ),
          ),

          // Lista de etiquetas actuales
          Expanded(
            child: ListView.builder(
              itemCount: _currentTags.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_currentTags[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeTag(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addTag() {
    if (_tagController.text.isNotEmpty) {
      setState(() {
        _currentTags.add(_tagController.text);
        widget.onTagsChanged(_currentTags);
        _tagController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _currentTags.removeAt(index);
      widget.onTagsChanged(_currentTags);
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }
}