import "package:collection/collection.dart";
import "package:it_kqt_mood/features/config/user_config_model.dart";
import "package:it_kqt_mood/features/day/data/day_profile.dart";
import "package:it_kqt_mood/features/day/data/day_profile_repository.dart";
import "package:it_kqt_mood/features/quick/data/quick_event.dart";
import "package:it_kqt_mood/features/quick/data/quick_event_repository.dart";

class AggregationService {
final IDayProfileRepository dayRepo;
final IQuickEventRepository quickRepo;

AggregationService(this.dayRepo, this.quickRepo);

// Стратегия: среднее по интенсивностям quick events за день.
Future<DayProfile> buildOrUpdateDayProfile(DateTime day, UserConfig cfg, {String? existingNote}) async {
final quick = await quickRepo.listByDay(day);
final groups = groupBy<QuickEvent, String>(quick, (e) => e.emotionId);
final map = <String, int>{};


for (final emo in cfg.emotions.where((e) => e.enabled)) {
  final list = groups[emo.id] ?? const [];
  if (list.isEmpty) {
    map[emo.id] = 0;
  } else {
    final avg = list.map((e) => e.intensity).average;
    map[emo.id] = avg.round();
  }
}
final values = map.entries.map((e) => KeyValueInt(e.key, e.value)).toList();

final id = _dayId(day);
final existing = await dayRepo.getById(id);
final profile = DayProfile(
  id: id,
  date: DateTime(day.year, day.month, day.day),
  values: values,
  note: existingNote ?? existing?.note ?? "",
);
await dayRepo.upsert(profile);
return profile;
}

String _dayId(DateTime d) => "${d.year.toString().padLeft(4,"0")}-${d.month.toString().padLeft(2,"0")}-${d.day.toString().padLeft(2,"0")}";
}
