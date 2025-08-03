import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:it_kqt_mood/features/mood/data/mood_model.dart';

class MoodCard extends StatelessWidget {
final MoodEntry entry;
final VoidCallback? onTap;
final VoidCallback? onDelete;

const MoodCard({
super.key,
required this.entry,
this.onTap,
this.onDelete,
});

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
final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(entry.date);
return Card(
child: ListTile(
title: Text('${_emotionLabel(entry.emotion)} • ${entry.score}/10'),
subtitle: Text('${entry.note.isEmpty ? "Без заметки" : entry.note}\n$dateStr'),
isThreeLine: true,
onTap: onTap,
trailing: IconButton(
icon: const Icon(Icons.delete_outline),
onPressed: onDelete,
),
),
);
}
}
