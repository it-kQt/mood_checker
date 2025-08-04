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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prov = context.read<DayProvider>();
    final cfg = prov.config!;
    final today = prov.today;
    for (final emo in cfg.emotions.where((e) => e.enabled)) {
      final current = today?.values[emo.id] ?? cfg.scaleMin;
      _values[emo.id] = (current).toDouble();
    }
    _noteCtrl.text = prov.today?.note ?? "";
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final prov = context.read<DayProvider>();
    try {
      final map = _values.map((k, v) => MapEntry(k, v.round()));
      for (final entry in map.entries) {
        await prov.addQuickEvent(
          emotionId: entry.key,
          intensity: entry.value,
          note: _noteCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(); // закрыть экран
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка сохранения: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DayProvider>();
    final cfg = prov.config!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Как прошел день?"),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const Text("...") : const Text("Сохранить"),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final emo in cfg.emotions.where((e) => e.enabled)) ...[
            InkWell(
              onTap: () {
                setState(() {
                  _values[emo.id] = cfg.scaleMin.toDouble();
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${emo.emoji} ${emo.name}"),
                  Text((_values[emo.id] ?? cfg.scaleMin.toDouble()).round().toString()),
                ],
              ),
            ),
            const SizedBox(height: 6),
            GradientSlider(
              showResetButton: false,
              min: cfg.scaleMin.toDouble(),
              max: cfg.scaleMax.toDouble(),
              color: Color(emo.color),
              value: (_values[emo.id] ?? cfg.scaleMin.toDouble()),
              onChanged: (v) => setState(() => _values[emo.id] = v),
            ),
            const SizedBox(height: 12),
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

