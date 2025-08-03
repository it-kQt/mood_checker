import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:it_kqt_mood/features/day/presentation/day_provider.dart";
import "package:it_kqt_mood/features/day/presentation/pages/day_edit_page.dart";
import "package:it_kqt_mood/features/day/presentation/widgets/gradient_slider.dart";
import "package:it_kqt_mood/features/day/presentation/widgets/circle_emotions.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _openQuickDialog({
    required String emotionId,
    required String emoji,
    required String label,
    required Color color,
  }) {
    final prov = context.read<DayProvider>();
    final cfg = prov.config!;
    final double min = cfg.scaleMin.toDouble();
    final double max = cfg.scaleMax.toDouble();
    double value = min;
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Text(label, style: Theme.of(ctx).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GradientSlider(
                min: min,
                max: max,
                color: color,
                value: value,
                onChanged: (v) {
                  value = v;
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: "Комментарий (опционально)",
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await prov.addQuickEvent(
                      emotionId: emotionId,
                      intensity: value.round(),
                      note: noteCtrl.text.trim(),
                    );
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: const Text("Сохранить"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DayProvider>();

    if (prov.isLoading || prov.config == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final cfg = prov.config!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Дневник настроения"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Экспресс-эмоции", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          CircleEmotions(
            items: [
              for (final e in cfg.emotions.where((e) => e.enabled))
                CircleEmotionItem(
                  id: e.id,
                  label: e.name,
                  emoji: e.emoji,
                  color: Color(e.color),
                ),
            ],
            onTap: (item) => _openQuickDialog(
              emotionId: item.id,
              emoji: item.emoji,
              label: item.label,
              color: item.color,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text("Итоги дня", style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DayEditPage()),
                  );
                  await context.read<DayProvider>().refreshToday();
                },
                child: const Text("Редактировать"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (prov.today == null)
            const Text("Пока нет данных за сегодня.")
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: prov.today!.values.entries.map((kv) {
                    final emo = cfg.emotions.firstWhere(
                      (e) => e.id == kv.key,
                      orElse: () => cfg.emotions.first,
                    );
                    return Chip(
                      label: Text("${emo.emoji} ${emo.name}: ${kv.value}"),
                    );
                  }).toList(),
                ),
                if (prov.today!.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(prov.today!.note),
                ],
              ],
            ),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DayEditPage()),
          );
          await context.read<DayProvider>().refreshToday();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
