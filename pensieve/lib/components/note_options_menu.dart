import 'package:flutter/material.dart';

class NoteOptionsMenu extends StatefulWidget {
  final Color iconColor;
  final Color backgroundColor;
  final Function() onColorSelect;
  final Function() onTextColorSelect;
  final Function() onFontSizeSelect;
  final Function() onTagsSelect;
  final Function() onImagesSelect;
  final Function() onDeleteSelect;
  final double iconSize;
  final BoxConstraints buttonConstraints;

  const NoteOptionsMenu({
    super.key,
    required this.iconColor,
    required this.backgroundColor,
    required this.onColorSelect,
    required this.onTextColorSelect,
    required this.onFontSizeSelect,
    required this.onTagsSelect,
    required this.onImagesSelect,
    required this.onDeleteSelect,
    this.iconSize = 24.0,
    this.buttonConstraints = const BoxConstraints(),
  });

  @override
  State<NoteOptionsMenu> createState() => NoteOptionsMenuState();
}

class NoteOptionsMenuState extends State<NoteOptionsMenu> {
  final GlobalKey<PopupMenuButtonState<String>> _popupKey = GlobalKey();

  void showOptionsMenu() {
    _popupKey.currentState?.showButtonMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 0, 
        ),
      ),
      child: PopupMenuButton<String>(
        key: _popupKey,
        icon: Icon(Icons.more_vert, 
          color: widget.iconColor, 
          size: widget.iconSize,
        ),
        padding: EdgeInsets.zero,
        constraints: widget.buttonConstraints,
        offset: const Offset(0, 40),
        elevation: 0,
        itemBuilder: (context) => [
          PopupMenuItem(
            padding: EdgeInsets.zero,
            child: StatefulBuilder(
              builder: (context, setState) => Container(
                constraints: const BoxConstraints(
                  maxWidth: 250,
                  minWidth: 150,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  image: DecorationImage(
                    image: const AssetImage('assets/images/lines_pattern.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      widget.backgroundColor.withOpacity(0.5),
                      BlendMode.multiply,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _buildMenuItem('color', Icons.color_lens, 'Color de nota', context),
                    _buildMenuItem('text_color', Icons.format_color_text, 'Color de texto', context),
                    _buildMenuItem('font_size', Icons.format_size, 'Tamaño de fuente', context),
                    _buildMenuItem('tags', Icons.label, 'Etiquetas', context),
                    _buildMenuItem('images', Icons.image, 'Imágenes', context),
                    _buildMenuItem('delete', Icons.delete, 'Eliminar', context), 
                  ],
                ),
              ),
            ),
          ),
        ],
        onSelected: _handleSelection,
      ),
    );
  }

  Widget _buildMenuItem(String value, IconData icon, String text, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _handleSelection(value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: widget.iconColor, size: 18),
              const SizedBox(width: 6),
              Text(text, style: TextStyle(color: widget.iconColor, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSelection(String value) {
    switch (value) {
      case 'color':
        widget.onColorSelect();
        break;
      case 'text_color':
        widget.onTextColorSelect();
        break;
      case 'font_size':
        widget.onFontSizeSelect();
        break;
      case 'tags':
        widget.onTagsSelect();
        break;
      case 'images':
        widget.onImagesSelect();
        break;
      case 'delete':
        widget.onDeleteSelect();
        break;
    }
  }
}