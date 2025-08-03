import "dart:io";

void log(String msg) => stdout.writeln("[fix] $msg");
void warn(String msg) => stdout.writeln("[warn] $msg");

Future<void> main() async {
  final dayProviderPath = "lib/features/day/presentation/day_provider.dart";
  final homePagePath = "lib/features/day/presentation/pages/home_page.dart";
  final dayEditPagePath = "lib/features/day/presentation/pages/day_edit_page.dart";
  final circleEmoPath = "lib/features/day/presentation/widgets/circle_emotions.dart";
  final quickEventPath = "lib/features/quick/data/quick_event.dart";
  final quickEventGPath = "lib/features/quick/data/quick_event.g.dart";
  final quickRepoPath = "lib/features/quick/data/quick_event_repository.dart";
  final hiveServicePath = "lib/core/storage/hive_service.dart";

  await _ensureFileExists(dayProviderPath);
  await _ensureFileExists(quickEventPath);

  await _fixDayProvider(dayProviderPath);
  await _fixHomePage(homePagePath);
  await _fixDayEditPage(dayEditPagePath);
  await _fixCircleEmotions(circleEmoPath);
  await _fixQuickEventForGeneration(quickEventPath, quickEventGPath);
  await _ensureQuickRepo(quickRepoPath);
  await _ensureHiveService(hiveServicePath);

  await _runFlutter(["pub", "get"]);
  await _runDart(["run", "build_runner", "build", "--delete-conflicting-outputs"]);
  await _runFlutter(["run"]);
}

Future<void> _ensureFileExists(String path) async {
  final f = File(path);
  if (!await f.exists()) {
    warn("Файл не найден: $path — некоторые правки будут пропущены.");
  }
}

Future<void> _fixDayProvider(String path) async {
  final file = File(path);
  if (!await file.exists()) return;
  var src = await file.readAsString();

  // Исправим импорты config (без /data)
  src = src.replaceAll('features/config/data/user_config_model.dart', 'features/config/user_config_model.dart');
  src = src.replaceAll('features/config/data/config_service.dart', 'features/config/config_service.dart');

  // Исправим импорты quick (не из day)
  src = src.replaceAll('features/day/data/quick_event.dart', 'features/quick/data/quick_event.dart');
  src = src.replaceAll('features/day/data/quick_event_repository.dart', 'features/quick/data/quick_event_repository.dart');

  // Добавим import dart:math если используется max( и нет импорта
  if (src.contains('max(') && !src.contains('import "dart:math";') && !src.contains("import 'dart:math';")) {
    // вставим перед первым import package или самым началом
    final idx = src.indexOf('import ');
    if (idx >= 0) {
      src = src.substring(0, idx) + 'import "dart:math";\n' + src.substring(idx);
    } else {
      src = 'import "dart:math";\n' + src;
    }
    log("Добавлен import dart:math в $path");
  }

  await file.writeAsString(src);
  log("Обновлён $path");
}

Future<void> _fixHomePage(String path) async {
  final file = File(path);
  if (!await file.exists()) return;
  var src = await file.readAsString();

  // .values.map((kv) -> .values.entries.map((kv)
  if ((src.contains("kv.key") || src.contains("kv.value")) && src.contains(".values.map((kv)")) {
    src = src.replaceAll(".values.map((kv)", ".values.entries.map((kv)");
    log("Исправлена итерация по Map.entries в $path");
  }

  await file.writeAsString(src);
}

Future<void> _fixDayEditPage(String path) async {
  final file = File(path);
  if (!await file.exists()) return;
  var src = await file.readAsString();

  if (src.contains("valuesMap")) {
    src = src.replaceAll("valuesMap", "values");
    log("Заменено valuesMap на values в $path");
  }

  if (src.contains("saveDayProfileManual(")) {
    // Простой замещающий шаблон: берем одну строку вызова и заменяем несколькими строками
    src = src.replaceAllMapped(
      RegExp(r'await\s+prov\.saveDayProfileManual\(\s*([a-zA-Z0-9_]+)\s*,\s*([^\)]+)\);'),
      (m) {
        final mapArg = m.group(1) ?? "map";
        final noteArg = m.group(2) ?? "null";
        return '''
for (final entry in $mapArg.entries) {
  await prov.addQuickEvent(
    emotionId: entry.key,
    intensity: entry.value,
    note: $noteArg,
  );
}''';
      },
    );
    log("Заменён вызов saveDayProfileManual на добавление событий в $path");
  }

  await file.writeAsString(src);
}

Future<void> _fixCircleEmotions(String path) async {
  final file = File(path);
  if (!await file.exists()) return;
  var src = await file.readAsString();

  final hasClass = src.contains("class CircleEmotions");
  final hasButtonSize = src.contains("_buttonSize");
  final hasLabelWidth = src.contains("_labelWidth");

  if (hasClass && !(hasButtonSize && hasLabelWidth)) {
    final insertAfter = src.indexOf("{", src.indexOf("class CircleEmotions"));
    if (insertAfter != -1) {
      final insertPos = insertAfter + 1;
      final addition = '''
  static const double _buttonSize = 56;
  static const double _labelWidth = 80;
''';
      src = src.substring(0, insertPos) + addition + src.substring(insertPos);
      log("Добавлены константы _buttonSize и _labelWidth в $path");
    }
  }

  await file.writeAsString(src);
}

Future<void> _fixQuickEventForGeneration(String path, String gPath) async {
  final file = File(path);
  if (!await file.exists()) {
    warn("Не найден $path — пропускаю фиксы QuickEvent");
    return;
  }
  var src = await file.readAsString();

  // Удалим ручной адаптер (ищем по имени класса)
  if (src.contains("class QuickEventAdapter extends TypeAdapter<QuickEvent>")) {
    // Грубое удаление блока класса адаптера
    final start = src.indexOf("class QuickEventAdapter extends TypeAdapter<QuickEvent>");
    if (start >= 0) {
      final end = src.indexOf("}", start);
      if (end >= 0) {
        // Попробуем найти закрывающую скобку класса адаптера более надёжно
        int brace = 0;
        int pos = start;
        int endPos = -1;
        while (pos < src.length) {
          if (src[pos] == "{") brace++;
          if (src[pos] == "}") {
            brace--;
            if (brace == 0) {
              endPos = pos + 1;
              break;
            }
          }
          pos++;
        }
        if (endPos > start) {
          src = src.substring(0, start) + src.substring(endPos);
          log("Удалён ручной QuickEventAdapter из $path");
        }
      }
    }
  }

  // Убедимся, что есть импорт hive
  if (!src.contains('package:hive/hive.dart')) {
    // вставим перед первым import package
    final idx = src.indexOf('import ');
    if (idx >= 0) {
      src = src.substring(0, idx) + 'import "package:hive/hive.dart";\n' + src.substring(idx);
    } else {
      src = 'import "package:hive/hive.dart";\n' + src;
    }
    log("Добавлен импорт hive в $path");
  }

  // Убедимся, что есть part "quick_event.g.dart";
  if (!src.contains('part "quick_event.g.dart";') && !src.contains("part 'quick_event.g.dart';")) {
    // вставим после импортов
    final firstNonImport = _findFirstNonImportIndex(src);
    final insertPos = firstNonImport >= 0 ? firstNonImport : 0;
    src = src.substring(0, insertPos) + 'part "quick_event.g.dart";\n' + src.substring(insertPos);
    log("Добавлен part quick_event.g.dart в $path");
  }

  // Убедимся, что класс размечен аннотацией @HiveType(typeId: 30)
  if (src.contains("class QuickEvent") && !src.contains("@HiveType(")) {
    src = src.replaceFirst("class QuickEvent", "@HiveType(typeId: 30)\nclass QuickEvent");
    // Добавим @HiveField для типичных имён
    for (final e in [
      ["id", 0],
      ["dateTime", 1],
      ["emotionId", 2],
      ["intensity", 3],
      ["note", 4],
    ]) {
      final name = e[0] as String;
      final index = e[1] as int;
      final idx = src.indexOf(RegExp(r'[\n\r][ \t]*(final|late|var|[A-Za-z0-9_<>\?]+)[ \t]+' + name + r'\b'));
      if (idx != -1) {
        // Проверим, что перед полем ещё нет @HiveField(index)
        final before = src.substring(0, idx);
        final fieldLineStart = before.lastIndexOf("\n");
        final hasAnn = before.substring(fieldLineStart + 1).contains("@HiveField(");
        if (!hasAnn) {
          src = src.substring(0, idx) + "\n  @HiveField($index)" + src.substring(idx);
        }
      }
    }
    log("Добавлены аннотации HiveType/HiveField в $path");
  }

  await file.writeAsString(src);

  // Сообщим, что g.dart перегенерируется
  final gFile = File(gPath);
  if (await gFile.exists()) {
    log("Файл $gPath будет перегенерирован build_runner.");
  }
}

int _findFirstNonImportIndex(String src) {
  int i = 0;
  while (true) {
    final next = src.indexOf("import ", i);
    if (next != i) break;
    final semi = src.indexOf(";", i);
    if (semi == -1) break;
    i = semi + 1;
    // пропустим пустые строки
    while (i < src.length && (src[i] == "\n" || src[i] == "\r")) i++;
  }
  return i;
}

Future<void> _ensureQuickRepo(String path) async {
  final file = File(path);
  if (await file.exists()) return;

  final content = '''
import "package:hive/hive.dart";
import "package:it_kqt_mood/core/storage/hive_service.dart";
import "package:it_kqt_mood/features/quick/data/quick_event.dart";

abstract class IQuickEventRepository {
  Future<void> add(QuickEvent e);
  Future<List<QuickEvent>> listByDay(DateTime day);
}

class QuickEventRepository implements IQuickEventRepository {
  Box<QuickEvent> get _box => HiveService.quickBox;

  @override
  Future<void> add(QuickEvent e) async {
    await _box.put(e.id, e);
  }

  @override
  Future<List<QuickEvent>> listByDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _box.values
        .where((e) => e.dateTime.isAfter(start) && e.dateTime.isBefore(end))
        .toList();
  }
}
''';
  await file.create(recursive: true);
  await file.writeAsString(content);
  log("Создан $path");
}

Future<void> _ensureHiveService(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    warn("Не найден $path — пропускаю проверки HiveService");
    return;
  }
  var src = await file.readAsString();

  // Импорт QuickEvent
  if (!src.contains('features/quick/data/quick_event.dart')) {
    final idx = src.indexOf('import ');
    final importLine = 'import "package:it_kqt_mood/features/quick/data/quick_event.dart";\n';
    if (idx >= 0) {
      src = src.substring(0, idx) + importLine + src.substring(idx);
    } else {
      src = importLine + src;
    }
    log("Добавлен импорт quick_event.dart в HiveService");
  }

  // Регистрация адаптера QuickEventAdapter
  if (!src.contains("QuickEventAdapter(")) {
    final initIdx = src.indexOf("Future<void> init() async {");
    if (initIdx != -1) {
      final insertPos = initIdx + "Future<void> init() async {".length;
      src = src.substring(0, insertPos) +
          '\n    if (!Hive.isAdapterRegistered(30)) Hive.registerAdapter(QuickEventAdapter());' +
          src.substring(insertPos);
      log("Добавлена регистрация QuickEventAdapter в HiveService.init()");
    } else {
      warn("Не найден метод init() в HiveService — пропущена регистрация адаптера.");
    }
  }

  // Поле и открытие бокса quick_event_box
  if (!src.contains("quick_event_box") && !src.contains("quickBox")) {
    // Добавим поле после объявления класса
    final classIdx = src.indexOf(RegExp(r'class\s+\w+\s*\{'));
    if (classIdx != -1 && !src.contains("Box<QuickEvent> quickBox")) {
      final bracePos = src.indexOf("{", classIdx);
      final insertPos = bracePos + 1;
      src = src.substring(0, insertPos) + "\n  static late Box<QuickEvent> quickBox;" + src.substring(insertPos);
      log("Добавлено поле quickBox в HiveService");
    }
    // Вставим открытие в init()
    final initIdx2 = src.indexOf("Future<void> init() async {");
    if (initIdx2 != -1 && !src.contains('openBox<QuickEvent>("quick_event_box"')) {
      final insertPos2 = initIdx2 + "Future<void> init() async {".length;
      src = src.substring(0, insertPos2) +
          '\n    quickBox = await Hive.openBox<QuickEvent>("quick_event_box");' +
          src.substring(insertPos2);
      log("Добавлено открытие бокса quick_event_box в HiveService.init()");
    }
  }

  await file.writeAsString(src);
}

Future<void> _runFlutter(List<String> args) async {
  final exe = Platform.environment["FLUTTER_BIN"];
  final bin = exe != null && exe.isNotEmpty ? exe : "flutter";
  await _run(bin, args);
}

Future<void> _runDart(List<String> args) async {
  await _run("dart", args);
}

Future<void> _run(String bin, List<String> args) async {
  log("run: $bin ${args.join(' ')}");
  final proc = await Process.start(
    bin,
    args,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await proc.exitCode;
  if (code != 0) {
    stderr.writeln("Команда завершилась с кодом $code: $bin ${args.join(' ')}");
    exit(code);
  }
}