import 'package:flutter/foundation.dart';
import 'package:it_kqt_mood/features/mood/data/mood_model.dart';
import 'package:it_kqt_mood/features/mood/data/mood_repository.dart';

class MoodProvider extends ChangeNotifier {
final IMoodRepository repository;
MoodProvider(this.repository);

List<MoodEntry> _items = [];
List<MoodEntry> get items => _items;

bool _loading = false;
bool get isLoading => _loading;

Future<void> load() async {
_loading = true;
notifyListeners();
_items = await repository.getAll();
_loading = false;
notifyListeners();
}

Future<void> add(MoodEntry entry) async {
await repository.add(entry);
await load();
}

Future<void> update(MoodEntry entry) async {
await repository.update(entry);
await load();
}

Future<void> delete(String id) async {
await repository.delete(id);
_items.removeWhere((e) => e.id == id);
notifyListeners();
}
}
