import "package:hive/hive.dart";
part "user_config_model.g.dart";

@HiveType(typeId: 10)
class EmotionConfig extends HiveObject {
@HiveField(0)
String id; // стабильный ключ, например "anger" или пользовательский "my_custom"

@HiveField(1)
String name; // отображаемое имя (RU)

@HiveField(2)
String emoji; // например "😡"

@HiveField(3)
int color; // ARGB int

@HiveField(4)
bool enabled;

EmotionConfig({
required this.id,
required this.name,
required this.emoji,
required this.color,
this.enabled = true,
});

EmotionConfig copyWith({
String? id,
String? name,
String? emoji,
int? color,
bool? enabled,
}) {
return EmotionConfig(
id: id ?? this.id,
name: name ?? this.name,
emoji: emoji ?? this.emoji,
color: color ?? this.color,
enabled: enabled ?? this.enabled,
);
}

Map<String, dynamic> toJson() => {
"id": id,
"name": name,
"emoji": emoji,
"color": color,
"enabled": enabled,
};

factory EmotionConfig.fromJson(Map<String, dynamic> json) => EmotionConfig(
id: json["id"] as String,
name: json["name"] as String,
emoji: json["emoji"] as String,
color: (json["color"] as num).toInt(),
enabled: (json["enabled"] as bool?) ?? true,
);
}

@HiveType(typeId: 11)
class UserConfig extends HiveObject {
@HiveField(0)
int scaleMin; // например 0

@HiveField(1)
int scaleMax; // например 10

@HiveField(2)
List<EmotionConfig> emotions;

UserConfig({
required this.scaleMin,
required this.scaleMax,
required this.emotions,
});

Map<String, dynamic> toJson() => {
"scaleMin": scaleMin,
"scaleMax": scaleMax,
"emotions": emotions.map((e) => e.toJson()).toList(),
};

factory UserConfig.fromJson(Map<String, dynamic> json) => UserConfig(
scaleMin: (json["scaleMin"] as num).toInt(),
scaleMax: (json["scaleMax"] as num).toInt(),
emotions: (json["emotions"] as List)
.map((e) => EmotionConfig.fromJson(Map<String, dynamic>.from(e)))
.toList(),
);

UserConfig copyWith({
int? scaleMin,
int? scaleMax,
List<EmotionConfig>? emotions,
}) {
return UserConfig(
scaleMin: scaleMin ?? this.scaleMin,
scaleMax: scaleMax ?? this.scaleMax,
emotions: emotions ?? this.emotions,
);
}
}
