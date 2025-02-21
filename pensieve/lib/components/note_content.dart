import 'package:flutter/material.dart';
import 'dart:async';

class NoteContent extends StatefulWidget {
  final String content;
  final Color textColor;
  final double fontSize;
  final Function(String) onContentChanged;

  const NoteContent({
    super.key,
    required this.content,
    required this.textColor,
    required this.fontSize,
    required this.onContentChanged,
  });

  @override
  State<NoteContent> createState() => _NoteContentState();
}

class _NoteContentState extends State<NoteContent> {
  late TextEditingController textController;
  String lastContent = '';
  Timer? saveTimer;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.content);
    lastContent = widget.content;
  }

  @override
  void didUpdateWidget(NoteContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      textController.text = widget.content;
      lastContent = widget.content;
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
    return TextField(
      controller: textController,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: 'Escribe algo...',
        hintStyle: TextStyle(color: widget.textColor),
      ),
      onChanged: (text) {
        if (text != lastContent) {
          lastContent = text;
          if (saveTimer?.isActive ?? false) {
            saveTimer?.cancel();
          }
          saveTimer = Timer(const Duration(seconds: 1), () {
            widget.onContentChanged(text);
          });
        }
      },
      maxLines: null,
      style: TextStyle(
        fontSize: widget.fontSize,
        color: widget.textColor,
      ),
    );
  }
}