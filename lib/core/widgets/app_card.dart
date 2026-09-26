import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_shadows.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/pressable.dart';

/// The base container every grouped block of content sits in.
///
/// One widget owns radius, padding, background and shadow, so a card can
/// never drift out of the system. Pass [onTap] and it becomes a [Pressable]
/// with the correct press feedback for its size.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.surfaceContainerLowest,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.xl,
    this.shadow,
    this.pressedShadow,
    this.border,
    this.constraints,
    this.clipContent = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Defaults to [AppShadows.card], or a shadow tinted with [color] when the
  /// card is painted in a saturated brand colour.
  final List<BoxShadow>? shadow;
  final List<BoxShadow>? pressedShadow;
  final BoxBorder? border;
  final BoxConstraints? constraints;

  /// Clip decorative children (blobs, oversized icons) to the card's radius.
  final bool clipContent;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final resting = shadow ?? AppShadows.card;

    Widget content = Container(
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: border,
      ),
      clipBehavior: clipContent ? Clip.antiAlias : Clip.none,
      child: child,
    );

    if (onTap == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: resting,
        ),
        child: content,
      );
    }

    return Pressable(
      onTap: onTap,
      borderRadius: borderRadius,
      shadow: resting,
      pressedShadow: pressedShadow,
      semanticLabel: semanticLabel,
      child: content,
    );
  }
}
