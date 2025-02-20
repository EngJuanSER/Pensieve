import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'note.dart';

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final typeId = 0;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      content: fields[1] as String,
      backgroundColor: fields[2] as int,
      createdAt: fields[3] as DateTime,
      modifiedAt: fields[4] as DateTime?,
      fontSize: fields[5] == null ? 16.0 : fields[5] as double, 
      textColor: fields[6] == null ? Colors.black.value : fields[6] as int, 
      imageUrls: fields[7] == null ? [] : List<String>.from(fields[7] as List), 
      isFavorite: fields[8] == null ? false : fields[8] as bool,
      tags: fields[9] == null ? [] : List<String>.from(fields[9] as List),
  
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
      writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.backgroundColor)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.modifiedAt)
      ..writeByte(5)
      ..write(obj.fontSize)
      ..writeByte(6)
      ..write(obj.textColor)
      ..writeByte(7)
      ..write(obj.imageUrls)
      ..writeByte(8)
      ..write(obj.isFavorite)
      ..writeByte(9)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}