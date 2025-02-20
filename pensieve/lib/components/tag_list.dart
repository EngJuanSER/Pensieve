import 'package:flutter/material.dart';

class TagList extends StatelessWidget {
  final List<String> tags;
  final Color textColor;
  final Color backgroundColor;

  const TagList({
    super.key,
    required this.tags,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags.map((tag) => Chip(
        label: Text(
          tag,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
          ),
        ),
        backgroundColor: backgroundColor.withOpacity(0.3),
      )).toList(),
    );
  }
}