import 'package:flutter/material.dart';

class Note {
  String id;
  String content;
  Color backgroundColor;
  DateTime createdAt;

  Note({
    required this.id,
    required this.content,
    required this.backgroundColor,
    required this.createdAt,
  });
}
