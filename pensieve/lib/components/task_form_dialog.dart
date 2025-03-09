import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/task.dart';
import 'tag_manager.dart';

class TaskFormDialog extends StatefulWidget {
  final Task? task;
  final Function(String title, String description, DateTime? dueDate, List<String> tags, int color) onSave;

  const TaskFormDialog({
    super.key,
    this.task,
    required this.onSave,
  });

  @override
  TaskFormDialogState createState() => TaskFormDialogState();
}

class TaskFormDialogState extends State<TaskFormDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime? _selectedDate;
  late List<String> _tags;
  late int _color;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _selectedDate = widget.task?.dueDate;
    _tags = widget.task?.tags ?? [];
    _color = widget.task?.color ?? 0xFF4CAF50; 
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.task == null ? 'Nueva Tarea' : 'Editar Tarea',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Campo de título
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 8),
                
                // Campo de descripción
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 3,
                  maxLines: 5,
                ),
                const SizedBox(height: 16),

                ListTile(
                  title: const Text('Fecha de vencimiento'),
                  trailing: _selectedDate != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _selectedDate = null),
                            )
                          ],
                        )
                      : const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 8),

                // Selector de color
                ListTile(
                  title: const Text('Color'),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(_color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () => _showColorPicker(context),
                ),
                const SizedBox(height: 8),

                ListTile(
                  title: const Text('Etiquetas'),
                  subtitle: _tags.isEmpty
                      ? const Text('Sin etiquetas')
                      : Wrap(
                          spacing: 4,
                          children: _tags
                              .map((tag) => Chip(
                                    label: Text(tag),
                                    backgroundColor: Color(_color).withOpacity(0.2),
                                  ))
                              .toList(),
                        ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showTagManager(context),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _validateAndSave,
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: Color(_color),
              onColorChanged: (color) {
                setState(() => _color = color.value);
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showTagManager(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Administrar etiquetas'),
        content: TagManager(
          tags: _tags,
          onTagsChanged: (newTags) {
            setState(() {
              _tags = newTags;
            });
          },
          iconColor: Color(_color),
        ),
        actions: [
          TextButton(
            child: const Text('Cerrar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _validateAndSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título es obligatorio')),
      );
      return;
    }
    
    widget.onSave(
      title,
      _descriptionController.text.trim(),
      _selectedDate,
      _tags,
      _color,
    );
    
    Navigator.of(context).pop();
  }
}