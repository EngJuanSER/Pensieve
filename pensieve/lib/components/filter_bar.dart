import 'package:flutter/material.dart';

class FilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<String> selectedTags;
  final List<String> availableTags;
  final bool showOnlyFavorites;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortBy;
  final bool ascending;
  final Function(String) onSearch;
  final Function(List<String>) onTagsChanged;
  final Function(bool) onFavoritesChanged;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(String, bool) onSortChanged;

  const FilterBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.selectedTags,
    required this.availableTags,
    required this.showOnlyFavorites,
    this.startDate,
    this.endDate,
    required this.sortBy,
    required this.ascending,
    required this.onSearch,
    required this.onTagsChanged,
    required this.onFavoritesChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onSortChanged,
  });

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
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
                    hintText: 'Buscar notas...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
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
                  ActionChip(
                    label: Text(
                      widget.startDate?.toString().split(' ')[0] ?? 'Fecha inicial',
                    ),
                    onPressed: () => _selectDate(context, true),
                    avatar: const Icon(Icons.calendar_today),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: Text(
                      widget.endDate?.toString().split(' ')[0] ?? 'Fecha final',
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
                          Text('Ordenar por ${widget.sortBy}'),
                          Icon(
                            widget.ascending 
                              ? Icons.arrow_upward 
                              : Icons.arrow_downward,
                          ),
                        ],
                      ),
                      avatar: const Icon(Icons.sort),
                    ),
                    itemBuilder: (context) => [
                      _buildSortMenuItem('fecha_creacion', 'Fecha de creación'),
                      _buildSortMenuItem('fecha_modificacion', 'Fecha de modificación'),
                      _buildSortMenuItem('alfabeticamente', 'Alfabéticamente'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
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

  PopupMenuItem<String> _buildSortMenuItem(String value, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Text(text),
          const Spacer(),
          if (widget.sortBy == value)
            Icon(
              widget.ascending 
                ? Icons.arrow_upward 
                : Icons.arrow_downward,
            ),
        ],
      ),
      onTap: () {
        widget.onSortChanged(
          value,
          widget.sortBy == value ? !widget.ascending : true,
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      if (isStartDate) {
        widget.onStartDateChanged(picked);
      } else {
        widget.onEndDateChanged(picked);
      }
    }
  }
}