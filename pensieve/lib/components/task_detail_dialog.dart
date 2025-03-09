import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskDetailDialog extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleCompletion;
  final VoidCallback onToggleFavorite;

  const TaskDetailDialog({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleCompletion,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isOverdue = task.dueDate != null && 
                           !task.isCompleted && 
                           task.dueDate!.isBefore(DateTime.now());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(task.color).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: Color(task.color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted ? 
                          TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      task.isFavorite ? Icons.star : Icons.star_border,
                      color: task.isFavorite ? Colors.amber : null,
                    ),
                    onPressed: onToggleFavorite,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (task.description.isNotEmpty) ...[
                const Text(
                  'Descripción',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? 
                      Colors.grey.shade800 : 
                      Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? 
                        Colors.white : 
                        Colors.black87,
                      decoration: task.isCompleted ? 
                        TextDecoration.lineThrough : 
                        null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Fechas y estados
              Column(
                children: [
                  _buildInfoRow(
                    context,
                    'Estado',
                    task.isCompleted ? 'Completada' : 'Pendiente',
                    icon: task.isCompleted ? 
                      Icons.check_circle : 
                      Icons.pending_actions,
                    iconColor: task.isCompleted ? 
                      Colors.green : 
                      Colors.blue,
                  ),
                  if (task.dueDate != null)
                    _buildInfoRow(
                      context,
                      'Fecha de vencimiento',
                      _formatDate(task.dueDate!),
                      icon: Icons.calendar_today,
                      iconColor: isOverdue ? Colors.red : null,
                    ),
                  _buildInfoRow(
                    context,
                    'Fecha de creación',
                    _formatDate(task.createdAt),
                    icon: Icons.access_time,
                  ),
                  if (task.completedAt != null)
                    _buildInfoRow(
                      context,
                      'Fecha de finalización',
                      _formatDate(task.completedAt!),
                      icon: Icons.done_all,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Etiquetas
              if (task.tags.isNotEmpty) ...[
                const Text(
                  'Etiquetas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: task.tags.map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Color(task.color).withOpacity(0.2),
                  )).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDelete();
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: Icon(
                      task.isCompleted ? Icons.refresh : Icons.check,
                    ),
                    label: Text(
                      task.isCompleted ? 'Reabrir' : 'Completar'
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onToggleCompletion();
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onEdit();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, 
    String title, 
    String value, 
    {IconData? icon, Color? iconColor}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            '$title:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}