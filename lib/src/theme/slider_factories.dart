import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../model/preset.dart';

class BuiltTrack {
final SliderTrackShape trackShape;
BuiltTrack(this.trackShape);
}

SliderComponentShape buildThumbShape(ThumbShape chosen, ThumbShape presetShape, ColorScheme scheme) {
switch (chosen) {
case ThumbShape.square:
return _SquareThumb(color: scheme.primary);
case ThumbShape.arrow:
return _ArrowThumb(color: scheme.primary);
case ThumbShape.circle:
default:
return const RoundSliderThumbShape(enabledThumbRadius: 10);
}
}

BuiltTrack buildTrackShape(TrackStyle chosen, TrackStyle presetStyle, ColorScheme scheme, List<Color> palette, AnimationType animType) {
switch (chosen) {
case TrackStyle.straight:
return BuiltTrack(const _StraightTrackShape());
case TrackStyle.gradient:
return BuiltTrack(_GradientTrackShape(palette: palette, animationType: animType));
case TrackStyle.rounded:
default:
return BuiltTrack(const _RoundedTrackShape());
}
}

SliderTickMarkShape? buildTickMarkShape(TickStyle chosen, TickStyle presetStyle) {
switch (chosen) {
case TickStyle.dots:
return const RoundSliderTickMarkShape(tickMarkRadius: 2);
case TickStyle.lines:
return const _LineTickMarkShape();
case TickStyle.none:
default:
return SliderTickMarkShape.noTickMark;
}
}

class _SquareThumb extends SliderComponentShape {
final double size;
final Color color;
const _SquareThumb({this.size = 18, required this.color});
@override
Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.square(size);
@override
void paint(PaintingContext context, Offset center, {required Animation<double> activationAnimation, required Animation<double> enableAnimation, required bool isDiscrete, required TextPainter labelPainter, required RenderBox parentBox, required SliderThemeData sliderTheme, required TextDirection textDirection, required double value, required double textScaleFactor, required Size sizeWithOverflow}) {
final canvas = context.canvas;
final r = Rect.fromCenter(center: center, width: size, height: size);
final paint = Paint()..color = color..style = PaintingStyle.fill;
canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), paint);
}
}

class _ArrowThumb extends SliderComponentShape {
final double size;
final Color color;
const _ArrowThumb({this.size = 20, required this.color});
@override
Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(size, size);
@override
void paint(PaintingContext context, Offset center, {required Animation<double> activationAnimation, required Animation<double> enableAnimation, required bool isDiscrete, required TextPainter labelPainter, required RenderBox parentBox, required SliderThemeData sliderTheme, required TextDirection textDirection, required double value, required double textScaleFactor, required Size sizeWithOverflow}) {
final canvas = context.canvas;
final path = Path();
final w = size;
final h = size * 0.8;
path.moveTo(center.dx + w * 0.5, center.dy);
path.lineTo(center.dx - w * 0.2, center.dy - h * 0.5);
path.lineTo(center.dx - w * 0.2, center.dy + h * 0.5);
path.close();
final paint = Paint()..color = color..style = PaintingStyle.fill;
canvas.drawPath(path, paint);
}
}

class _RoundedTrackShape extends RoundedRectSliderTrackShape {
const _RoundedTrackShape();
}

class _StraightTrackShape extends SliderTrackShape {
const _StraightTrackShape();
@override
Rect getPreferredRect({ required RenderBox parentBox, Offset offset = Offset.zero, required SliderThemeData sliderTheme, bool isEnabled = false, bool isDiscrete = false }) {
final trackHeight = sliderTheme.trackHeight ?? 4;
final pad = 16.0;
final trackLeft = offset.dx + pad;
final trackRight = parentBox.size.width - pad;
final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
return Rect.fromLTWH(trackLeft, trackTop, trackRight - trackLeft, trackHeight);
}
@override
void paint(PaintingContext context, Offset offset, { required RenderBox parentBox, required SliderThemeData sliderTheme, required Animation<double> enableAnimation, required Offset thumbCenter, Offset? secondaryOffset, bool isEnabled = false, bool isDiscrete = false, required TextDirection textDirection }) {
final rect = getPreferredRect(parentBox: parentBox, offset: offset, sliderTheme: sliderTheme);
final canvas = context.canvas;
final active = Paint()..color = sliderTheme.activeTrackColor ?? Colors.blue;
final inactive = Paint()..color = (sliderTheme.inactiveTrackColor ?? Colors.grey).withOpacity(0.5);
final left = Rect.fromLTWH(rect.left, rect.top, thumbCenter.dx - rect.left, rect.height);
final right = Rect.fromLTWH(thumbCenter.dx, rect.top, rect.right - thumbCenter.dx, rect.height);
canvas.drawRect(left, active);
canvas.drawRect(right, inactive);


// Необязательная отрисовка secondary-участка, если передан
if (secondaryOffset != null) {
  final secLeft = math.min(thumbCenter.dx, secondaryOffset.dx);
  final secRight = math.max(thumbCenter.dx, secondaryOffset.dx);
  final secRect = Rect.fromLTWH(secLeft, rect.top, secRight - secLeft, rect.height);
  final secondaryPaint = Paint()
    ..color = (sliderTheme.secondaryActiveTrackColor ?? (sliderTheme.activeTrackColor ?? Colors.blue)).withOpacity(0.35);
  canvas.drawRect(secRect, secondaryPaint);
}
}
}

class _GradientTrackShape extends SliderTrackShape {
final List<Color> palette;
final AnimationType animationType;
const _GradientTrackShape({required this.palette, required this.animationType});
@override
Rect getPreferredRect({ required RenderBox parentBox, Offset offset = Offset.zero, required SliderThemeData sliderTheme, bool isEnabled = false, bool isDiscrete = false }) {
final trackHeight = sliderTheme.trackHeight ?? 6;
final horizontalPadding = 16.0;
final trackLeft = offset.dx + horizontalPadding;
final trackRight = parentBox.size.width - horizontalPadding;
final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
return Rect.fromLTWH(trackLeft, trackTop, trackRight - trackLeft, trackHeight);
}
@override
void paint(PaintingContext context, Offset offset, { required RenderBox parentBox, required SliderThemeData sliderTheme, required Animation<double> enableAnimation, required Offset thumbCenter, Offset? secondaryOffset, bool isEnabled = false, bool isDiscrete = false, required TextDirection textDirection }) {
final rect = getPreferredRect(parentBox: parentBox, offset: offset, sliderTheme: sliderTheme);
final canvas = context.canvas;
final t = _time(animationType, enableAnimation.value);
final shader = LinearGradient(
colors: _animatedPalette(palette, t),
begin: Alignment.centerLeft,
end: Alignment.centerRight,
).createShader(rect);
final active = Paint()..shader = shader;
final inactive = Paint()..color = (sliderTheme.inactiveTrackColor ?? Colors.grey).withOpacity(0.35);
final r = RRect.fromRectAndRadius(rect, const Radius.circular(999));


final activeRect = Rect.fromLTWH(rect.left, rect.top, math.max(0, thumbCenter.dx - rect.left), rect.height);
canvas.save();
canvas.clipRRect(r);
canvas.drawRect(activeRect, active);
canvas.restore();

final rightRect = Rect.fromLTWH(thumbCenter.dx, rect.top, rect.right - thumbCenter.dx, rect.height);
canvas.drawRRect(RRect.fromRectAndRadius(rightRect, const Radius.circular(999)), inactive);

// Необязательная отрисовка secondary-участка, если передан
if (secondaryOffset != null) {
  final secLeft = math.min(thumbCenter.dx, secondaryOffset.dx);
  final secRight = math.max(thumbCenter.dx, secondaryOffset.dx);
  final secRect = Rect.fromLTWH(secLeft, rect.top, secRight - secLeft, rect.height);
  final secRRect = RRect.fromRectAndRadius(secRect, const Radius.circular(999));
  final secondaryPaint = Paint()
    ..color = (sliderTheme.secondaryActiveTrackColor ?? (sliderTheme.activeTrackColor ?? Colors.blue)).withOpacity(0.25);
  canvas.drawRRect(secRRect, secondaryPaint);
}
}
static double _time(AnimationType type, double v) {
switch (type) {
case AnimationType.flow: return DateTime.now().millisecondsSinceEpoch % 4000 / 4000.0;
case AnimationType.valueBased: return v;
default: return (DateTime.now().millisecondsSinceEpoch % 6000) / 6000.0 * 0.25;
}
}
static List<Color> _animatedPalette(List<Color> base, double t) {
if (base.length < 2) return base;
final shift = (t * (base.length - 1));
final i = shift.floor().clamp(0, base.length - 2);
final frac = shift - i;
final a = base[i];
final b = base[i + 1];
Color lerp(Color x, Color y, double f) => Color.lerp(x, y, f) ?? x;
return [lerp(a, b, frac), lerp(b, a, frac)];
}
}

class _LineTickMarkShape extends SliderTickMarkShape {
const _LineTickMarkShape();
@override
Size getPreferredSize({required SliderThemeData sliderTheme, bool isEnabled = false}) => const Size(1, 8);
@override
void paint(PaintingContext context, Offset center, {required RenderBox parentBox, required SliderThemeData sliderTheme, required Animation<double> enableAnimation, required TextDirection textDirection, Offset? thumbCenter, bool isEnabled = false}) {
final canvas = context.canvas;
final paint = Paint()..color = (sliderTheme.activeTickMarkColor ?? Colors.black54);
canvas.drawRect(Rect.fromCenter(center: center, width: 1, height: 8), paint);
}
}
