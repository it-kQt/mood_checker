// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuickEventAdapter extends TypeAdapter<QuickEvent> {
  @override
  final int typeId = 30;

  @override
  QuickEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuickEvent(
      id: fields[0] as String,
      dateTime: fields[1] as DateTime,
      emotionId: fields[2] as String,
      intensity: fields[3] as int,
      note: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, QuickEvent obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dateTime)
      ..writeByte(2)
      ..write(obj.emotionId)
      ..writeByte(3)
      ..write(obj.intensity)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuickEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
