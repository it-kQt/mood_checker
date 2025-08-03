import "dart:convert";
import "package:hive_flutter/hive_flutter.dart";
import "package:flutter/material.dart";
import "user_config_model.dart";

class ConfigService {
static const String boxName = "user_config_box";
static const String key = "user_config";

static Future<void> init() async {
if (!Hive.isAdapterRegistered(10)) {
Hive.registerAdapter(EmotionConfigAdapter());
}
if (!Hive.isAdapterRegistered(11)) {
Hive.registerAdapter(UserConfigAdapter());
}
await Hive.openBox<UserConfig>(boxName);
}

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

static Box<UserConfig> get _box => Hive.box<UserConfig>(boxName);

static Future<UserConfig> loadOrCreate() async {
final existing = _box.get(key);
if (existing != null) return existing;
final def = defaultConfig;
await _box.put(key, def);
return def;
}

static Future<void> save(UserConfig cfg) async {
  var fixed = cfg;
  if (cfg.scaleMin >= cfg.scaleMax) {
    fixed = cfg.copyWith(scaleMin: 0, scaleMax: 10);
  }
  await _box.put(key, fixed);
}


// Экспорт/импорт JSON
static String exportJson(UserConfig cfg) => jsonEncode(cfg.toJson());

static Future<UserConfig> importJson(String jsonStr) async {
final map = jsonDecode(jsonStr) as Map<String, dynamic>;
final cfg = UserConfig.fromJson(map);
await save(cfg);
return cfg;
}
}
