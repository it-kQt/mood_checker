import 'package:flutter/material.dart';

enum BaseTheme { light, dark }
enum AnimationType { subtle, flow, valueBased }
enum ThumbShape { circle, square, arrow }
enum TrackStyle { straight, rounded, gradient }
enum TickStyle { none, dots, lines }

class Preset {
  final int schemaVersion;
  final String id;
  final String name;
  final String? description;
  final BaseTheme baseTheme;
  final ColorScheme colorScheme;
  final List<Color> gradientPalette;
  final AnimationType gradientAnimation;
  final ThumbShape thumbShape;
  final TrackStyle trackStyle;
  final TickStyle tickStyle;
  final double cornerRadius;

  Preset({
    required this.schemaVersion,
    required this.id,
    required this.name,
    required this.description,
    required this.baseTheme,
    required this.colorScheme,
    required this.gradientPalette,
    required this.gradientAnimation,
    required this.thumbShape,
    required this.trackStyle,
    required this.tickStyle,
    required this.cornerRadius,
  });

  factory Preset.fromJson(Map<String, dynamic> j) {
    final base = (j['baseTheme'] as String?) == 'dark' ? BaseTheme.dark : BaseTheme.light;
    final cs = j['colorScheme'] as Map<String, dynamic>;
    final scheme = ColorScheme(
      brightness: base == BaseTheme.dark ? Brightness.dark : Brightness.light,
      primary: _parseColor(cs['primary']),
      onPrimary: _parseColor(cs['onPrimary']),
      secondary: _parseColor(cs['secondary']),
      onSecondary: _parseColor(cs['onSecondary']),
      surface: _parseColor(cs['surface']),
      onSurface: _parseColor(cs['onSurface']),
      background: _parseColor(cs['background']),
      onBackground: _parseColor(cs['onBackground']),
      error: _parseColor(cs['error']),
      onError: _parseColor(cs['onError']),
      tertiary: cs['tertiary'] != null ? _parseColor(cs['tertiary']) : _parseColor(cs['secondary']),
      outline: cs['outline'] != null ? _parseColor(cs['outline']) : _parseColor(cs['onSurface']).withOpacity(0.12),
    );
    final ext = (j['extended'] ?? {}) as Map<String, dynamic>;
    final palette = (ext['gradientPalette'] as List? ?? []).map((e) => _parseColor(e)).toList();
    return Preset(
      schemaVersion: j['schemaVersion'] ?? 1,
      id: j['id'],
      name: j['name'],
      description: j['description'],
      baseTheme: base,
      colorScheme: scheme,
      gradientPalette: palette.isNotEmpty ? palette : [scheme.primary, scheme.secondary],
      gradientAnimation: _anim(ext['gradientAnimation']),
      thumbShape: _thumb(ext['thumbShape']),
      trackStyle: _track(ext['trackStyle']),
      tickStyle: _tick(ext['tickStyle']),
      cornerRadius: (ext['cornerRadius'] is num) ? (ext['cornerRadius'] as num).toDouble() : 12,
    );
  }

  static Color _parseColor(dynamic v) {
    if (v is int) return Color(v);
    if (v is String) {
      var s = v.trim();
      if (s.startsWith('#')) s = s.substring(1);
      if (s.length == 6) s = 'FF$s';
      return Color(int.parse(s, radix: 16));
    }
    return const Color(0xFF000000);
  }

  static AnimationType _anim(dynamic v) {
    switch ((v ?? 'subtle').toString().toLowerCase()) {
      case 'flow': return AnimationType.flow;
      case 'valuebased': return AnimationType.valueBased;
      default: return AnimationType.subtle;
    }
  }

  static ThumbShape _thumb(dynamic v) {
    switch ((v ?? 'circle').toString().toLowerCase()) {
      case 'square': return ThumbShape.square;
      case 'arrow': return ThumbShape.arrow;
      default: return ThumbShape.circle;
    }
  }

  static TrackStyle _track(dynamic v) {
    switch ((v ?? 'rounded').toString().toLowerCase()) {
      case 'straight': return TrackStyle.straight;
      case 'gradient': return TrackStyle.gradient;
      default: return TrackStyle.rounded;
    }
  }

  static TickStyle _tick(dynamic v) {
    switch ((v ?? 'none').toString().toLowerCase()) {
      case 'dots': return TickStyle.dots;
      case 'lines': return TickStyle.lines;
      default: return TickStyle.none;
    }
  }
}
