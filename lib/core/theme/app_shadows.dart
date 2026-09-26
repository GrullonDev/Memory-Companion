import 'package:flutter/material.dart';

/// Elevation tokens.
///
/// Depth is expressed with large, soft, Y-offset shadows rather than
/// Material's tonal elevation. Coloured surfaces get a shadow tinted with
/// their own hue so the colour stays vibrant instead of being greyed down.
abstract final class AppShadows {
  /// Resting state for a white card on the app background.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0F101828),
      offset: Offset(0, 4),
      blurRadius: 14,
      spreadRadius: -2,
    ),
  ];

  /// A card that should read as clearly lifted (hero / primary action).
  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x14101828),
      offset: Offset(0, 10),
      blurRadius: 28,
      spreadRadius: -6,
    ),
  ];

  /// Overlays, dialogs and the bottom sheet.
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x1F101828),
      offset: Offset(0, 16),
      blurRadius: 40,
      spreadRadius: -8,
    ),
  ];

  /// The bottom navigation bar casts upward.
  static const List<BoxShadow> navBar = [
    BoxShadow(
      color: Color(0x14101828),
      offset: Offset(0, -4),
      blurRadius: 20,
      spreadRadius: -4,
    ),
  ];

  /// No shadow. Use for the pressed state so the element visibly settles.
  static const List<BoxShadow> none = [];

  /// A shadow tinted with [color] — for saturated surfaces such as the
  /// yellow primary card, where a grey shadow would look muddy.
  ///
  /// [pressed] returns the flattened version used while the finger is down.
  static List<BoxShadow> tinted(Color color, {bool pressed = false}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: pressed ? 0.18 : 0.34),
        offset: Offset(0, pressed ? 2 : 8),
        blurRadius: pressed ? 8 : 20,
        spreadRadius: -4,
      ),
    ];
  }
}
