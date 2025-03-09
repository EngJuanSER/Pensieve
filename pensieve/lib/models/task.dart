class Task {
  String id;
  String title;
  String description;
  DateTime createdAt;
  DateTime? dueDate;
  DateTime? completedAt;
  bool isCompleted;
  bool isFavorite;
  List<String> tags;
  int color;
  String? reminder;
  
  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    this.isCompleted = false,
    this.isFavorite = false,
    List<String>? tags,
    required this.color,
    this.reminder,
  }) : tags = tags ?? [];
}