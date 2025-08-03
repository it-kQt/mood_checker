import "package:hive/hive.dart";

part "quick_event.g.dart";

@HiveType(typeId: 30)
class QuickEvent extends HiveObject {
@HiveField(0)
String id;

@HiveField(1)
DateTime dateTime;

@HiveField(2)
String emotionId; // ссылка на EmotionConfig.id

@HiveField(3)
int intensity; // scaleMin..scaleMax

@HiveField(4)
String note;

QuickEvent({
required this.id,
required this.dateTime,
required this.emotionId,
required this.intensity,
this.note = "",
});
}



