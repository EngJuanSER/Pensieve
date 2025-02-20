import 'package:flutter/material.dart';

class NoteOptionsMenu extends StatelessWidget {
  final Color iconColor;
  final Color backgroundColor;
  final Function() onColorSelect;
  final Function() onTextColorSelect;
  final Function() onFontSizeSelect;
  final Function() onTagsSelect;
  final Function() onImagesSelect;
  final Function() onDeleteSelect;

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
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 0, 
        ),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: iconColor),
        offset: const Offset(0, 40),
        elevation: 0, 
        itemBuilder: (context) => [
          PopupMenuItem(
            padding: EdgeInsets.zero, 
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                image: DecorationImage(
                  image: const AssetImage('assets/images/lines_pattern.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    backgroundColor.withOpacity(0.8),
                    BlendMode.modulate,
                  ),
                ),
              ),
              child: Column(
                children: [
                  _buildMenuItem('color', Icons.color_lens, 'Color de nota'),
                  _buildMenuItem('text_color', Icons.format_color_text, 'Color de texto'),
                  _buildMenuItem('font_size', Icons.format_size, 'Tamaño de fuente'),
                  _buildMenuItem('tags', Icons.label, 'Etiquetas'),
                  _buildMenuItem('images', Icons.image, 'Imágenes'),
                  _buildDeleteItem(),
                ],
              ),
            ),
          ),
        ],
        onSelected: _handleSelection,
      ),
    );
  }

  Widget _buildMenuItem(String value, IconData icon, String text) {
    return InkWell(
      onTap: () => _handleSelection(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(color: iconColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteItem() {
    return InkWell(
      onTap: () => _handleSelection('delete'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  void _handleSelection(String value) {
    switch (value) {
      case 'color':
        onColorSelect();
        break;
      case 'text_color':
        onTextColorSelect();
        break;
      case 'font_size':
        onFontSizeSelect();
        break;
      case 'tags':
        onTagsSelect();
        break;
      case 'images':
        onImagesSelect();
        break;
      case 'delete':
        onDeleteSelect();
        break;
    }
  }
}