import "dart:io";

void log(String m) => stdout.writeln("[fix] $m");
void warn(String m) => stdout.writeln("[warn] $m");

Future<void> main() async {
  final mainPath = "lib/main.dart";
  final homePath = "lib/features/day/presentation/pages/home_page.dart";

  await _fixMain(mainPath);
  await _fixHomePage(homePath);

  log("Готово. Сделай полный перезапуск приложения.");
}

Future<void> _fixMain(String path) async {
  final f = File(path);
  if (!await f.exists()) {
    warn("Не найден $path — пропускаю фиксы main.dart");
    return;
  }
  var src = await f.readAsString();
  var changed = false;

  // 1) Импорт DayProvider
  const dayProviderImport = "package:it_kqt_mood/features/day/presentation/day_provider.dart";
  if (!src.contains(dayProviderImport)) {
    // вставим рядом с import provider.dart
    final iProvider = src.indexOf("package:provider/provider.dart");
    final toInsert = "import 'package:it_kqt_mood/features/day/presentation/day_provider.dart';\n";
    if (iProvider != -1) {
      final before = src.substring(0, src.lastIndexOf(";\n", iProvider) + 2);
      final after = src.substring(src.lastIndexOf(";\n", iProvider) + 2);
      src = before + toInsert + after;
    } else {
      src = toInsert + src;
    }
    changed = true;
    log("Добавлен импорт DayProvider в main.dart");
  }

  // 2) Обернуть runApp в MultiProvider с DayProvider
  // Ищем runApp(...)
  final runAppIdx = src.indexOf("runApp(");
  if (runAppIdx != -1 && !src.contains("MultiProvider") && !src.contains("Provider<DayProvider>") && !src.contains("ChangeNotifierProvider<DayProvider>")) {
    // Попробуем извлечь аргумент runApp(..)
    final closeParen = _findMatchingParen(src, runAppIdx + "runApp(".length - 1);
    if (closeParen != -1) {
      final arg = src.substring(runAppIdx + "runApp(".length, closeParen);
      String settingsProvider;
      if (arg.contains("ChangeNotifierProvider.value") && arg.contains("SettingsModel")) {
        // Уже есть SettingsModel через value — обернём в MultiProvider
        settingsProvider = arg.trim();
      } else {
        // Ищем создание settings ранее
        settingsProvider = "ChangeNotifierProvider<SettingsModel>.value(value: settings, child: const MyApp())";
      }

      final multi = """
MultiProvider(
  providers: [
    ChangeNotifierProvider<SettingsModel>.value(value: settings),
    ChangeNotifierProvider<DayProvider>(create: (_) => DayProvider()),
  ],
  child: const MyApp(),
)""";

      // Заменим runApp(арг) на runApp(multi)
      src = src.replaceRange(runAppIdx, closeParen + 1, "runApp($multi);");
      changed = true;
      log("Обёрнут runApp в MultiProvider c DayProvider");
    }
  } else if (!src.contains("ChangeNotifierProvider<DayProvider>")) {
    // Уже MultiProvider, но без DayProvider — добавим
    final providersIdx = src.indexOf("providers: [");
    if (providersIdx != -1) {
      final insertPos = src.indexOf("[", providersIdx) + 1;
      src = src.substring(0, insertPos) +
          "\n    ChangeNotifierProvider<DayProvider>(create: (_) => DayProvider())," +
          src.substring(insertPos);
      changed = true;
      log("Добавлен DayProvider в список providers");
    }
  }

  if (changed) {
    await f.writeAsString(src);
  } else {
    log("main.dart уже корректен (провайдер присутствует).");
  }
}

Future<void> _fixHomePage(String path) async {
  final f = File(path);
  if (!await f.exists()) {
    warn("Не найден $path — пропускаю фиксы HomePage");
    return;
  }
  var src = await f.readAsString();
  var changed = false;

  // 1) initState: заменить Future.microtask(...) на addPostFrameCallback
  final initStart = src.indexOf("void initState()");
  if (initStart != -1) {
    final blockStart = src.indexOf("{", initStart);
    final blockEnd = _findMatchingBrace(src, blockStart);
    if (blockStart != -1 && blockEnd != -1) {
      final initBlock = src.substring(blockStart, blockEnd + 1);
      if (initBlock.contains("Future.microtask") || initBlock.contains("context.read<DayProvider>().init()")) {
        final newInitBlock = """{
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DayProvider>().init();
    });
  }""";
        // Заменим весь метод initState на гарантировано корректный
        final methodStart = src.lastIndexOf("@override", initStart) != -1
            ? src.lastIndexOf("@override", initStart)
            : initStart;
        src = src.replaceRange(methodStart, blockEnd + 1, """
  @override
  void initState() $newInitBlock
""");
        changed = true;
        log("HomePage.initState переписан на addPostFrameCallback");
      }
    }
  } else {
    // нет initState — добавим
    final stateClassIdx = src.indexOf("class _HomePageState");
    if (stateClassIdx != -1) {
      final brace = src.indexOf("{", stateClassIdx);
      if (brace != -1) {
        final insertPos = brace + 1;
        src = src.substring(0, insertPos) +
            """

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DayProvider>().init();
    });
  }

""" +
            src.substring(insertPos);
        changed = true;
        log("HomePage.initState добавлен");
      }
    }
  }

  // 2) refreshToday после возврата со страниц — уже есть, оставляем

  if (changed) {
    await f.writeAsString(src);
  } else {
    log("HomePage уже корректен.");
  }
}

/// Вспомогательное: найти парную скобку ) к индексу на (
int _findMatchingParen(String s, int openIndex) {
  int depth = 0;
  for (int i = openIndex; i < s.length; i++) {
    final ch = s[i];
    if (ch == "(") depth++;
    if (ch == ")") {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

/// Вспомогательное: найти парную скобку } к индексу на {
int _findMatchingBrace(String s, int openIndex) {
  int depth = 0;
  bool inStr = false;
  String? quote;
  for (int i = openIndex; i < s.length; i++) {
    final ch = s[i];
    if (inStr) {
      if (ch == "\\" && i + 1 < s.length) {
        i++;
        continue;
      }
      if (ch == quote) {
        inStr = false;
        quote = null;
      }
      continue;
    }
    if (ch == "'" || ch == '"') {
      inStr = true;
      quote = ch;
      continue;
    }
    if (ch == "{") depth++;
    if (ch == "}") {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}