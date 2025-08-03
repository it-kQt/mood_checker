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

@override
void initState() {
super.initState();
_value = widget.value;
}

@override
void didUpdateWidget(covariant GradientSlider oldWidget) {
super.didUpdateWidget(oldWidget);
_value = widget.value;
}

@override
Widget build(BuildContext context) {
final t = (_value - widget.min) / (widget.max - widget.min);
final active = Color.lerp(Colors.yellow, widget.color, t.clamp(0, 1))!;
return Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Container(
height: 8,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(4),
gradient: LinearGradient(
colors: [Colors.yellow, widget.color],
),
),
),
SliderTheme(
data: SliderTheme.of(context).copyWith(
activeTrackColor: active,
inactiveTrackColor: widget.color.withOpacity(0.25),
thumbColor: active,
),
child: Slider(
value: _value,
min: widget.min,
max: widget.max,
divisions: (widget.max - widget.min).round(),
onChanged: (v) {
setState(() => _value = v);
widget.onChanged(v);
},
),
),
],
);
}
}
