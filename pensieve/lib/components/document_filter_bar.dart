import 'package:flutter/material.dart';

class DocumentFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<String> selectedTags;
  final List<String> availableTags;
  final List<String> selectedTypes;
  final List<String> availableTypes;
  final bool showOnlyFavorites;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortBy;
  final bool ascending;
  final Function(String) onSearch;
  final Function(List<String>) onTagsChanged;
  final Function(List<String>) onTypesChanged;
  final Function(bool) onFavoritesChanged;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(String, bool) onSortChanged;

  const DocumentFilterBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.selectedTags,
    required this.availableTags,
    required this.selectedTypes,
    required this.availableTypes,
    required this.showOnlyFavorites,
    this.startDate,
    this.endDate,
    required this.sortBy,
    required this.ascending,
    required this.onSearch,
    required this.onTagsChanged,
    required this.onTypesChanged,
    required this.onFavoritesChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onSortChanged,
  });

  @override
  State<DocumentFilterBar> createState() => _DocumentFilterBarState();
}

class _DocumentFilterBarState extends State<DocumentFilterBar> {
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
                    hintText: 'Buscar documentos...',
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
                  ActionChip(
                    label: Text(
                      widget.startDate != null 
                        ? "${widget.startDate!.day}/${widget.startDate!.month}/${widget.startDate!.year}"
                        : 'Desde',
                    ),
                    onPressed: () => _selectDate(context, true),
                    avatar: const Icon(Icons.calendar_today),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: Text(
                      widget.endDate != null
                        ? "${widget.endDate!.day}/${widget.endDate!.month}/${widget.endDate!.year}"
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
                          Text('Ordenar por ${_getSortByText(widget.sortBy)}'),
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
                      _buildSortMenuItem('fecha_agregado', 'Fecha de agregado'),
                      _buildSortMenuItem('fecha_acceso', 'Fecha de acceso'),
                      _buildSortMenuItem('nombre', 'Nombre'),
                      _buildSortMenuItem('tamaño', 'Tamaño'),
                    ],
                  ),
                ],
              ),
            ),
            
            if (widget.availableTypes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Tipos: '),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.availableTypes.map((type) => 
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              selected: widget.selectedTypes.contains(type),
                              label: Text(type.toUpperCase()),
                              onSelected: (selected) {
                                List<String> newTypes = List.from(widget.selectedTypes);
                                if (selected) {
                                  newTypes.add(type);
                                } else {
                                  newTypes.remove(type);
                                }
                                widget.onTypesChanged(newTypes);
                              },
                            ),
                          )
                        ).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            if (widget.availableTags.isNotEmpty) ...[
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
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart 
      ? widget.startDate ?? DateTime.now() 
      : widget.endDate ?? DateTime.now();
      
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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

  String _getSortByText(String sortBy) {
    switch (sortBy) {
      case 'fecha_agregado': return 'fecha agregado';
      case 'fecha_acceso': return 'fecha acceso';
      case 'nombre': return 'nombre';
      case 'tamaño': return 'tamaño';
      default: return sortBy;
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