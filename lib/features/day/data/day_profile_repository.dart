import "package:it_kqt_mood/core/storage/hive_service.dart";
import "day_profile.dart";

abstract class IDayProfileRepository {
Future<DayProfile?> getById(String id);
Future<void> upsert(DayProfile profile);
Future<List<DayProfile>> listByRange(DateTime from, DateTime to);
}

class DayProfileRepository implements IDayProfileRepository {
@override
Future<DayProfile?> getById(String id) async {
final box = HiveService.dayBox;
return box.get(id);
}

@override
Future<void> upsert(DayProfile profile) async {
final box = HiveService.dayBox;
await box.put(profile.id, profile);
}

@override
Future<List<DayProfile>> listByRange(DateTime from, DateTime to) async {
final box = HiveService.dayBox;
final items = box.values.where((e) {
final d = DateTime(e.date.year, e.date.month, e.date.day);
final f = DateTime(from.year, from.month, from.day);
final t = DateTime(to.year, to.month, to.day);
return (d.isAtSameMomentAs(f) || d.isAfter(f)) &&
(d.isAtSameMomentAs(t) || d.isBefore(t));
}).toList();
items.sort((a, b) => b.date.compareTo(a.date));
return items;
}
}
