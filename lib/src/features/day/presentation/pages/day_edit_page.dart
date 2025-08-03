import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:it_kqt_mood/features/day/presentation/day_provider.dart";
import "package:it_kqt_mood/features/day/presentation/widgets/gradient_slider.dart";

class DayEditPage extends StatefulWidget {
const DayEditPage({super.key});

@override
State<DayEditPage> createState() => _DayEditPageState();
}

class _DayEditPageState extends State<DayEditPage> {
final Map<String, double> _values = {};
final _noteCtrl = TextEditingController();

@override
void initState() {
super.initState();
final prov = context.read<DayProvider>();
final cfg = prov.config;
final today = prov.today;
for (final emo in cfg.emotions.where((e) => e.enabled)) {
final current = today?.valuesMap[emo.id] ?? cfg.scaleMin;
_values[emo.id] = current.toDouble();
}
_noteCtrl.text = prov.today?.note ?? "";
}

@override
void dispose() {
_noteCtrl.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final prov = context.watch<DayProvider>();
final cfg = prov.config;


return Scaffold(
  appBar: AppBar(
    title: const Text("Как прошел день?"),
    actions: [
      TextButton(
        onPressed: () async {
          final map = _values.map((k, v) => MapEntry(k, v.toInt()));
          await prov.saveDayProfileManual(map, _noteCtrl.text.trim());
          if (mounted) Navigator.pop(context);
        },
        child: const Text("Сохранить"),
      ),
    ],
  ),
  body: ListView(
    padding: const EdgeInsets.all(16),
    children: [
      for (final emo in cfg.emotions.where((e) => e.enabled)) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${emo.emoji} ${emo.name}"),
            Text((_values[emo.id] ?? cfg.scaleMin.toDouble()).toInt().toString()),
          ],
        ),
        GradientSlider(
          min: cfg.scaleMin.toDouble(),
          max: cfg.scaleMax.toDouble(),
          color: Color(emo.color),
          value: _values[emo.id] ?? cfg.scaleMin.toDouble(),
          onChanged: (v) => setState(() => _values[emo.id] = v),
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 16),
      const Text("Заметка", style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextField(
        controller: _noteCtrl,
        minLines: 3,
        maxLines: 6,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: "Опишите, как прошел день",
        ),
      ),
    ],
  ),
);
}
}
