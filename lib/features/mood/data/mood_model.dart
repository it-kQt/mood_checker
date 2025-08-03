import 'package:hive/hive.dart';

part 'mood_model.g.dart';

@HiveType(typeId: 1)
enum MoodEmotion {
@HiveField(0)
happy,
@HiveField(1)
neutral,
@HiveField(2)
sad,
@HiveField(3)
angry,
@HiveField(4)
anxious,
@HiveField(5)
excited,
}

@HiveType(typeId: 2)
class MoodEntry extends HiveObject {
@HiveField(0)
String id;

@HiveField(1)
DateTime date;

@HiveField(2)
MoodEmotion emotion;

@HiveField(3)
int score; // 1..10

@HiveField(4)
String note;

MoodEntry({
required this.id,
required this.date,
required this.emotion,
required this.score,
required this.note,
});

MoodEntry copyWith({
String? id,
DateTime? date,
MoodEmotion? emotion,
int? score,
String? note,
}) {
return MoodEntry(
id: id ?? this.id,
date: date ?? this.date,
emotion: emotion ?? this.emotion,
score: score ?? this.score,
note: note ?? this.note,
);
}
}
