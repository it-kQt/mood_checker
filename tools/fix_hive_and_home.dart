import "dart:io";

void log(String m) => stdout.writeln("[fix] $m");
void warn(String m) => stdout.writeln("[warn] $m");

Future<void> main() async {
  await _patchDayProvider();
  await _patchHomePage();
  await _patchDayEditPage();
  log("Готово. Собери проект заново (полный перезапуск).");
}

Future<void> _patchDayProvider() async {
  final path = "lib/features/day/presentation/day_provider.dart";
  final f = File(path);
  if (!await f.exists()) { warn("Нет $path"); return; }
  var s = await f.readAsString();
  var changed = false;

  // Исправить ошибочную ссылка 'final c = config;' внутри DaySummary (по логу).
  // Удалим любые оступившиеся строки "final c = config;" вне DayProvider.
  if (s.contains("final c = config;")) {
    s = s.replaceAll("final c = config;", "");
    changed = true;
    log("DayProvider: удалена ошибочная строка 'final c = config;'");
  }

  // Валидация интенсивности: использовать configOrThrow и целочисленные границы
  final clampRe = RegExp(r"intensity\.clamp\(\s*config\.scaleMin\s*,\s*config\.scaleMax\s*\)");
  if (clampRe.hasMatch(s)) {
    s = s.replaceAll(clampRe, "intensity.clamp(configOrThrow.scaleMin, configOrThrow.scaleMax)");
    changed = true;
    log("DayProvider: валидация интенсивности через configOrThrow");
  }

  // Если встречается прямой доступ config.scaleMin/scaleMax — заменим на configOrThrow.
  s = s.replaceAll(RegExp(r"\bconfig\.scaleMin\b"), "configOrThrow.scaleMin");
  s = s.replaceAll(RegExp(r"\bconfig\.scaleMax\b"), "configOrThrow.scaleMax");

  // На всякий: убедимся, что метод init() сбрасывает isLoading.
  if (!s.contains("bool isLoading")) {
    final classOpen = s.indexOf("{");
    if (classOpen != -1) {
      s = s.substring(0, classOpen + 1) + "\n  bool isLoading = true;\n" + s.substring(classOpen + 1);
      changed = true;
      log("DayProvider: добавлен флаг isLoading");
    }
  }
  // Вставить обёртку isLoading в init() (если нет).
  final initSig = RegExp(r"Future<\s*void\s*>\s*init\s*\(\s*\)");
  final initMatch = initSig.firstMatch(s);
  if (initMatch != null) {
    final bStart = s.indexOf("{", initMatch.end);
    final bEnd = _matchBrace(s, bStart);
    var body = s.substring(bStart + 1, bEnd);
    if (!body.contains("isLoading = true")) {
      body = "    isLoading = true;\n    notifyListeners();\n$body";
      changed = true;
      log("DayProvider.init: добавлен старт загрузки");
    }
    if (!body.contains("isLoading = false")) {
      body = "$body\n\n    isLoading = false;\n    notifyListeners();\n";
      changed = true;
      log("DayProvider.init: добавлено завершение загрузки");
    }
    s = s.replaceRange(bStart + 1, bEnd, body);
  }

  if (changed) await f.writeAsString(s);
}

Future<void> _patchHomePage() async {
  final path = "lib/features/day/presentation/pages/home_page.dart";
  final f = File(path);
  if (!await f.exists()) { warn("Нет $path"); return; }
  var s = await f.readAsString();
  var changed = false;

  // Ранний лоадер уже добавлен ранее. Теперь заменим использование cfg (который UserConfig?) на not-null после проверки.
  // 1) В build: после раннего возврата cfg не null — используем !
  s = s.replaceAll("final cfg = prov.config;", "final cfg = prov.config!;");

  // 2) В _openQuickDialog: берём конфиг напрямую из провайдера (HomePage гарантирует init).
  // Заменим:
  // final cfg = prov.config;
  // final min = cfg.scaleMin.toDouble();
  // final max = cfg.scaleMax.toDouble();
  // double value = min;
  // На целочисленные границы.
  final dialogCfgRe = RegExp(
      r"final cfg = prov\.config;[\s\S]*?final min = cfg\.scaleMin\.toDouble\(\);[\s\S]*?final max = cfg\.scaleMax\.toDouble\(\);[\s\S]*?double value = min;");
  if (dialogCfgRe.hasMatch(s)) {
    s = s.replaceAll(dialogCfgRe, """
final cfg = prov.configOrThrow;
final int min = cfg.scaleMin;
final int max = cfg.scaleMax;
int value = min;""");
    changed = true;
    log("HomePage: диалог — целочисленные min/max и доступ через configOrThrow");
  } else {
    // на случай, если строки немного отличаются:
    s = s
        .replaceAll("final cfg = prov.config;", "final cfg = prov.configOrThrow;")
        .replaceAll(".toDouble()", "");
    // заменим типы переменных
    s = s.replaceAll(RegExp(r"final min = cfg\.scaleMin;"), "final int min = cfg.scaleMin;");
    s = s.replaceAll(RegExp(r"final max = cfg\.scaleMax;"), "final int max = cfg.scaleMax;");
    s = s.replaceAll(RegExp(r"double value = min;"), "int value = min;");
    changed = true;
  }

  // 3) Вызов GradientSlider: min/max/value должны быть int; onChanged отдаёт int.
  // Поправим лямбду, если тип double.
  s = s.replaceAll(
      RegExp(r"GradientSlider\(\s*min:\s*([^\n,]+),\s*max:\s*([^\n,]+),\s*color:\s*([^\n,]+),\s*value:\s*([^\n,]+),\s*onChanged:\s*\(v\)\s*\{\s*value\s*=\s*v;\s*\}", multiLine: true),
      "GradientSlider(min: min, max: max, color: color, value: value, onChanged: (v) { value = v; })");

  // 4) В списках эмоций — cfg уже non-null (cfg!), ничего не меняем кроме первой строки.

  if (changed) await f.writeAsString(s);
}

Future<void> _patchDayEditPage() async {
  final path = "lib/features/day/presentation/pages/day_edit_page.dart";
  final f = File(path);
  if (!await f.exists()) { warn("Нет $path"); return; }
  var s = await f.readAsString();
  var changed = false;

  // После экрана-загрузчика провайдер готов — используем cfg = prov.config!
  s = s.replaceAll("final cfg = prov.config;", "final cfg = prov.config!;");

  // Заменим все cfg.scaleMin/Max.toDouble() на целочисленное использование
  s = s.replaceAll(".toDouble()", "");

  // current = today?.values[emo.id] ?? cfg.scaleMin; — пусть будет int
  // Текстовое отображение: ((_values[emo.id] ?? cfg.scaleMin)).toString()
  s = s.replaceAll(
      RegExp(r"Text\(\((_values\[emo\.id\]\s*\?\?\s*cfg\.scaleMin\.toDouble\(\))\.toInt\(\)\.toString\(\)\)"),
      "Text((_values[emo.id] ?? cfg.scaleMin).toString())");

  // Слайдеры на int
  s = s.replaceAll(RegExp(r"min:\s*cfg\.scaleMin\.toDouble\(\)"), "min: cfg.scaleMin");
  s = s.replaceAll(RegExp(r"max:\s*cfg\.scaleMax\.toDouble\(\)"), "max: cfg.scaleMax");
  s = s.replaceAll(RegExp(r"value:\s*_values\[emo\.id\]\s*\?\?\s*cfg\.scaleMin\.toDouble\(\)"),
      "value: _values[emo.id] ?? cfg.scaleMin");

  changed = true;
  await f.writeAsString(s);
  log("DayEditPage: переведено на целочисленную шкалу и cfg!");
}

int _matchBrace(String s, int openIdx) {
  int d = 0;
  bool inStr = false;
  String? q;
  for (int i = openIdx; i < s.length; i++) {
    final ch = s[i];
    if (inStr) {
      if (ch == "\\" && i + 1 < s.length) { i++; continue; }
      if (ch == q) { inStr = false; q = null; }
      continue;
    }
    if (ch == "'" || ch == '"') { inStr = true; q = ch; continue; }
    if (ch == "{") d++;
    else if (ch == "}") { d--; if (d == 0) return i; }
  }
  return -1;
}