import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'note.dart';

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final typeId = 0; // Assign a unique ID for the adapter

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
      fontSize: fields[4] == null ? 16.0 : fields[4] as double,
      textColor: fields[5] == null ? Colors.black.value : fields[5] as int, // Provide default value for textColor
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(6) 
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.backgroundColor) 
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.fontSize)
      ..writeByte(5)
      ..write(obj.textColor); 
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