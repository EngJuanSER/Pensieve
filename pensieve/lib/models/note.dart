class Note {
  String id;
  String content;
  int backgroundColor;
  DateTime createdAt;
  int textColor;
  double fontSize; // Add font size

  Note({
    required this.id,
    required this.content,
    required this.backgroundColor,
    required this.createdAt,
    required this.fontSize,
    required this.textColor, // Add font size
  });
}