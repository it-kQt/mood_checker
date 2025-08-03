import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/preset.dart';
import '../model/settings_model.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsModel>();
    final presets = s.availablePresets;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const ListTile(title: Text('Настройки', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const Divider(),
            const Padding(padding: EdgeInsets.only(top: 8), child: Text('Пресет')),
            DropdownButton<String>(
              value: s.activePresetId ?? (presets.isNotEmpty ? presets.first.id : null),
              items: presets.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
              onChanged: (v) { if (v != null) s.setPreset(v); },
            ),
            const SizedBox(height: 12),
            const Text('Анимация трека'),
            SegmentedButton<AnimationType>(
              segments: const [
                ButtonSegment(value: AnimationType.subtle, label: Text('Subtle')),
                ButtonSegment(value: AnimationType.flow, label: Text('Flow')),
                ButtonSegment(value: AnimationType.valueBased, label: Text('Value')),
              ],
              selected: {s.animationType},
              onSelectionChanged: (v) => s.setAnimation(v.first),
            ),
            const SizedBox(height: 12),
            const Text('Форма ползунка'),
            SegmentedButton<ThumbShape>(
              segments: const [
                ButtonSegment(value: ThumbShape.circle, label: Text('Круг')),
                ButtonSegment(value: ThumbShape.square, label: Text('Квадр')),
                ButtonSegment(value: ThumbShape.arrow, label: Text('Стрелка')),
              ],
              selected: {s.thumbShape},
              onSelectionChanged: (v) => s.setThumb(v.first),
            ),
            const SizedBox(height: 12),
            const Text('Стиль трека'),
            SegmentedButton<TrackStyle>(
              segments: const [
                ButtonSegment(value: TrackStyle.rounded, label: Text('Скругл')),
                ButtonSegment(value: TrackStyle.straight, label: Text('Прямой')),
                ButtonSegment(value: TrackStyle.gradient, label: Text('Градиент')),
              ],
              selected: {s.trackStyle},
              onSelectionChanged: (v) => s.setTrack(v.first),
            ),
            const SizedBox(height: 12),
            const Text('Тики'),
            SegmentedButton<TickStyle>(
              segments: const [
                ButtonSegment(value: TickStyle.none, label: Text('Нет')),
                ButtonSegment(value: TickStyle.dots, label: Text('Точки')),
                ButtonSegment(value: TickStyle.lines, label: Text('Линии')),
              ],
              selected: {s.tickStyle},
              onSelectionChanged: (v) => s.setTicks(v.first),
            ),
          ],
        ),
      ),
    );
  }
}
