import 'package:flutter/material.dart';

class DocumentLibraryViewOptions extends StatelessWidget {
  final String viewMode; 
  final int gridColumns;
  final ValueChanged<String> onViewModeChanged;
  final ValueChanged<int> onGridColumnsChanged;
  
  const DocumentLibraryViewOptions({
    super.key,
    required this.viewMode,
    required this.gridColumns,
    required this.onViewModeChanged,
    required this.onGridColumnsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Selector de modo de vista
          PopupMenuButton<String>(
            tooltip: 'Cambiar vista',
            icon: Icon(_getViewModeIcon()),
            onSelected: onViewModeChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'grid',
                child: Row(
                  children: [
                    Icon(Icons.grid_view),
                    SizedBox(width: 8),
                    Text('Cuadrícula'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'list',
                child: Row(
                  children: [
                    Icon(Icons.view_list),
                    SizedBox(width: 8),
                    Text('Lista'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'grouped_type',
                child: Row(
                  children: [
                    Icon(Icons.folder),
                    SizedBox(width: 8),
                    Text('Agrupar por tipo'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'grouped_tag',
                child: Row(
                  children: [
                    Icon(Icons.label),
                    SizedBox(width: 8),
                    Text('Agrupar por etiqueta'),
                  ],
                ),
              ),
            ],
          ),
          
          if (viewMode == 'grid')
            Expanded(
              child: Row(
                children: [
                  const Text('Columnas: '),
                  Expanded(
                    child: Slider(
                      value: gridColumns.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
                      label: '$gridColumns',
                      onChanged: (value) => onGridColumnsChanged(value.toInt()),
                    ),
                  ),
                  Text('$gridColumns'),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  IconData _getViewModeIcon() {
    switch (viewMode) {
      case 'list':
        return Icons.view_list;
      case 'grouped_type':
        return Icons.folder;
      case 'grouped_tag':
        return Icons.label;
      case 'grid':
      default:
        return Icons.grid_view;
    }
  }
}