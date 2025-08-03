import "dart:convert";
import "dart:io";

Future<void> main() async {
  final pubspec = File("pubspec.yaml");
  if (!await pubspec.exists()) {
    stderr.writeln("pubspec.yaml не найден. Запусти скрипт из корня Flutter-проекта.");
    exit(1);
  }

  print("Читаю pubspec.yaml...");
  final original = await pubspec.readAsString();

  final updated = _ensureDeps(original);
  if (updated != original) {
    await pubspec.writeAsString(updated);
    print("pubspec.yaml обновлён.");
  } else {
    print("Зависимости уже присутствуют. Файл не изменён.");
  }

  await _run("flutter", ["pub", "get"]);

  if (updated.contains("build_runner") && updated.contains("hive_generator")) {
    await _run("dart", ["run", "build_runner", "build", "--delete-conflicting-outputs"]);
  } else {
    print("Пропускаю build_runner (нет зависимостей).");
  }

  print("Готово!");
}

String _ensureDeps(String yaml) {
  String addDepBlock(String section, Map<String, String> deps) {
    if (!yaml.contains("$section:\n")) {
      final block = StringBuffer()..writeln("$section:");
      deps.forEach((k, v) => block.writeln("  $k: $v"));
      yaml = "$yaml\n$block";
      return yaml;
    }

    final lines = LineSplitter.split(yaml).toList();
    final startIdx = lines.indexWhere((l) => l.trim() == "$section:");
    if (startIdx == -1) return yaml;

    final baseIndent = _leadingSpaces(lines[startIdx]);
    int endIdx = startIdx + 1;
    while (endIdx < lines.length) {
      final line = lines[endIdx];
      final indent = _leadingSpaces(line);
      if (line.trim().isEmpty) {
        endIdx++;
        continue;
      }
      if (indent <= baseIndent && !line.trim().startsWith("#")) break;
      endIdx++;
    }

    final current = <String, int>{};
    for (int i = startIdx + 1; i < endIdx; i++) {
      final l = lines[i];
      final trimmed = l.trimLeft();
      if (trimmed.startsWith("#") || !trimmed.contains(":")) continue;
      final key = trimmed.split(":").first.trim();
      current[key] = i;
    }

    final toInsert = <String, String>{};
    deps.forEach((k, v) {
      if (current.containsKey(k)) {
        final idx = current[k]!;
        final indent = " " * (baseIndent + 2);
        lines[idx] = "$indent$k: $v";
      } else {
        toInsert[k] = v;
      }
    });

    if (toInsert.isNotEmpty) {
      final insertPos = endIdx;
      final indent = " " * (baseIndent + 2);
      final newLines = toInsert.entries.map((e) => "$indent${e.key}: ${e.value}").toList();
      lines.insertAll(insertPos, newLines);
    }

    yaml = lines.join("\n");
    return yaml;
  }

  const deps = {
    "hive": "^2.2.3",
    "hive_flutter": "^1.1.0",
    "provider": "^6.0.5",
    "uuid": "^4.4.0",
  };

  const devDeps = {
    "build_runner": "^2.4.9",
    "hive_generator": "^2.0.1",
  };

  yaml = addDepBlock("dependencies", deps);
  yaml = addDepBlock("dev_dependencies", devDeps);

  if (!yaml.contains("environment:")) {
    yaml = """
environment:
  sdk: ">=2.18.0 <4.0.0"
$yaml
""";
  }

  return yaml;
}

int _leadingSpaces(String s) {
  var count = 0;
  for (var i = 0; i < s.length; i++) {
    final ch = s.codeUnitAt(i);
    if (ch == 0x20) {
      count++;
    } else {
      break;
    }
  }
  return count;
}

Future<void> _run(String bin, List<String> args) async {
  final proc = await Process.start(bin, args, mode: ProcessStartMode.inheritStdio);
  final code = await proc.exitCode;
  if (code != 0) {
    stderr.writeln("Команда завершилась с кодом $code: $bin ${args.join(" ")}");
    exit(code);
  }
}