import 'package:flutter/material.dart';

class TaskFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<String> selectedTags;
  final List<String> availableTags;
  final bool showOnlyFavorites;
  final bool showOnlyPending;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortBy;
  final bool ascending;
  final Function(String) onSearch;
  final Function(List<String>) onTagsChanged;
  final Function(bool) onFavoritesChanged;
  final Function(bool) onPendingChanged;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(String, bool) onSortChanged;

  const TaskFilterBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.selectedTags,
    required this.availableTags,
    required this.showOnlyFavorites,
    required this.showOnlyPending,
    this.startDate,
    this.endDate,
    required this.sortBy,
    required this.ascending,
    required this.onSearch,
    required this.onTagsChanged,
    required this.onFavoritesChanged,
    required this.onPendingChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onSortChanged,
  });

  @override
  State<TaskFilterBar> createState() => _TaskFilterBarState();
}

class _TaskFilterBarState extends State<TaskFilterBar> {
  bool _showAdvancedFilters = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.searchController,
                  focusNode: widget.searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Buscar tareas...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    suffixIcon: widget.searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              widget.searchController.clear();
                              widget.onSearch('');
                            },
                          )
                        : null,
                  ),
                  onChanged: widget.onSearch,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showAdvancedFilters 
                    ? Icons.expand_less 
                    : Icons.expand_more,
                ),
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = !_showAdvancedFilters;
                  });
                },
              ),
            ],
          ),

          if (_showAdvancedFilters) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    selected: widget.showOnlyFavorites,
                    label: const Text('Favoritos'),
                    onSelected: widget.onFavoritesChanged,
                    avatar: const Icon(Icons.star),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: widget.showOnlyPending,
                    label: const Text('Pendientes'),
                    onSelected: widget.onPendingChanged,
                    avatar: const Icon(Icons.pending_actions),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: Text(
                      widget.startDate != null
                        ? _formatDate(widget.startDate!)
                        : 'Desde',
                    ),
                    onPressed: () => _selectDate(context, true),
                    avatar: const Icon(Icons.calendar_today),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: Text(
                      widget.endDate != null
                        ? _formatDate(widget.endDate!)
                        : 'Hasta',
                    ),
                    onPressed: () => _selectDate(context, false),
                    avatar: const Icon(Icons.calendar_today),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    child: Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Ordenar por ${_getSortByText()}'),
                          Icon(
                            widget.ascending 
                              ? Icons.arrow_upward 
                              : Icons.arrow_downward,
                            size: 16,
                          ),
                        ],
                      ),
                      avatar: const Icon(Icons.sort),
                    ),
                    itemBuilder: (context) => [
                      _buildSortMenuItem('dueDate', 'Fecha de vencimiento'),
                      _buildSortMenuItem('title', 'Título'),
                      _buildSortMenuItem('createdAt', 'Fecha de creación'),
                      _buildSortMenuItem('completedAt', 'Fecha de finalización'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            if (widget.availableTags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: widget.availableTags.map((tag) => FilterChip(
                  selected: widget.selectedTags.contains(tag),
                  label: Text(tag),
                  onSelected: (selected) {
                    List<String> newTags = List.from(widget.selectedTags);
                    if (selected) {
                      newTags.add(tag);
                    } else {
                      newTags.remove(tag);
                    }
                    widget.onTagsChanged(newTags);
                  },
                )).toList(),
              ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getSortByText() {
    switch (widget.sortBy) {
      case 'dueDate': return 'vencimiento';
      case 'title': return 'título';
      case 'createdAt': return 'creación';
      case 'completedAt': return 'finalización';
      default: return widget.sortBy;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (widget.startDate ?? DateTime.now()) : (widget.endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    
    if (picked != null) {
      if (isStart) {
        widget.onStartDateChanged(picked);
      } else {
        widget.onEndDateChanged(picked);
      }
    }
  }

  PopupMenuItem<String> _buildSortMenuItem(String value, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Text(text),
          const Spacer(),
          if (widget.sortBy == value)
            Icon(widget.ascending ? Icons.arrow_upward : Icons.arrow_downward),
        ],
      ),
      onTap: () {
        final newAscending = widget.sortBy == value ? !widget.ascending : true;
        Future.delayed(
          const Duration(milliseconds: 100),
          () => widget.onSortChanged(value, newAscending),
        );
      },
    );
  }
}