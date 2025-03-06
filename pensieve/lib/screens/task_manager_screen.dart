import 'package:flutter/material.dart';
import '../components/theme_toggle_button.dart';

class TaskManagerScreen extends StatelessWidget {
  const TaskManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Lógica para agregar tarea
            },
          ),
        ],
      ),
      // resto del código...
    );
  }
}