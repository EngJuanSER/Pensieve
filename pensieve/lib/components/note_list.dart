import 'package:flutter/material.dart';
import '../models/note.dart';
import 'note_list_header.dart';
import 'note_content.dart';
import 'image_preview.dart';
import 'tag_list.dart';
import 'font_size.dart';
import 'tag_manager.dart';
import 'image_gallery.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class NoteListItem extends StatefulWidget {
  final Note note;
  final Function(String, String) updateNote;
  final Function(String, Color) changeColor;
  final Function(String, double) changeFontSize;
  final Function(String, Color) changeTextColor;
  final Function(BuildContext, String) showDeleteConfirmationDialog;
  final Function(String) toggleFavorite;
  final Function(String, List<String>) updateTags;
  final GlobalKey<NoteListHeaderState>? headerKey;
  final Function(bool)? onFocusChanged;


  const NoteListItem({
    super.key,
    required this.note,
    required this.updateNote,
    required this.changeColor,
    required this.changeFontSize,
    required this.changeTextColor,
    required this.showDeleteConfirmationDialog,
    required this.toggleFavorite,
    required this.updateTags,
    required this.onFocusChanged,
    this.headerKey,
  });

  @override
  NoteListItemState createState() => NoteListItemState();
}

class NoteListItemState extends State<NoteListItem> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
          image: DecorationImage(
            image: const AssetImage('assets/images/lines_pattern.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(widget.note.backgroundColor).withOpacity(0.8),
              BlendMode.modulate,
            ),
          ),
        ),
        child: Card(
          elevation: 0,
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              NoteListHeader(
                key: widget.headerKey,
                createdAt: widget.note.createdAt,
                isFavorite: widget.note.isFavorite,
                textColor: Color(widget.note.textColor),
                backgroundColor: Color(widget.note.backgroundColor),
                onFavoriteToggle: () => widget.toggleFavorite(widget.note.id),
                onColorSelect: () => _showColorPicker(context),
                onTextColorSelect: () => _showTextColorPicker(context),
                onFontSizeSelect: () => _showFontSizeDialog(context),
                onTagsSelect: () => _showTagManager(context),
                onImagesSelect: () => _showImageGallery(context),
                onDeleteSelect: () => widget.showDeleteConfirmationDialog(context, widget.note.id),
              ),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NoteContent(
                      content: widget.note.content,
                      textColor: Color(widget.note.textColor),
                      fontSize: widget.note.fontSize,
                      onContentChanged: (text) => 
                        widget.updateNote(widget.note.id, text),
                      onFocusChanged: widget.onFocusChanged,
                    ),

                    if (widget.note.tags.isNotEmpty)
                      TagList(
                        tags: widget.note.tags,
                        textColor: Color(widget.note.textColor),
                        backgroundColor: Color(widget.note.backgroundColor),
                      ),
                    
                    if (widget.note.imageUrls.isNotEmpty)
                      ImagePreview(imageUrls: widget.note.imageUrls),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona un color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: Color(widget.note.backgroundColor),
            onColorChanged: (color) => widget.changeColor(widget.note.id, color),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cerrar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showTextColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona un color de texto'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: Color(widget.note.textColor),
            onColorChanged: (color) {
              setState(() {
                widget.changeTextColor(widget.note.id, color);
              });
            },          
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cerrar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FontSizeDialog(
        initialFontSize: widget.note.fontSize,
        onFontSizeChanged: (fontSize) => widget.changeFontSize(widget.note.id, fontSize),
      ),
    );
  }

  void _showTagManager(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestionar etiquetas'),
        content: TagManager(
          tags: widget.note.tags,
          onTagsChanged: (newTags) => widget.updateTags(widget.note.id, newTags),
          iconColor: Color(widget.note.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showImageGallery(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: ImageGallery(
          imageUrls: widget.note.imageUrls,
          onImageUrlsChanged: (newUrls) {
            setState(() {
              widget.note.imageUrls = newUrls;
              widget.updateNote(widget.note.id, widget.note.content);
            });
          },
          iconColor: Color(widget.note.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}