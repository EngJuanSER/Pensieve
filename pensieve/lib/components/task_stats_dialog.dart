import 'package:flutter/material.dart';

class TaskStatsDialog extends StatelessWidget {
  final int totalTasks;
  final int pendingTasks;
  final int completedTasks;
  final int favoritesCount;
  final int overdueCount;
  final DateTime? nextDueDate;
  final Map<String, int> tagStats;

  const TaskStatsDialog({
    super.key,
    required this.totalTasks,
    required this.pendingTasks,
    required this.completedTasks,
    required this.favoritesCount,
    required this.overdueCount,
    this.nextDueDate,
    required this.tagStats,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Estadísticas de Tareas'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow(context, 'Total de tareas', totalTasks),
            _buildStatRow(context, 'Tareas pendientes', pendingTasks),
            _buildStatRow(context, 'Tareas completadas', completedTasks),
            _buildStatRow(context, 'Tareas favoritas', favoritesCount),
            _buildStatRow(context, 'Tareas atrasadas', overdueCount, 
              color: overdueCount > 0 ? Colors.red : null),
            
            if (nextDueDate != null) ...[
              const SizedBox(height: 8),
              _buildDateRow(
                context, 
                'Próximo vencimiento', 
                '${nextDueDate!.day}/${nextDueDate!.month}/${nextDueDate!.year}'
              ),
            ],
            
            if (tagStats.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Tareas por etiqueta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...tagStats.entries
                .toList()
                .map((e) => _buildStatRow(context, e.key, e.value))
                ,
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, String label, int value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}