import 'package:flutter/material.dart';
import 'note_options_menu.dart';

class NoteHeader extends StatefulWidget {
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

  const NoteHeader({
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
  State<NoteHeader> createState() => NoteHeaderState();
}

class NoteHeaderState extends State<NoteHeader> {
  final GlobalKey<NoteOptionsMenuState> _menuKey = GlobalKey();

  void showOptionsMenu() {
    _menuKey.currentState?.showOptionsMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 4.0, 4.0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.createdAt.toString().split('.')[0],
            style: TextStyle(
              fontSize: 12,
              color: widget.textColor.withOpacity(0.6),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  widget.isFavorite ? Icons.star : Icons.star_border,
                  color: widget.textColor,
                ),
                onPressed: widget.onFavoriteToggle,
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
        ],
      ),
    );
  }
}