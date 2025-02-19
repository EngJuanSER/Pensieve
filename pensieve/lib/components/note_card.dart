import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/note.dart';
import '../components/font_size.dart';
import '../components/image_gallery.dart';
import 'dart:async';

class NoteCard extends StatefulWidget {
  final Note note;
  final Function(String, String) updateNote;
  final Function(String, Color) changeColor;
  final Function(String, double) changeFontSize;
  final Function(String, Color) changeTextColor;
  final Function(BuildContext, String) showDeleteConfirmationDialog;

  const NoteCard({
    super.key,
    required this.note,
    required this.updateNote,
    required this.changeColor,
    required this.changeFontSize,
    required this.changeTextColor,
    required this.showDeleteConfirmationDialog,
  });

  @override
  NoteCardState createState() => NoteCardState();
}

class NoteCardState extends State<NoteCard> {
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
  void didUpdateWidget(covariant NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note.content != oldWidget.note.content) {
      textController.text = widget.note.content;
      lastContent = widget.note.content;
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          image: AssetImage('assets/images/lines_pattern.jpg'), 
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Color(widget.note.backgroundColor).withOpacity(0.8), 
            BlendMode.modulate,
          ),
        ),
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: Colors.transparent,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
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
                style: TextStyle(fontSize: widget.note.fontSize, color: Color(widget.note.textColor)),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Row(
                children: [
                    ImageGallery(
                      iconColor: Color(widget.note.textColor),
                      imageUrls: widget.note.imageUrls,
                      onImageUrlsChanged: (newImageUrls) {
                        final note = widget.note;
                        note.imageUrls = newImageUrls;
                        widget.updateNote(note.id, note.content); // Actualizar la nota en Hive
                      },
                    ),
                    IconButton(
                    icon: Icon(color: Color(widget.note.textColor), Icons.color_lens),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Selecciona un color'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: Color(widget.note.backgroundColor),
                                onColorChanged: (color) {
                                  widget.changeColor(widget.note.id, color);
                                },
                              ),
                            ),
                            actions: <Widget>[
                              ElevatedButton(
                                child: const Text('Cerrar'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(color: Color(widget.note.textColor), Icons.format_size),
                     onPressed: () {
                      showGeneralDialog(
                        context: context,
                        barrierLabel: "Ajustar tamaño de fuente",
                        barrierDismissible: true,
                        barrierColor: Colors.black.withOpacity(0.5),
                        transitionDuration: const Duration(milliseconds: 200),
                        pageBuilder: (BuildContext context, Animation animation, Animation secondaryAnimation) {
                          return Center(
                            child: Container(
                              constraints: const BoxConstraints(
                                maxWidth: 350, 
                                maxHeight: 400, 
                              ),
                              child: FontSizeDialog(
                                initialFontSize: widget.note.fontSize,
                                onFontSizeChanged: (fontSize) {
                                  widget.changeFontSize(widget.note.id, fontSize);
                                },
                              ),
                            ),
                          );
                        },
                        transitionBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(color: Color(widget.note.textColor), Icons.format_color_text),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Selecciona un color de texto'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: Color(widget.note.textColor),
                                onColorChanged: (color) {
                                  widget.changeTextColor(widget.note.id, color);
                                },
                              ),
                            ),
                            actions: <Widget>[
                              ElevatedButton(
                                child: const Text('Cerrar'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(color: Color(widget.note.textColor), Icons.delete),
                    onPressed: () => widget.showDeleteConfirmationDialog(context, widget.note.id),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

