// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KeyValueIntAdapter extends TypeAdapter<KeyValueInt> {
  @override
  final int typeId = 21;

  @override
  KeyValueInt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KeyValueInt(
      fields[0] as String,
      fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, KeyValueInt obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyValueIntAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DayProfileAdapter extends TypeAdapter<DayProfile> {
  @override
  final int typeId = 20;

  @override
  DayProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DayProfile(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      values: (fields[2] as List).cast<KeyValueInt>(),
      note: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DayProfile obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.values)
      ..writeByte(3)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
