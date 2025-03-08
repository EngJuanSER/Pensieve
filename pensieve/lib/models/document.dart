class Document {
  String id;
  String name;
  String path;
  DateTime addedAt;
  DateTime? lastAccessed;
  String fileType;
  int fileSize; 
  List<String> tags;
  String? description;
  bool isFavorite;
  String? thumbnailPath;

  Document({
    required this.id,
    required this.name,
    required this.path,
    required this.addedAt,
    this.lastAccessed,
    required this.fileType,
    required this.fileSize,
    List<String>? tags,
    this.description,
    this.isFavorite = false,
    this.thumbnailPath,
  }) : tags = tags ?? [];
}