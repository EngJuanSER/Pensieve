import 'package:hive/hive.dart';
import 'document.dart';

class DocumentAdapter extends TypeAdapter<Document> {
  @override
  final int typeId = 2; 

  @override
  Document read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Document(
      id: fields[0] as String,
      name: fields[1] as String,
      path: fields[2] as String,
      addedAt: fields[3] as DateTime,
      lastAccessed: fields[4] as DateTime?,
      fileType: fields[5] as String,
      fileSize: fields[6] as int,
      tags: (fields[7] as List).cast<String>(),
      description: fields[8] as String?,
      isFavorite: fields[9] as bool,
      thumbnailPath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Document obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.addedAt)
      ..writeByte(4)
      ..write(obj.lastAccessed)
      ..writeByte(5)
      ..write(obj.fileType)
      ..writeByte(6)
      ..write(obj.fileSize)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.isFavorite)
      ..writeByte(10)
      ..write(obj.thumbnailPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}