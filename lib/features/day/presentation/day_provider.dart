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
    try {
      isLoading = true;
      notifyListeners();

      // ConfigService.init уже выполнен в main(), здесь — только загрузка
      config = await ConfigService.loadOrCreate();
      await refreshToday();
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
