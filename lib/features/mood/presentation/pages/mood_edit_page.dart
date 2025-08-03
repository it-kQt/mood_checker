import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:it_kqt_mood/features/mood/data/mood_model.dart";
import "package:it_kqt_mood/features/mood/presentation/mood_provider.dart";
import "package:uuid/uuid.dart";

class MoodEditPage extends StatefulWidget {
final MoodEntry? existing;
const MoodEditPage({super.key, this.existing});

@override
State<MoodEditPage> createState() => _MoodEditPageState();
}

class _MoodEditPageState extends State<MoodEditPage> {
late MoodEmotion _emotion;
double _score = 5;
final _noteController = TextEditingController();

@override
void initState() {
super.initState();
if (widget.existing != null) {
_emotion = widget.existing!.emotion;
_score = widget.existing!.score.toDouble();
_noteController.text = widget.existing!.note;
} else {
_emotion = MoodEmotion.neutral;
_score = 5;
}
}

@override
void dispose() {
_noteController.dispose();
super.dispose();
}

String _emotionLabel(MoodEmotion e) {
switch (e) {
case MoodEmotion.happy: return "Радость";
case MoodEmotion.neutral: return "Нейтрально";
case MoodEmotion.sad: return "Грусть";
case MoodEmotion.angry: return "Злость";
case MoodEmotion.anxious: return "Тревога";
case MoodEmotion.excited: return "Возбуждение";
}
}

@override
Widget build(BuildContext context) {
final isEdit = widget.existing != null;
return Scaffold(
appBar: AppBar(
title: Text(isEdit ? "Редактирование" : "Новая запись"),
actions: [
TextButton(
onPressed: () async {
final provider = context.read<MoodProvider>();
if (isEdit) {
final updated = widget.existing!.copyWith(
emotion: _emotion,
score: _score.toInt(),
note: _noteController.text.trim(),
);
await provider.update(updated);
} else {
final id = const Uuid().v4();
final entry = MoodEntry(
id: id,
date: DateTime.now(),
emotion: _emotion,
score: _score.toInt(),
note: _noteController.text.trim(),
);
await provider.add(entry);
}
if (mounted) Navigator.pop(context);
},
child: const Text("Сохранить"),
),
],
),
body: ListView(
padding: const EdgeInsets.all(16),
children: [
const Text("Эмоция", style: TextStyle(fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
DropdownButtonFormField<MoodEmotion>(
value: _emotion,
items: MoodEmotion.values
.map((e) => DropdownMenuItem(
value: e,
child: Text(_emotionLabel(e)),
))
.toList(),
onChanged: (v) => setState(() => _emotion = v ?? _emotion),
),
const SizedBox(height: 24),
Row(
children: [
const Text("Оценка"),
const SizedBox(width: 12),
Text(_score.toInt().toString()),
],
),
Slider(
value: _score,
min: 1,
max: 10,
divisions: 9,
label: _score.toInt().toString(),
onChanged: (v) => setState(() => _score = v),
),
const SizedBox(height: 24),
const Text("Заметка", style: TextStyle(fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
TextField(
controller: _noteController,
minLines: 3,
maxLines: 6,
decoration: const InputDecoration(
border: OutlineInputBorder(),
hintText: "Как прошел день? Что повлияло на настроение?",
),
),
],
),
);
}
}
