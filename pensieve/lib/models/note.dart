class Note {
  String id;
  String content;
  int backgroundColor;
  DateTime createdAt;
  int textColor;
  double fontSize; 
  DateTime? modifiedAt;


  Note({
    required this.id,
    required this.content,
    required this.backgroundColor,
    required this.createdAt,
    required this.fontSize,
    required this.textColor,
    this.modifiedAt, 
  });
}