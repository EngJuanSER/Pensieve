import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final Function() onTap;
  final Function() onToggleCompletion;
  final Function() onToggleFavorite;
  final Function() onDelete;
  
  const TaskItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleCompletion,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isOverdue = task.dueDate != null && 
                          !task.isCompleted && 
                          task.dueDate!.isBefore(DateTime.now());

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
          ? BorderSide(color: Colors.red.shade300, width: 1.5)
          : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: task.isCompleted
              ? Border.all(color: Colors.green.withOpacity(0.5), width: 1)
              : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con título, botón de completado y acciones
                Row(
                  children: [
                    // Checkbox de completado
                    Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) => onToggleCompletion(),
                        activeColor: Color(task.color),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    
                    // Título de la tarea
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                          color: task.isCompleted
                            ? isDarkMode
                              ? Colors.white70
                              : Colors.black54
                            : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Botones de acción
                    IconButton(
                      icon: Icon(
                        task.isFavorite ? Icons.star : Icons.star_border,
                        color: task.isFavorite ? Colors.amber : null,
                      ),
                      iconSize: 20,
                      onPressed: onToggleFavorite,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                    ),
                    
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      iconSize: 20,
                      onPressed: () => _confirmDelete(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                    ),
                  ],
                ),
                
                // Description (si existe)
                if (task.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 40, top: 4, bottom: 8),
                    child: Text(
                      task.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                // Etiquetas y fechas
                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 4),
                  child: Row(
                    children: [
                      // Fecha de vencimiento
                      if (task.dueDate != null) 
                        _buildDueDate(context, isDarkMode, isOverdue),
                      
                      const Spacer(),
                      
                      // Tags
                      if (task.tags.isNotEmpty)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Color(task.color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.tags.length > 1
                                ? '${task.tags.length} etiquetas'
                                : task.tags.first,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(task.color),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDueDate(BuildContext context, bool isDarkMode, bool isOverdue) {
    final now = DateTime.now();
    final dueDate = task.dueDate!;
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    String dueDateText;
    if (dueDay.isAtSameMomentAs(today)) {
      dueDateText = 'Hoy';
    } else if (dueDay.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      dueDateText = 'Mañana';
    } else if (dueDay.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      dueDateText = 'Ayer';
    } else {
      dueDateText = '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    }
    
    Color textColor = isOverdue
      ? Colors.red
      : isDarkMode
        ? Colors.white70
        : Colors.black87;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.calendar_today,
          size: 12,
          color: textColor,
        ),
        const SizedBox(width: 4),
        Text(
          dueDateText,
          style: TextStyle(
            fontSize: 12,
            color: textColor,
            fontWeight: isOverdue ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
  
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Estás seguro de que quieres eliminar la tarea "${task.title}"?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}