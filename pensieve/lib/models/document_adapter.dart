import 'package:hive/hive.dart';
import 'document.dart';

class DocumentAdapter extends TypeAdapter<Document> {
  @override
  final int typeId = 2; 

  @override
  Document read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final path = reader.readString();
    final addedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final hasLastAccessed = reader.readBool();
    final lastAccessed = hasLastAccessed 
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;
    final fileType = reader.readString();
    final fileSize = reader.readInt();
    final tagCount = reader.readInt();
    final tags = List<String>.generate(tagCount, (_) => reader.readString());
    final hasDescription = reader.readBool();
    final description = hasDescription ? reader.readString() : null;
    final hasThumbnail = reader.readBool();
    final thumbnailPath = hasThumbnail ? reader.readString() : null;
    final isFavorite = reader.readBool();
    
    return Document(
      id: id,
      name: name,
      path: path,
      addedAt: addedAt,
      lastAccessed: lastAccessed,
      fileType: fileType,
      fileSize: fileSize,
      tags: tags,
      description: description,
      thumbnailPath: thumbnailPath,
      isFavorite: isFavorite,
    );
  }

  @override
  void write(BinaryWriter writer, Document obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.path);
    writer.writeInt(obj.addedAt.millisecondsSinceEpoch);
    writer.writeBool(obj.lastAccessed != null);
    if (obj.lastAccessed != null) {
      writer.writeInt(obj.lastAccessed!.millisecondsSinceEpoch);
    }
    writer.writeString(obj.fileType);
    writer.writeInt(obj.fileSize);
    writer.writeInt(obj.tags.length);
    for (var tag in obj.tags) {
      writer.writeString(tag);
    }
    writer.writeBool(obj.description != null);
    if (obj.description != null) {
      writer.writeString(obj.description!);
    }
    writer.writeBool(obj.thumbnailPath != null);
    if (obj.thumbnailPath != null) {
      writer.writeString(obj.thumbnailPath!);
    }
    writer.writeBool(obj.isFavorite);
  }
}