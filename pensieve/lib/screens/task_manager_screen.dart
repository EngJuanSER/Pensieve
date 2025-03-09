import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../components/controllers/task_controller.dart';
import '../components/task_item.dart';
import '../components/task_filter_bar.dart';
import '../components/task_form_dialog.dart';
import '../components/task_detail_dialog.dart';
import '../components/task_stats_dialog.dart';
import '../components/theme_toggle_button.dart';

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  TaskManagerScreenState createState() => TaskManagerScreenState();
}

class TaskManagerScreenState extends State<TaskManagerScreen> {
  final TaskController _controller = TaskController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  FocusNode? _rootFocusNode;
  
  @override
  void initState() {
    super.initState();
    _initializeController();
    _setupKeyboardHandlers();
  }

  Future<void> _initializeController() async {
    try {
      await _controller.loadTasks();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error al inicializar el controlador de tareas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar las tareas'),
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
              _showAddTaskDialog();
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
        _showAddTaskDialog();
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

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        onSave: (title, description, dueDate, tags, color) {
          _addTask(title, description, dueDate, tags, color);
        },
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        task: task,
        onSave: (title, description, dueDate, tags, color) {
          _updateTask(
            task.id, 
            title, 
            description, 
            dueDate, 
            task.isCompleted,
            tags, 
            color
          );
        },
      ),
    );
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(
        task: task,
        onEdit: () => _showEditTaskDialog(task),
        onDelete: () => _deleteTask(task.id),
        onToggleCompletion: () => _toggleTaskCompletion(task.id),
        onToggleFavorite: () => _toggleFavorite(task.id),
      ),
    );
  }

  Future<void> _addTask(
    String title, 
    String description, 
    DateTime? dueDate, 
    List<String> tags, 
    int color
  ) async {
    final success = await _controller.addTask(
      title: title,
      description: description,
      dueDate: dueDate,
      tags: tags,
      color: color,
    );
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea agregada correctamente')),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al agregar la tarea'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateTask(
    String id, 
    String title, 
    String description, 
    DateTime? dueDate, 
    bool isCompleted,
    List<String> tags, 
    int color
  ) async {
    final success = await _controller.updateTask(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      isCompleted: isCompleted,
      tags: tags,
      color: color,
    );
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea actualizada correctamente')),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar la tarea'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleTaskCompletion(String id) async {
    final success = await _controller.toggleTaskCompletion(id);
    if (mounted && success) {
      setState(() {});
    }
  }

  Future<void> _toggleFavorite(String id) async {
    final success = await _controller.toggleFavorite(id);
    if (mounted && success) {
      setState(() {});
    }
  }

  void _confirmDeleteTask(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Estás seguro de que quieres eliminar la tarea "$title"?'),
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
              _deleteTask(id);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(String id) async {
    final success = await _controller.deleteTask(id);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea eliminada correctamente')),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar la tarea'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStats(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TaskStatsDialog(
        totalTasks: _controller.totalTasks,
        pendingTasks: _controller.pendingTasks,
        completedTasks: _controller.completedTasks,
        favoritesCount: _controller.favoritesCount,
        overdueCount: _controller.overdueCount,
        nextDueDate: _controller.nextDueDate,
        tagStats: _controller.tagStats,
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
            title: const Text('Tareas'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              const ThemeToggleButton(),
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Estadísticas',
                onPressed: () => _showStats(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Barra de filtros
              TaskFilterBar(
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                selectedTags: _controller.selectedTags,
                availableTags: _controller.getAvailableTags(),
                showOnlyFavorites: _controller.showOnlyFavorites,
                showOnlyPending: _controller.showOnlyPending,
                startDate: _controller.startDate,
                endDate: _controller.endDate,
                sortBy: _controller.sortBy,
                ascending: _controller.ascending,
                onSearch: (value) => setState(() {}),
                onTagsChanged: (tags) {
                  _controller.updateFilter(tags: tags);
                  setState(() {});
                },
                onFavoritesChanged: (value) {
                  _controller.updateFilter(onlyFavorites: value);
                  setState(() {});
                },
                onPendingChanged: (value) {
                  _controller.updateFilter(onlyPending: value);
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

              // Lista de tareas
              Expanded(
                child: _buildTaskList(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddTaskDialog,
            tooltip: 'Agregar tarea',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    if (!_controller.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final tasks = _controller.getFilteredAndSortedTasks(_searchController.text);

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Colors.grey.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty || _controller.selectedTags.isNotEmpty
                ? 'No se encontraron tareas con los filtros aplicados'
                : 'No hay tareas. ¡Crea tu primera tarea!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.withOpacity(0.9),
              ),
            ),
            if (_searchController.text.isNotEmpty || _controller.selectedTags.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Limpiar filtros'),
                onPressed: () {
                  _searchController.clear();
                  _controller.updateFilter(
                    tags: [],
                    onlyFavorites: false,
                    sort: 'dueDate',
                    asc: true,
                  );
                  setState(() {});
                },
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskItem(
          task: task,
          onTap: () => _showTaskDetails(task),
          onToggleCompletion: () => _toggleTaskCompletion(task.id),
          onToggleFavorite: () => _toggleFavorite(task.id),
          onDelete: () => _confirmDeleteTask(context, task.id, task.title),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    
    if (_rootFocusNode != null) {
      _rootFocusNode!.dispose();
    }
    
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);
    super.dispose();
  }
}