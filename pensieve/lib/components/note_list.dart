import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/note.dart';
import '../components/font_size.dart';
import '../components/image_gallery.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

class NoteListItem extends StatefulWidget {
  final Note note;
  final Function(String, String) updateNote;
  final Function(String, Color) changeColor;
  final Function(String, double) changeFontSize;
  final Function(String, Color) changeTextColor;
  final Function(BuildContext, String) showDeleteConfirmationDialog;
  final Function(String) toggleFavorite;
  final Function(String, List<String>) updateTags;

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
  });

  @override
  NoteListItemState createState() => NoteListItemState();
}

class NoteListItemState extends State<NoteListItem> {
  String lastContent = '';
  Timer? saveTimer;
  late TextEditingController textController;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.note.content);
    lastContent = widget.note.content;
  }

  @override
  void didUpdateWidget(covariant NoteListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note.content != oldWidget.note.content) {
      textController.text = widget.note.content;
      lastContent = widget.note.content;
    }
  }

  @override
  void dispose() {
    textController.dispose();
    saveTimer?.cancel();
    super.dispose();
  }

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
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 4.0, 4.0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.note.createdAt.toString().split('.')[0],
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(widget.note.textColor).withOpacity(0.6),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        widget.note.isFavorite ? Icons.star : Icons.star_border,
                        color: Color(widget.note.textColor),
                      ),
                      onPressed: () => widget.toggleFavorite(widget.note.id),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Escribe algo...',
                          hintStyle: TextStyle(color: Color(widget.note.textColor)),
                        ),
                        onChanged: (text) {
                          if (text != lastContent) {
                            lastContent = text;
                            if (saveTimer?.isActive ?? false) {
                              saveTimer?.cancel();
                            }
                            saveTimer = Timer(const Duration(seconds: 1), () {
                              widget.updateNote(widget.note.id, text);
                            });
                          }
                        },
                        maxLines: null,
                        style: TextStyle(
                          fontSize: widget.note.fontSize,
                          color: Color(widget.note.textColor),
                        ),
                      ),
                      
                      if (widget.note.imageUrls.isNotEmpty)
                        ValueListenableBuilder<List<String>>(
                          valueListenable: ValueNotifier<List<String>>(widget.note.imageUrls),
                          builder: (context, imageUrls, _) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  for (var i = 0; i < math.min(2, imageUrls.length); i++)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.file(
                                          File(imageUrls[i]),
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  if (imageUrls.length > 2)
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '+${imageUrls.length - 2}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Color(widget.note.textColor).withOpacity(0.1),
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ImageGallery(
                      iconColor: Color(widget.note.textColor),
                      imageUrls: widget.note.imageUrls,
                      onImageUrlsChanged: (newImageUrls) {
                        setState(() {
                          widget.note.imageUrls = newImageUrls;
                          widget.updateNote(widget.note.id, widget.note.content);
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.color_lens, color: Color(widget.note.textColor)),
                      onPressed: () => _showColorPicker(context),
                    ),
                    IconButton(
                      icon: Icon(Icons.format_size, color: Color(widget.note.textColor)),
                      onPressed: () => _showFontSizeDialog(context),
                    ),
                    IconButton(
                      icon: Icon(Icons.format_color_text, color: Color(widget.note.textColor)),
                      onPressed: () => _showTextColorPicker(context),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Color(widget.note.textColor)),
                      onPressed: () => widget.showDeleteConfirmationDialog(context, widget.note.id),
                    ),
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
      builder: (BuildContext context) {
        return AlertDialog(
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
        );
      },
    );
  }

  void _showTextColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona un color de texto'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: Color(widget.note.textColor),
              onColorChanged: (color) => widget.changeTextColor(widget.note.id, color),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Ajustar tamaño de fuente",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350, maxHeight: 400),
            child: FontSizeDialog(
              initialFontSize: widget.note.fontSize,
              onFontSizeChanged: (fontSize) => widget.changeFontSize(widget.note.id, fontSize),
            ),
          ),
        );
      },
    );
  }
}