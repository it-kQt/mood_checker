// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mood_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MoodEntryAdapter extends TypeAdapter<MoodEntry> {
  @override
  final int typeId = 2;

  @override
  MoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoodEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      emotion: fields[2] as MoodEmotion,
      score: fields[3] as int,
      note: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MoodEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.emotion)
      ..writeByte(3)
      ..write(obj.score)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoodEmotionAdapter extends TypeAdapter<MoodEmotion> {
  @override
  final int typeId = 1;

  @override
  MoodEmotion read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MoodEmotion.happy;
      case 1:
        return MoodEmotion.neutral;
      case 2:
        return MoodEmotion.sad;
      case 3:
        return MoodEmotion.angry;
      case 4:
        return MoodEmotion.anxious;
      case 5:
        return MoodEmotion.excited;
      default:
        return MoodEmotion.happy;
    }
  }

  @override
  void write(BinaryWriter writer, MoodEmotion obj) {
    switch (obj) {
      case MoodEmotion.happy:
        writer.writeByte(0);
        break;
      case MoodEmotion.neutral:
        writer.writeByte(1);
        break;
      case MoodEmotion.sad:
        writer.writeByte(2);
        break;
      case MoodEmotion.angry:
        writer.writeByte(3);
        break;
      case MoodEmotion.anxious:
        writer.writeByte(4);
        break;
      case MoodEmotion.excited:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodEmotionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
