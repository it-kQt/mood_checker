import 'package:flutter/material.dart';
import 'preset.dart';

class SettingsModel extends ChangeNotifier {
  final List<Preset> availablePresets;
  String? activePresetId;

  AnimationType animationType;
  ThumbShape thumbShape;
  TrackStyle trackStyle;
  TickStyle tickStyle;

  SettingsModel({
    required this.availablePresets,
    required this.activePresetId,
    required this.animationType,
    required this.thumbShape,
    required this.trackStyle,
    required this.tickStyle,
  });

  Preset? get activePreset => availablePresets.where((p) => p.id == activePresetId).cast<Preset?>().firstOrNull;

  void setPreset(String id) { activePresetId = id; notifyListeners(); }
  void setAnimation(AnimationType a) { animationType = a; notifyListeners(); }
  void setThumb(ThumbShape t) { thumbShape = t; notifyListeners(); }
  void setTrack(TrackStyle t) { trackStyle = t; notifyListeners(); }
  void setTicks(TickStyle t) { tickStyle = t; notifyListeners(); }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
