class Note {
  String id;
  String content;
  int backgroundColor;
  DateTime createdAt;
  DateTime? modifiedAt;
  int textColor;
  double fontSize; 
  List<String> imageUrls;

  Note({
    required this.id,
    required this.content,
    required this.backgroundColor,
    required this.createdAt,
    this.modifiedAt, 
    required this.fontSize,
    required this.textColor,
    this.imageUrls = const [],
  });
}