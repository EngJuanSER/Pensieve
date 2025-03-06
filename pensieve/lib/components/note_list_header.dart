import 'package:flutter/material.dart';
import 'note_options_menu.dart';
import 'package:intl/intl.dart';

class NoteListHeader extends StatefulWidget {
  final DateTime createdAt;
  final bool isFavorite;
  final Color textColor;
  final Color backgroundColor;
  final Function() onFavoriteToggle;
  final Function() onColorSelect;
  final Function() onTextColorSelect;
  final Function() onFontSizeSelect;
  final Function() onTagsSelect;
  final Function() onImagesSelect;
  final Function() onDeleteSelect;

  const NoteListHeader({
    super.key,
    required this.createdAt,
    required this.isFavorite,
    required this.textColor,
    required this.backgroundColor,
    required this.onFavoriteToggle,
    required this.onColorSelect,
    required this.onTextColorSelect,
    required this.onFontSizeSelect,
    required this.onTagsSelect,
    required this.onImagesSelect,
    required this.onDeleteSelect,
  });

  @override
  State<NoteListHeader> createState() => NoteListHeaderState();
}

class NoteListHeaderState extends State<NoteListHeader> {
  final GlobalKey<NoteOptionsMenuState> _menuKey = GlobalKey();

  void showOptionsMenu() {
    _menuKey.currentState?.showOptionsMenu();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yy').format(date);
  }

@override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 4.0, 4.0, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          
          if (availableWidth < 80) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    widget.isFavorite ? Icons.star : Icons.star_border,
                    color: widget.textColor,
                  ),
                  onPressed: widget.onFavoriteToggle,
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
                NoteOptionsMenu(
                  key: _menuKey,
                  iconColor: widget.textColor,
                  backgroundColor: widget.backgroundColor,
                  onColorSelect: widget.onColorSelect,
                  onTextColorSelect: widget.onTextColorSelect,
                  onFontSizeSelect: widget.onFontSizeSelect,
                  onTagsSelect: widget.onTagsSelect,
                  onImagesSelect: widget.onImagesSelect,
                  onDeleteSelect: widget.onDeleteSelect,
                  iconSize: 16,
                  buttonConstraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ],
            );
          }
          
          final buttonsWidth = availableWidth > 120 ? 76.0 : 60.0;
          final dateWidth = availableWidth - buttonsWidth - 8;
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: dateWidth.clamp(0.0, double.infinity),
                child: Text(
                  _formatDate(widget.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.textColor.withOpacity(0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: buttonsWidth,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        widget.isFavorite ? Icons.star : Icons.star_border,
                        color: widget.textColor,
                      ),
                      onPressed: widget.onFavoriteToggle,
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                    NoteOptionsMenu(
                      key: _menuKey,
                      iconColor: widget.textColor,
                      backgroundColor: widget.backgroundColor,
                      onColorSelect: widget.onColorSelect,
                      onTextColorSelect: widget.onTextColorSelect,
                      onFontSizeSelect: widget.onFontSizeSelect,
                      onTagsSelect: widget.onTagsSelect,
                      onImagesSelect: widget.onImagesSelect,
                      onDeleteSelect: widget.onDeleteSelect,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}