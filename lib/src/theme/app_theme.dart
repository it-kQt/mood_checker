import 'package:flutter/material.dart';
import '../model/preset.dart';
import '../model/settings_model.dart';
import 'slider_factories.dart';

class AppThemePair {
  final ThemeData light;
  final ThemeData dark;
  AppThemePair(this.light, this.dark);
}

AppThemePair buildAppTheme(Preset? preset, SettingsModel s) {
  final scheme = preset?.colorScheme ?? ColorScheme.fromSeed(seedColor: Colors.teal);
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.background,
  );
  final thumb = buildThumbShape(s.thumbShape, preset?.thumbShape ?? s.thumbShape, scheme);
  final track = buildTrackShape(s.trackStyle, preset?.trackStyle ?? s.trackStyle, scheme, preset?.gradientPalette ?? [scheme.primary, scheme.secondary], s.animationType);
  final ticks = buildTickMarkShape(s.tickStyle, preset?.tickStyle ?? s.tickStyle);

  ThemeData themed(ThemeData b) {
    return b.copyWith(
      sliderTheme: b.sliderTheme.copyWith(
        thumbShape: thumb,
        trackHeight: 6,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.outline.withOpacity(0.3),
        trackShape: track.trackShape,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        tickMarkShape: ticks,
        activeTickMarkColor: scheme.onSurface.withOpacity(0.6),
        inactiveTickMarkColor: scheme.onSurface.withOpacity(0.2),
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
        valueIndicatorTextStyle: TextStyle(color: scheme.onPrimary),
      ),
    );
  }

  final light = themed(base.copyWith(brightness: Brightness.light));
  final dark = themed(base.copyWith(brightness: Brightness.dark));
  return AppThemePair(light, dark);
}
