import "package:hive/hive.dart";

part "day_profile.g.dart";

// Храним значения эмоций как список пар ключ-значение, чтобы быть устойчивыми к изменению набора эмоций.
@HiveType(typeId: 21)
class KeyValueInt {
@HiveField(0)
String key;

@HiveField(1)
int value;

KeyValueInt(this.key, this.value);
}

@HiveType(typeId: 20)
class DayProfile extends HiveObject {
@HiveField(0)
String id; // yyyy-MM-dd

@HiveField(1)
DateTime date;

@HiveField(2)
List<KeyValueInt> values; // эмоция -> шкала

@HiveField(3)
String note;

DayProfile({
required this.id,
required this.date,
required this.values,
this.note = "",
});

Map<String, int> get valuesMap => {
for (final kv in values) kv.key: kv.value,
};

DayProfile copyWith({
String? id,
DateTime? date,
List<KeyValueInt>? values,
String? note,
}) {
return DayProfile(
id: id ?? this.id,
date: date ?? this.date,
values: values ?? this.values,
note: note ?? this.note,
);
}
}
