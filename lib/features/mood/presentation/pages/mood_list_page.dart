import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:it_kqt_mood/features/mood/presentation/mood_provider.dart';
import 'package:it_kqt_mood/features/mood/presentation/widgets/mood_card.dart';
import 'package:it_kqt_mood/features/mood/data/mood_model.dart';
import 'package:it_kqt_mood/features/mood/presentation/pages/mood_edit_page.dart';

class MoodListPage extends StatefulWidget {
const MoodListPage({super.key});

@override
State<MoodListPage> createState() => _MoodListPageState();
}

class _MoodListPageState extends State<MoodListPage> {
@override
void initState() {
super.initState();
Future.microtask(() => context.read<MoodProvider>().load());
}

@override
Widget build(BuildContext context) {
final provider = context.watch<MoodProvider>();
return Scaffold(
appBar: AppBar(
title: const Text('Дневник настроения'),
),
body: provider.isLoading
? const Center(child: CircularProgressIndicator())
: provider.items.isEmpty
? const Center(child: Text('Пока нет записей. Нажмите + чтобы добавить.'))
: ListView.builder(
itemCount: provider.items.length,
itemBuilder: (context, index) {
final entry = provider.items[index];
return MoodCard(
entry: entry,
onTap: () async {
await Navigator.push(
context,
MaterialPageRoute(
builder: (context) => MoodEditPage(existing: entry),
),
);
},
onDelete: () => provider.delete(entry.id),
);
},
),
floatingActionButton: FloatingActionButton(
onPressed: () async {
await Navigator.push(
context,
MaterialPageRoute(builder: (context) => const MoodEditPage()),
);
},
child: const Icon(Icons.add),
),
);
}
}
