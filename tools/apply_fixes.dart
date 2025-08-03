import "dart:io";

void main() async {
  final projectRoot = Directory.current.path;
  print("Applying fixes to project at: $projectRoot");

  await _writeFile(
    "lib/core/storage/hive_service.dart",
    _hiveServiceContent,
  );

  await _patchConfigService(
    "lib/features/config/config_service.dart",
  );

  await _writeFile(
    "lib/features/day/presentation/day_provider.dart",
    _dayProviderContent,
  );

  await _patchGradientSlider(
    "lib/features/day/presentation/widgets/gradient_slider.dart",
  );

  await _patchCircleEmotions(
    "lib/features/day/presentation/widgets/circle_emotions.dart",
  );

  await _ensureQuickEventAdapter(
    "lib/features/day/data/quick_event.dart",
  );

  await _ensureMain(
    "lib/main.dart",
  );

  print("\nAll done! Next steps:");
  print("1) dart run build_runner build --delete-conflicting-outputs (если используешь генерацию)");
  print("2) flutter run");
}

// ============ Helpers ============
Future<void> _writeFile(String path, String content) async {
  final file = File(path);
  await file.create(recursive: true);
  await file.writeAsString(content);
  print("Wrote: $path");
}

Future<void> _patchFile(String path, String Function(String) patcher,
    {bool required = true}) async {
  final file = File(path);
  if (!await file.exists()) {
    if (required) {
      stderr.writeln("ERROR: File not found: $path");
    } else {
      print("Skip (not found): $path");
    }
    return;
  }
  final original = await file.readAsString();
  final updated = patcher(original);
  if (original != updated) {
    await file.writeAsString(updated);
    print("Patched: $path");
  } else {
    print("No changes: $path");
  }
}

Future<void> _patchConfigService(String path) async {
  await _patchFile(path, (src) {
    // Replace defaultConfig block
    final defStart = "static UserConfig get defaultConfig";
    if (src.contains(defStart)) {
      src = src.replaceFirst(
        RegExp(r"static UserConfig get defaultConfig\s*\{[\s\S]*?\}\n"),
        _configDefaultReplacement,
      );
    }

    // Patch save() to validate scale
    if (src.contains("static Future<void> save(UserConfig cfg) async {")) {
      src = src.replaceFirst(
        RegExp(r"static Future<void> save\(UserConfig cfg\) async \{[\s\S]*?\}"),
        _configSaveReplacement,
      );
    }

    return src;
  });
}

Future<void> _patchGradientSlider(String path) async {
  await _patchFile(path, (_) => _gradientSliderContent, required: false);
}

Future<void> _patchCircleEmotions(String path) async {
  await _patchFile(path, (src) {
    if (!src.contains("_buildItem(BuildContext ctx")) {
      // If structure differs, just overwrite file
      return _circleEmotionsFullContent;
    }
    // Replace _buildItem implementation with the new one.
    src = src.replaceFirst(
      RegExp(r"Widget _buildItem\([\s\S]*?\)\s*\{[\s\S]*?\}\s*\}?\s*$"),
      _circleEmotionsBuildItemReplacement,
    );
    // Ensure constants appear once
    if (!src.contains("_buttonSize")) {
      src = src.replaceFirst(
        "class CircleEmotions extends StatelessWidget {",
        "class CircleEmotions extends StatelessWidget {\n  static const double _buttonSize = 56;\n  static const double _labelWidth = 80;",
      );
    }
    return src;
  }, required: false);
}

Future<void> _ensureQuickEventAdapter(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    stderr.writeln("WARNING: quick_event.dart not found, skip adapter injection");
    return;
  }
  final src = await file.readAsString();
  if (src.contains("class QuickEventAdapter extends TypeAdapter<QuickEvent>")) {
    print("QuickEventAdapter already exists");
    return;
  }
  final updated = "$src\n\n$_quickEventAdapterContent\n";
  await file.writeAsString(updated);
  print("Injected QuickEventAdapter into: $path");
}

Future<void> _ensureMain(String path) async {
  final file = File(path);
  if (await file.exists()) {
    print("main.dart exists, skip creation");
    return;
  }
  await _writeFile(path, _mainContent);
}

// ============ Contents ============

const _hiveServiceContent = r'''
import "package:hive_flutter/hive_flutter.dart";
import "package:flutter/foundation.dart";
import "package:it_kqt_mood/features/config/data/user_config_model.dart";
import "package:it_kqt_mood/features/day/data/quick_event.dart";

class HiveService {
  static late Box<UserConfig> _configBox;
  static late Box<QuickEvent> _quickBox;

  static Box<QuickEvent> get quickBox => _quickBox;
  static Box<UserConfig> get configBox => _configBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(EmotionConfigAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(UserConfigAdapter());
    }
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(QuickEventAdapter());
    }

    _configBox = await Hive.openBox<UserConfig>("user_config_box");
    _quickBox = await Hive.openBox<QuickEvent>("quick_event_box");

    if (kDebugMode) {
      // debug logs if needed
    }
  }
}
''';

const _configDefaultReplacement = r'''
static UserConfig get defaultConfig {
  return UserConfig(
    scaleMin: 0,
    scaleMax: 10,
    emotions: [
      EmotionConfig(id: "joy", name: "Радость", emoji: "😊", color: 0xFFFFC107),
      EmotionConfig(id: "sadness", name: "Грусть", emoji: "😢", color: 0xFF2196F3),
      EmotionConfig(id: "anger", name: "Злость", emoji: "😠", color: 0xFFF44336),
      EmotionConfig(id: "anxiety", name: "Тревога", emoji: "😰", color: 0xFF7E57C2),
      EmotionConfig(id: "calm", name: "Спокойствие", emoji: "😌", color: 0xFF26A69A),
      EmotionConfig(id: "excitement", name: "Воодушевление", emoji: "🤩", color: 0xFFFF7043),
      EmotionConfig(id: "irritation", name: "Раздражение", emoji: "😤", color: 0xFF8D6E63),
      EmotionConfig(id: "confusion", name: "Растерянность", emoji: "😕", color: 0xFF9E9D24),
      EmotionConfig(id: "boredom", name: "Скука", emoji: "🥱", color: 0xFF78909C),
      EmotionConfig(id: "pride", name: "Гордость", emoji: "😌", color: 0xFFAB47BC),
    ],
  );
}
''';

const _configSaveReplacement = r'''
static Future<void> save(UserConfig cfg) async {
  var fixed = cfg;
  if (cfg.scaleMin >= cfg.scaleMax) {
    fixed = cfg.copyWith(scaleMin: 0, scaleMax: 10);
  }
  await _box.put(key, fixed);
}
''';

const _dayProviderContent = r'''
import "dart:math";
import "package:flutter/foundation.dart";
import "package:uuid/uuid.dart";
import "package:it_kqt_mood/features/config/data/user_config_model.dart";
import "package:it_kqt_mood/features/config/data/config_service.dart";
import "package:it_kqt_mood/features/day/data/quick_event.dart";
import "package:it_kqt_mood/features/day/data/quick_event_repository.dart";

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
  late UserConfig config;
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
    final validatedIntensity = intensity.clamp(config.scaleMin, config.scaleMax);
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

const _gradientSliderContent = r'''
import "package:flutter/material.dart";

class GradientSlider extends StatefulWidget {
  final double min;
  final double max;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const GradientSlider({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  State<GradientSlider> createState() => _GradientSliderState();
}

class _GradientSliderState extends State<GradientSlider> {
  late double _value;

  static const double _trackHeight = 8.0;

  @override
  void initState() {
    super.initState();
    _value = widget.value.clamp(widget.min, widget.max);
  }

  @override
  void didUpdateWidget(covariant GradientSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.min != widget.min ||
        oldWidget.max != widget.max) {
      _value = widget.value.clamp(widget.min, widget.max);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ((_value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
    final active = Color.lerp(widget.color.withOpacity(0.4), widget.color, t)!;

    final divisionsDouble = (widget.max - widget.min);
    final isIntScale = divisionsDouble == divisionsDouble.roundToDouble();
    final divisions = isIntScale ? divisionsDouble.toInt() : null;

    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: _trackHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_trackHeight / 2),
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.2),
                widget.color,
              ],
            ),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: active,
            inactiveTrackColor: widget.color.withOpacity(0.25),
            thumbColor: active,
            overlayColor: active.withOpacity(0.15),
          ),
          child: Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: divisions,
            label: isIntScale ? _value.toInt().toString() : _value.toStringAsFixed(1),
            onChanged: (v) {
              setState(() => _value = v);
              widget.onChanged(v);
            },
          ),
        ),
        Row(
          children: [
            Text(widget.min.toStringAsFixed(isIntScale ? 0 : 1), style: textStyle),
            const Spacer(),
            Text(
              isIntScale ? _value.toInt().toString() : _value.toStringAsFixed(1),
              style: textStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(widget.max.toStringAsFixed(isIntScale ? 0 : 1), style: textStyle),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                setState(() => _value = widget.min);
                widget.onChanged(_value);
              },
              child: const Text("Сброс"),
            ),
          ],
        ),
      ],
    );
  }
}
''';

const _circleEmotionsBuildItemReplacement = r'''
Widget _buildItem(BuildContext ctx, int index, int total, double r, CircleEmotionItem item, double emojiSize) {
  final angle = (2 * math.pi / total) * index - math.pi / 2;
  final cx = r * math.cos(angle);
  final cy = r * math.sin(angle);

  return Positioned(
    left: cx + r + 40 - (_buttonSize / 2),
    top: cy + r + 40 - (_buttonSize / 2),
    child: Tooltip(
      message: item.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(_buttonSize / 2),
        onTap: () => onTap(item),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _buttonSize,
              height: _buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.color.withOpacity(0.12),
                border: Border.all(color: item.color.withOpacity(0.6)),
              ),
              alignment: Alignment.center,
              child: Text(item.emoji, style: TextStyle(fontSize: emojiSize)),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: _labelWidth,
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
''';

const _circleEmotionsFullContent = r'''
import "dart:math" as math;
import "package:flutter/material.dart";

class CircleEmotionItem {
  final String id;
  final String label;
  final String emoji;
  final Color color;

  CircleEmotionItem({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
  });
}

class CircleEmotions extends StatelessWidget {
  final List<CircleEmotionItem> items;
  final void Function(CircleEmotionItem) onTap;
  final double minRadius;
  final double maxEmojiSize;

  const CircleEmotions({
    super.key,
    required this.items,
    required this.onTap,
    this.minRadius = 70,
    this.maxEmojiSize = 28,
  });

  static const double _buttonSize = 56;
  static const double _labelWidth = 80;

  @override
  Widget build(BuildContext context) {
    final count = items.length.clamp(1, 999);
    final radius = minRadius + (count > 8 ? (count - 8) * 6.0 : 0.0);
    final emojiSize = (maxEmojiSize - (count > 10 ? (count - 10) * 1.2 : 0))
        .clamp(18, maxEmojiSize);

    return Center(
      child: SizedBox(
        width: radius * 2 + 80,
        height: radius * 2 + 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.25),
              ),
            ),
            for (int i = 0; i < count; i++)
              _buildItem(context, i, count, radius, items[i], emojiSize.toDouble()),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext ctx, int index, int total, double r, CircleEmotionItem item, double emojiSize) {
    final angle = (2 * math.pi / total) * index - math.pi / 2;
    final cx = r * math.cos(angle);
    final cy = r * math.sin(angle);

    return Positioned(
      left: cx + r + 40 - (_buttonSize / 2),
      top: cy + r + 40 - (_buttonSize / 2),
      child: Tooltip(
        message: item.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(_buttonSize / 2),
          onTap: () => onTap(item),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _buttonSize,
                height: _buttonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.color.withOpacity(0.12),
                  border: Border.all(color: item.color.withOpacity(0.6)),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: TextStyle(fontSize: emojiSize)),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: _labelWidth,
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''';

const _quickEventAdapterContent = r'''
import "package:hive/hive.dart";

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

const _mainContent = r'''
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:it_kqt_mood/core/storage/hive_service.dart";
import "package:it_kqt_mood/features/day/presentation/day_provider.dart";
// TODO: update with your actual HomePage import
// import "package:it_kqt_mood/features/day/presentation/pages/home_page.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DayProvider()..init()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Дневник настроения",
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text("Стартовый экран")),
          body: const Center(child: Text("Подключи HomePage и замени стартовый экран")),
        ),
      ),
    );
  }
}
''';