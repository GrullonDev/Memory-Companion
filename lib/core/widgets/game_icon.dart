import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_spacing.dart';

/// An icon inside a rounded "well".
///
/// Icons in this app are never bare glyphs floating on a colour: a tinted
/// well gives them a consistent silhouette, guarantees a contrast backdrop,
/// and makes them read as objects a child can aim at rather than decoration.
class GameIcon extends StatelessWidget {
  const GameIcon({
    super.key,
    required this.icon,
    required this.color,
    this.background,
    this.size = AppSize.wellMd,
    this.iconSize,
    this.radius,
  });

  /// Compact variant used inside chips and list rows.
  const GameIcon.small({
    super.key,
    required this.icon,
    required this.color,
    this.background,
  })  : size = AppSize.wellSm,
        iconSize = AppSize.iconSm,
        radius = AppRadius.sm;

  /// Hero variant for the primary action card.
  const GameIcon.large({
    super.key,
    required this.icon,
    required this.color,
    this.background,
  })  : size = AppSize.wellLg,
        iconSize = AppSize.iconXl,
        radius = AppRadius.lg;

  final IconData icon;

  /// Colour of the glyph itself.
  final Color color;

  /// Well fill. Defaults to [color] at 16% — enough separation from the card
  /// beneath without introducing a new colour.
  final Color? background;

  final double size;
  final double? iconSize;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(radius ?? AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: color,
        size: iconSize ?? size * 0.5,
      ),
    );
  }
}
