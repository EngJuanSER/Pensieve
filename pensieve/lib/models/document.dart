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
  String? thumbnailPath;
  bool isFavorite;

  Document({
    required this.id,
    required this.name,
    required this.path,
    required this.addedAt,
    this.lastAccessed,
    required this.fileType,
    required this.fileSize,
    this.description,
    this.thumbnailPath,
    List<String>? tags,
    bool? isFavorite,
  }) : 
    tags = tags ?? [],
    isFavorite = isFavorite ?? false;
}