import 'dart:io';

void log(String m) => stdout.writeln('[fix] $m');
void warn(String m) => stdout.writeln('[warn] $m');

Future<void> main() async {
  await _ensurePubspecConstraints();
  await _writeHomePage();
  await _writeDayEditPage();
  await _writeDayProvider();

  await _run(['flutter', 'clean']);
  await _run(['flutter', 'pub', 'get']);
  await _run(['dart', 'run', 'build_runner', 'build', '--delete-conflicting-outputs']);

  log('Готово. Запускай: flutter run');
}

Future<void> _ensurePubspecConstraints() async {
  final f = File('pubspec.yaml');
  if (!f.existsSync()) {
    warn('pubspec.yaml не найден — пропускаю обновление зависимостей');
    return;
  }
  var s = f.readAsStringSync();
  var changed = false;

  // Нормализуем environment блок без RegExp с классами символов
  final lines = s.split('\n');
  final out = <String>[];
  var i = 0;
  var envWritten = false;
  while (i < lines.length) {
    final line = lines[i];
    if (line.trim() == 'environment:') {
      // пропустим существующий блок environment полностью
      out.add('environment:');
      out.add('  sdk: ">=3.7.0 <4.0.0"');
      envWritten = true;
      i++;
      // пропускаем следующие строки с отступом >=2 пробела
      while (i < lines.length && (lines[i].startsWith('  ') || lines[i].trim().isEmpty)) {
        // останавливаемся при встрече нового раздела верхнего уровня (например dependencies:)
        final t = lines[i].trimLeft();
        if (!lines[i].startsWith('  ') && t.endsWith(':')) break;
        i++;
      }
      continue;
    }
    out.add(line);
    i++;
  }
  if (!envWritten) {
    out.add('');
    out.add('environment:');
    out.add('  sdk: ">=3.7.0 <4.0.0"');
    changed = true;
    log('pubspec.yaml: добавлен SDK constraint');
  }
  final newS = out.join('\n');
  if (newS != s) {
    s = newS;
    changed = true;
    log('pubspec.yaml: environment обновлён');
  }

  // Убрать явный analyzer (простая замена по строке)
  if (s.contains('\nanalyzer:')) {
    s = s.replaceAll('\nanalyzer:', '\n# analyzer: resolved transitively');
    changed = true;
    log('pubspec.yaml: убран analyzer');
  }

  // Обновить codegen-зависимости
  s = _bumpDep(s, 'build_runner', '^2.4.13', dev: true);
  s = _bumpDep(s, 'json_serializable', '^6.9.0', dev: true);
  s = _bumpDep(s, 'hive_generator', '^2.0.1', dev: true);
  s = _bumpDep(s, 'freezed', '^2.5.7', dev: true);
  s = _bumpDep(s, 'freezed_annotation', '^2.4.4', dev: false);

  if (changed) {
    f.writeAsStringSync(s);
    log('pubspec.yaml сохранён. Выполняю flutter pub upgrade...');
    await _run(['flutter', 'pub', 'upgrade']);
  } else {
    log('pubspec.yaml без изменений');
  }
}

String _bumpDep(String s, String name, String target, {required bool dev}) {
  final section = dev ? 'dev_dependencies' : 'dependencies';
  final lines = s.split('\n');
  final out = <String>[];
  var hasSection = false;
  var sectionIndex = -1;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    out.add(line);
    if (line.trim() == '$section:') {
      hasSection = true;
      sectionIndex = out.length - 1;
    }
  }
  if (!hasSection) {
    out.add('');
    out.add('$section:');
    sectionIndex = out.length - 1;
  }

  // Найдём и заменим/добавим зависимость в секции
  var j = sectionIndex + 1;
  var found = false;
  while (j < out.length) {
    final t = out[j].trimLeft();
    if (!out[j].startsWith('  ') && t.endsWith(':')) break; // вышли из секции
    if (out[j].trim().startsWith('$name:')) {
      out[j] = '  $name: $target';
      found = true;
      break;
    }
    j++;
  }
  if (!found) {
    out.insert(sectionIndex + 1, '  $name: $target');
  }
  return out.join('\n');
}

Future<void> _writeHomePage() async {
  const path = 'lib/features/day/presentation/pages/home_page.dart';
  final f = File(path)..createSync(recursive: true);
  const content = r'''
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:it_kqt_mood/features/day/presentation/day_provider.dart";
import "package:it_kqt_mood/features/day/presentation/pages/day_edit_page.dart";
import "package:it_kqt_mood/features/day/presentation/widgets/gradient_slider.dart";
import "package:it_kqt_mood/features/day/presentation/widgets/circle_emotions.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DayProvider>().init();
    });
  }

  void _openQuickDialog({
    required String emotionId,
    required String emoji,
    required String label,
    required Color color,
  }) {
    final prov = context.read<DayProvider>();
    final cfg = prov.config!;
    final double min = cfg.scaleMin.toDouble();
    final double max = cfg.scaleMax.toDouble();
    double value = min;
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Text(label, style: Theme.of(ctx).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GradientSlider(
                min: min,
                max: max,
                color: color,
                value: value,
                onChanged: (v) {
                  value = v;
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: "Комментарий (опционально)",
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await prov.addQuickEvent(
                      emotionId: emotionId,
                      intensity: value.round(),
                      note: noteCtrl.text.trim(),
                    );
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: const Text("Сохранить"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DayProvider>();

    if (prov.isLoading || prov.config == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final cfg = prov.config!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Дневник настроения"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Экспресс-эмоции", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          CircleEmotions(
            items: [
              for (final e in cfg.emotions.where((e) => e.enabled))
                CircleEmotionItem(
                  id: e.id,
                  label: e.name,
                  emoji: e.emoji,
                  color: Color(e.color),
                ),
            ],
            onTap: (item) => _openQuickDialog(
              emotionId: item.id,
              emoji: item.emoji,
              label: item.label,
              color: item.color,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text("Итоги дня", style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DayEditPage()),
                  );
                  await context.read<DayProvider>().refreshToday();
                },
                child: const Text("Редактировать"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (prov.today == null)
            const Text("Пока нет данных за сегодня.")
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: prov.today!.values.entries.map((kv) {
                    final emo = cfg.emotions.firstWhere(
                      (e) => e.id == kv.key,
                      orElse: () => cfg.emotions.first,
                    );
                    return Chip(
                      label: Text("${emo.emoji} ${emo.name}: ${kv.value}"),
                    );
                  }).toList(),
                ),
                if (prov.today!.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(prov.today!.note),
                ],
              ],
            ),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DayEditPage()),
          );
          await context.read<DayProvider>().refreshToday();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
''';
  f.writeAsStringSync(content);
  log('Перезаписан $path');
}

Future<void> _writeDayEditPage() async {
  const path = 'lib/features/day/presentation/pages/day_edit_page.dart';
  final f = File(path)..createSync(recursive: true);
  const content = r'''
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:it_kqt_mood/features/day/presentation/day_provider.dart";
import "package:it_kqt_mood/features/day/presentation/widgets/gradient_slider.dart";

class DayEditPage extends StatefulWidget {
  const DayEditPage({super.key});

  @override
  State<DayEditPage> createState() => _DayEditPageState();
}

class _DayEditPageState extends State<DayEditPage> {
  final Map<String, double> _values = {};
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prov = context.read<DayProvider>();
    final cfg = prov.config!;
    final today = prov.today;
    for (final emo in cfg.emotions.where((e) => e.enabled)) {
      final current = today?.values[emo.id] ?? cfg.scaleMin;
      _values[emo.id] = (current).toDouble();
    }
    _noteCtrl.text = prov.today?.note ?? "";
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DayProvider>();
    final cfg = prov.config!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Как прошел день?"),
        actions: [
          TextButton(
            onPressed: () async {
              final map = _values.map((k, v) => MapEntry(k, v.round()));
              for (final entry in map.entries) {
                await prov.addQuickEvent(
                  emotionId: entry.key,
                  intensity: entry.value,
                  note: _noteCtrl.text.trim(),
                );
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final emo in cfg.emotions.where((e) => e.enabled)) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${emo.emoji} ${emo.name}"),
                Text((_values[emo.id] ?? cfg.scaleMin.toDouble()).round().toString()),
              ],
            ),
            GradientSlider(
              min: cfg.scaleMin.toDouble(),
              max: cfg.scaleMax.toDouble(),
              color: Color(emo.color),
              value: (_values[emo.id] ?? cfg.scaleMin.toDouble()),
              onChanged: (v) => setState(() => _values[emo.id] = v),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          const Text("Заметка", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Опишите, как прошел день",
            ),
          ),
        ],
      ),
    );
  }
}
''';
  f.writeAsStringSync(content);
  log('Перезаписан $path');
}

Future<void> _writeDayProvider() async {
  const path = 'lib/features/day/presentation/day_provider.dart';
  final f = File(path)..createSync(recursive: true);
  const content = r'''
import "dart:math";
import "package:flutter/foundation.dart";
import "package:uuid/uuid.dart";

import "package:it_kqt_mood/features/config/user_config_model.dart";
import "package:it_kqt_mood/features/config/config_service.dart";

import "package:it_kqt_mood/features/quick/data/quick_event.dart";
import "package:it_kqt_mood/features/quick/data/quick_event_repository.dart";

class DaySummary {
  final Map<String, int> values; // emotionId -> aggregated value
  final String note;

  DaySummary({required this.values, this.note = ""});
}

class DayProvider extends ChangeNotifier {
  final IQuickEventRepository quickRepo;

  DayProvider({IQuickEventRepository? quickRepo})
      : quickRepo = quickRepo ?? QuickEventRepository();

  bool isLoading = true;
  UserConfig? config;
  DaySummary? today;

  final _uuid = const Uuid();

  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    config = await ConfigService.loadOrCreate();
    await refreshToday();

    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshToday() async {
    final events = await quickRepo.listByDay(DateTime.now());
    final map = <String, int>{};
    for (final e in events) {
      map.update(e.emotionId, (v) => v + e.intensity, ifAbsent: () => e.intensity);
    }
    final note = events.firstWhere(
      (e) => e.note.trim().isNotEmpty,
      orElse: () => QuickEvent(
        id: "",
        dateTime: DateTime.now(),
        emotionId: "",
        intensity: 0,
        note: "",
      ),
    ).note;

    today = map.isEmpty && note.isEmpty ? null : DaySummary(values: map, note: note);
    notifyListeners();
  }

  Future<void> addQuickEvent({
    required String emotionId,
    required int intensity,
    String note = "",
  }) async {
    final cfg = config!;
    final int validatedIntensity = intensity.clamp(cfg.scaleMin, cfg.scaleMax);
    final event = QuickEvent(
      id: _uuid.v4(),
      dateTime: DateTime.now(),
      emotionId: emotionId,
      intensity: validatedIntensity,
      note: note,
    );
    await quickRepo.add(event);
    await refreshToday();
  }

  Future<void> saveConfig(UserConfig newCfg) async {
    final minV = newCfg.scaleMin;
    final maxV = newCfg.scaleMax;
    if (minV >= maxV) {
      final corrected = newCfg.copyWith(scaleMin: 0, scaleMax: max(1, maxV + 1));
      await ConfigService.save(corrected);
      config = corrected;
    } else {
      await ConfigService.save(newCfg);
      config = newCfg;
    }
    notifyListeners();
  }
}
''';
  f.writeAsStringSync(content);
  log('Перезаписан $path');
}

Future<void> _run(List<String> cmd) async {
  log('> ${cmd.join(' ')}');
  final p = await Process.start(cmd.first, cmd.sublist(1));
  await stdout.addStream(p.stdout);
  await stderr.addStream(p.stderr);
  final code = await p.exitCode;
  if (code != 0) {
    throw ProcessException(cmd.first, cmd.sublist(1), 'exit code $code', code);
  }
}