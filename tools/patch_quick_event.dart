import "dart:io";

Future<void> main() async {
  const path = "lib/features/quick/data/quick_event.dart";
  final file = File(path);
  if (!await file.exists()) {
    stderr.writeln("Не найден файл: $path");
    exit(1);
  }
  var src = await file.readAsString();

  if (src.contains("class QuickEventAdapter extends TypeAdapter<QuickEvent>")) {
    print("Адаптер уже присутствует. Ничего не делаю.");
    return;
  }

  // Проверим, есть ли импорт hive
  if (!RegExp(r'''import\s+["']package:hive/hive.dart["'];''').hasMatch(src)) {
    src = 'import "package:hive/hive.dart";\n$src';
  }

  const adapter = r'''
class QuickEventAdapter extends TypeAdapter<QuickEvent> {
  @override
  final int typeId = 30;

  @override
  QuickEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
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
}
''';

  src = "$src\n$adapter\n";
  await file.writeAsString(src);
  print("Вставлен QuickEventAdapter в $path");
}