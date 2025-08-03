import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/preset.dart';
import '../model/settings_model.dart';

class SliderPreview extends StatefulWidget {
  const SliderPreview({super.key});
  @override
  State<SliderPreview> createState() => _SliderPreviewState();
}

class _SliderPreviewState extends State<SliderPreview> {
  double v1 = 0.2, v2 = 0.6, v3 = 0.85;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsModel>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Превью', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _buildSlider('Subtle', AnimationType.subtle, (x) => setState(() => v1 = x), v1),
        _buildSlider('Flow', AnimationType.flow, (x) => setState(() => v2 = x), v2),
        _buildSlider('ValueBased', AnimationType.valueBased, (x) => setState(() => v3 = x), v3),
        const SizedBox(height: 24),
        Text('Текущий пресет: ${s.activePreset?.name ?? '-'}'),
      ],
    );
  }

  Widget _buildSlider(String label, AnimationType a, ValueChanged<double> onChanged, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(value: value, onChanged: onChanged),
      ],
    );
  }
}
