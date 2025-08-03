import "package:hive_flutter/hive_flutter.dart";
import "package:flutter/foundation.dart";
import "package:it_kqt_mood/features/config/user_config_model.dart";
import "package:it_kqt_mood/features/quick/data/quick_event.dart";

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
