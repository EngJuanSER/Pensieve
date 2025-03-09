import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/task.dart';

class TaskController extends ChangeNotifier {
  List<Task> tasks = [];
  Box<Task>? _tasksBox;
  bool _isInitialized = false;
  
  // Filtros
  List<String> selectedTags = [];
  bool showOnlyFavorites = false;
  bool showOnlyPending = true;
  DateTime? startDate;
  DateTime? endDate;
  String sortBy = 'dueDate';
  bool ascending = true;
  
  // Estadísticas
  Map<String, int> tagStats = {};
  int totalTasks = 0;
  int pendingTasks = 0;
  int completedTasks = 0;
  int favoritesCount = 0;
  int overdueCount = 0;
  DateTime? nextDueDate;

  TaskController();
  
  bool get isInitialized => _isInitialized;
  
  Future<void> loadTasks() async {
    if (_tasksBox == null) {
      await _openBox();
    } else {
      tasks = _tasksBox!.values.toList();
      updateStats();
      notifyListeners();
    }
  }
  
  Future<void> _openBox() async {
    try {
      _tasksBox = await Hive.openBox<Task>('tasks');
      tasks = _tasksBox!.values.toList();
      updateStats();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al abrir Hive Box: $e');
      
      try {
        await Hive.deleteBoxFromDisk('tasks');
        debugPrint('Caja eliminada tras error. Recreando...');
        _tasksBox = await Hive.openBox<Task>('tasks');
        tasks = [];
        updateStats();
        _isInitialized = true;
        notifyListeners();
      } catch (e2) {
        debugPrint('Error fatal con Hive: $e2');
        tasks = [];
        _isInitialized = true;
        notifyListeners();
      }
    }
  }
  
  void updateStats() {
    final allTasks = tasks;
    
    totalTasks = allTasks.length;
    pendingTasks = allTasks.where((task) => !task.isCompleted).length;
    completedTasks = allTasks.where((task) => task.isCompleted).length;
    favoritesCount = allTasks.where((task) => task.isFavorite).length;
    
    final now = DateTime.now();
    overdueCount = allTasks.where(
      (task) => !task.isCompleted && 
                task.dueDate != null && 
                task.dueDate!.isBefore(now)
    ).length;
    
    // Encontrar próxima fecha de entrega
    Task? nextDueTask;
    for (final task in allTasks.where((t) => !t.isCompleted && t.dueDate != null)) {
      if (nextDueTask == null || task.dueDate!.isBefore(nextDueTask.dueDate!)) {
        nextDueTask = task;
      }
    }
    nextDueDate = nextDueTask?.dueDate;
    
    // Estadística de etiquetas
    tagStats = {};
    for (final task in allTasks) {
      for (final tag in task.tags) {
        tagStats[tag] = (tagStats[tag] ?? 0) + 1;
      }
    }
  }
  
  List<Task> getFilteredAndSortedTasks(String searchText) {
    if (!_isInitialized) return [];
    
    return tasks.where((task) {
      bool matchesSearch = true;
      bool matchesTags = true;
      bool matchesFavorites = true;
      bool matchesPending = true;
      bool matchesDateRange = true;

      // Búsqueda
      if (searchText.isNotEmpty) {
        matchesSearch = task.title.toLowerCase().contains(searchText.toLowerCase()) ||
                     task.description.toLowerCase().contains(searchText.toLowerCase()) ||
                     task.tags.any((tag) => tag.toLowerCase().contains(searchText.toLowerCase()));
      }

      // Filtro por etiquetas
      if (selectedTags.isNotEmpty) {
        matchesTags = selectedTags.every((tag) => task.tags.contains(tag));
      }

      // Filtro por favoritos
      if (showOnlyFavorites) {
        matchesFavorites = task.isFavorite;
      }
      
      // Filtro por pendientes
      if (showOnlyPending) {
        matchesPending = !task.isCompleted;
      }

      // Filtro por rango de fechas (aplica a createdAt)
      if (startDate != null) {
        matchesDateRange = task.createdAt.isAfter(startDate!) || 
                          task.createdAt.isAtSameMomentAs(startDate!);
      }
      if (endDate != null) {
        matchesDateRange = matchesDateRange && 
                          (task.createdAt.isBefore(endDate!) || 
                          task.createdAt.isAtSameMomentAs(endDate!));
      }

      return matchesSearch && 
             matchesTags && 
             matchesFavorites && 
             matchesPending &&
             matchesDateRange;
    }).toList()..sort((a, b) {
      // Ordenamiento
      int comp;
      switch (sortBy) {
        case 'dueDate':
          // Tareas sin fecha de entrega van al final
          if (a.dueDate == null && b.dueDate == null) {
            comp = 0;
          } else if (a.dueDate == null) {
            comp = 1;
          } else if (b.dueDate == null) {
            comp = -1;
          } else {
            comp = a.dueDate!.compareTo(b.dueDate!);
          }
          break;
        case 'title':
          comp = a.title.compareTo(b.title);
          break;
        case 'createdAt':
          comp = a.createdAt.compareTo(b.createdAt);
          break;
        case 'completedAt':
          // Tareas no completadas van al final
          if (a.completedAt == null && b.completedAt == null) {
            comp = 0;
          } else if (a.completedAt == null) {
            comp = 1;
          } else if (b.completedAt == null) {
            comp = -1;
          } else {
            comp = a.completedAt!.compareTo(b.completedAt!);
          }
          break;
        default:
          comp = 0;
      }
      
      // Aplicar dirección (ascendente/descendente)
      return ascending ? comp : -comp;
    });
  }
  
  Future<bool> addTask({
    required String title,
    String description = '',
    DateTime? dueDate,
    List<String> tags = const [],
    int color = 0xFF4CAF50,
    String? reminder,
  }) async {
    if (!_isInitialized) await loadTasks();
    if (_tasksBox == null) return false;
    
    try {
      final taskId = const Uuid().v4();
      final task = Task(
        id: taskId,
        title: title,
        description: description,
        createdAt: DateTime.now(),
        dueDate: dueDate,
        isCompleted: false,
        isFavorite: false,
        tags: tags,
        color: color,
        reminder: reminder,
      );
      
      await _tasksBox!.put(taskId, task);
      await loadTasks();
      return true;
    } catch (e) {
      debugPrint('Error al agregar tarea: $e');
      return false;
    }
  }
  
  Future<bool> updateTask({
    required String id,
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? completedAt,
    bool? isCompleted,
    List<String>? tags,
    int? color,
    String? reminder,
  }) async {
    if (!_isInitialized) await loadTasks();
    if (_tasksBox == null) return false;
    
    try {
      final taskIndex = tasks.indexWhere((task) => task.id == id);
      if (taskIndex == -1) return false;
      
      final task = tasks[taskIndex];
      
      if (title != null) task.title = title;
      if (description != null) task.description = description;
      if (dueDate != null) task.dueDate = dueDate;
      if (completedAt != null) task.completedAt = completedAt;
      if (isCompleted != null) {
        task.isCompleted = isCompleted;
        if (isCompleted && task.completedAt == null) {
          task.completedAt = DateTime.now();
        } else if (!isCompleted) {
          task.completedAt = null;
        }
      }
      if (tags != null) task.tags = tags;
      if (color != null) task.color = color;
      if (reminder != null) task.reminder = reminder;
      
      await _tasksBox!.put(id, task);
      await loadTasks();
      return true;
    } catch (e) {
      debugPrint('Error al actualizar tarea: $e');
      return false;
    }
  }
  
  Future<bool> toggleTaskCompletion(String id) async {
    if (!_isInitialized) await loadTasks();
    if (_tasksBox == null) return false;
    
    try {
      final taskIndex = tasks.indexWhere((task) => task.id == id);
      if (taskIndex == -1) return false;
      
      final task = tasks[taskIndex];
      task.isCompleted = !task.isCompleted;
      
      if (task.isCompleted) {
        task.completedAt = DateTime.now();
      } else {
        task.completedAt = null;
      }
      
      await _tasksBox!.put(id, task);
      await loadTasks();
      return true;
    } catch (e) {
      debugPrint('Error al cambiar estado de tarea: $e');
      return false;
    }
  }
  
  Future<bool> toggleFavorite(String id) async {
    if (!_isInitialized) await loadTasks();
    if (_tasksBox == null) return false;
    
    try {
      final taskIndex = tasks.indexWhere((task) => task.id == id);
      if (taskIndex == -1) return false;
      
      final task = tasks[taskIndex];
      task.isFavorite = !task.isFavorite;
      
      await _tasksBox!.put(id, task);
      await loadTasks();
      return true;
    } catch (e) {
      debugPrint('Error al marcar/desmarcar favorito: $e');
      return false;
    }
  }
  
  Future<bool> deleteTask(String id) async {
    if (!_isInitialized) await loadTasks();
    if (_tasksBox == null) return false;
    
    try {
      await _tasksBox!.delete(id);
      await loadTasks();
      return true;
    } catch (e) {
      debugPrint('Error al eliminar tarea: $e');
      return false;
    }
  }
  
  List<String> getAvailableTags() {
    return tagStats.keys.toList();
  }
  
  void updateFilter({
    List<String>? tags,
    bool? onlyFavorites,
    bool? onlyPending,
    DateTime? start,
    DateTime? end,
    String? sort,
    bool? asc,
  }) {
    if (tags != null) selectedTags = tags;
    if (onlyFavorites != null) showOnlyFavorites = onlyFavorites;
    if (onlyPending != null) showOnlyPending = onlyPending;
    if (start != null) startDate = start;
    if (end != null) endDate = end;
    if (sort != null) sortBy = sort;
    if (asc != null) ascending = asc;
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}