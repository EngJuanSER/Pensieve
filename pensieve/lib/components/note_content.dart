import 'package:flutter/material.dart';
import 'dart:async';

class NoteContent extends StatefulWidget {
  final String content;
  final Color textColor;
  final double fontSize;
  final Function(String) onContentChanged;
  final Function(bool)? onFocusChanged;

  const NoteContent({
    super.key,
    required this.content,
    required this.textColor,
    required this.fontSize,
    required this.onContentChanged,
    this.onFocusChanged,
  });

  @override
  State<NoteContent> createState() => _NoteContentState();
}

class _NoteContentState extends State<NoteContent> {
  late TextEditingController textController;
  final FocusNode _focusNode = FocusNode();
  String lastContent = '';
  Timer? saveTimer;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.content);
    lastContent = widget.content;
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (widget.onFocusChanged != null) {
      widget.onFocusChanged!(_focusNode.hasFocus);
    }
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
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    textController.dispose();
    saveTimer?.cancel();
    super.dispose();
  }

    @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          fillColor: Colors.transparent,
          filled: false,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: widget.textColor,
          selectionColor: widget.textColor.withOpacity(0.3),
          selectionHandleColor: widget.textColor,
        ),
      ),
      child: TextField(
        controller: textController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Escribe algo...',
          hintStyle: TextStyle(color: widget.textColor.withOpacity(0.5)),
          fillColor: Colors.transparent,
          filled: false,
        ),
        onChanged: (text) {
          if (text != lastContent) {
            lastContent = text;
            if (saveTimer?.isActive ?? false) {
              saveTimer?.cancel();
            }
            saveTimer = Timer(const Duration(milliseconds: 500), () {
              widget.onContentChanged(text);
            });
          }
        },
        maxLines: null,
        style: TextStyle(
          fontSize: widget.fontSize,
          color: widget.textColor,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}