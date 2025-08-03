import "package:it_kqt_mood/core/storage/hive_service.dart";
import "quick_event.dart";

abstract class IQuickEventRepository {
Future<void> add(QuickEvent event);
Future<void> delete(String id);
Future<List<QuickEvent>> listByDay(DateTime day);
}

class QuickEventRepository implements IQuickEventRepository {
@override
Future<void> add(QuickEvent event) async {
await HiveService.quickBox.put(event.id, event);
}

@override
Future<void> delete(String id) async {
await HiveService.quickBox.delete(id);
}

@override
Future<List<QuickEvent>> listByDay(DateTime day) async {
final box = HiveService.quickBox;
final start = DateTime(day.year, day.month, day.day);
final end = start.add(const Duration(days: 1));
final res = box.values.where((e) =>
e.dateTime.isAfter(start.subtract(const Duration(microseconds: 1))) &&
e.dateTime.isBefore(end)
).toList();
res.sort((a, b) => b.dateTime.compareTo(a.dateTime));
return res;
}
}
