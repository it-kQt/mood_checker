// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_config_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmotionConfigAdapter extends TypeAdapter<EmotionConfig> {
  @override
  final int typeId = 10;

  @override
  EmotionConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmotionConfig(
      id: fields[0] as String,
      name: fields[1] as String,
      emoji: fields[2] as String,
      color: fields[3] as int,
      enabled: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EmotionConfig obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.enabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserConfigAdapter extends TypeAdapter<UserConfig> {
  @override
  final int typeId = 11;

  @override
  UserConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserConfig(
      scaleMin: fields[0] as int,
      scaleMax: fields[1] as int,
      emotions: (fields[2] as List).cast<EmotionConfig>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserConfig obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.scaleMin)
      ..writeByte(1)
      ..write(obj.scaleMax)
      ..writeByte(2)
      ..write(obj.emotions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
