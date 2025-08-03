import "package:flutter/material.dart";

class GradientSlider extends StatefulWidget {
  final double min;
  final double max;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const GradientSlider({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  State<GradientSlider> createState() => _GradientSliderState();
}

class _GradientSliderState extends State<GradientSlider> {
  late double _value;

  static const double _trackHeight = 8.0;

  @override
  void initState() {
    super.initState();
    _value = widget.value.clamp(widget.min, widget.max);
  }

  @override
  void didUpdateWidget(covariant GradientSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.min != widget.min ||
        oldWidget.max != widget.max) {
      _value = widget.value.clamp(widget.min, widget.max);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ((_value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
    final active = Color.lerp(widget.color.withOpacity(0.4), widget.color, t)!;

    final divisionsDouble = (widget.max - widget.min);
    final isIntScale = divisionsDouble == divisionsDouble.roundToDouble();
    final divisions = isIntScale ? divisionsDouble.toInt() : null;

    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: _trackHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_trackHeight / 2),
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.2),
                widget.color,
              ],
            ),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: active,
            inactiveTrackColor: widget.color.withOpacity(0.25),
            thumbColor: active,
            overlayColor: active.withOpacity(0.15),
          ),
          child: Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: divisions,
            label: isIntScale ? _value.toInt().toString() : _value.toStringAsFixed(1),
            onChanged: (v) {
              setState(() => _value = v);
              widget.onChanged(v);
            },
          ),
        ),
        Row(
          children: [
            Text(widget.min.toStringAsFixed(isIntScale ? 0 : 1), style: textStyle),
            const Spacer(),
            Text(
              isIntScale ? _value.toInt().toString() : _value.toStringAsFixed(1),
              style: textStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(widget.max.toStringAsFixed(isIntScale ? 0 : 1), style: textStyle),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                setState(() => _value = widget.min);
                widget.onChanged(_value);
              },
              child: const Text("Сброс"),
            ),
          ],
        ),
      ],
    );
  }
}
