import 'package:it_kqt_mood/core/storage/hive_service.dart';
import 'package:it_kqt_mood/features/mood/data/mood_model.dart';

abstract class IMoodRepository {
Future<List<MoodEntry>> getAll();
Future<void> add(MoodEntry entry);
Future<void> update(MoodEntry entry);
Future<void> delete(String id);
}

class MoodRepository implements IMoodRepository {
@override
Future<List<MoodEntry>> getAll() async {
final box = HiveService.moodBox;
return box.values.toList()
..sort((a, b) => b.date.compareTo(a.date));
}

@override
Future<void> add(MoodEntry entry) async {
final box = HiveService.moodBox;
await box.put(entry.id, entry);
}

@override
Future<void> update(MoodEntry entry) async {
final box = HiveService.moodBox;
await box.put(entry.id, entry);
}

@override
Future<void> delete(String id) async {
final box = HiveService.moodBox;
await box.delete(id);
}
}
