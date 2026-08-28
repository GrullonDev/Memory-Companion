import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';

/// A single combatant summary card used on the versus screen.
///
/// [reversed] mirrors the internal layout (avatar side, stat order) so
/// the rival card can face the player card, matching the mockup.
class VersusPlayerCard extends StatelessWidget {
  const VersusPlayerCard({
    super.key,
    required this.name,
    required this.rankLabel,
    required this.level,
    required this.powerValue,
    required this.powerProgress,
    required this.formWins,
    required this.accentColor,
    this.reversed = false,
  });

  final String name;
  final String rankLabel;
  final int level;
  final String powerValue;
  final double powerProgress;
  final List<bool> formWins;
  final Color accentColor;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final avatar = _Avatar(accentColor: accentColor);
    final identity = Column(
      crossAxisAlignment: reversed
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          textDirection: reversed ? TextDirection.rtl : TextDirection.ltr,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Lv $level',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              rankLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );

    final identityRow = Row(
      children: reversed
          ? [Expanded(child: identity), const SizedBox(width: 16), avatar]
          : [avatar, const SizedBox(width: 16), Expanded(child: identity)],
    );

    final powerLabel = Text(
      AppLocale.powerLevelLabel.getString(context),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
    final powerValueText = Text(
      powerValue,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );

    final formLabel = Text(
      reversed
          ? ':${AppLocale.formLabel.getString(context)}'
          : '${AppLocale.formLabel.getString(context)}:',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
    final formDots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < formWins.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: formWins[i] ? AppColors.mintGreen : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border(top: BorderSide(color: accentColor, width: 4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          identityRow,
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: reversed ? TextDirection.rtl : TextDirection.ltr,
            children: [powerLabel, powerValueText],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: powerProgress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(accentColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            textDirection: reversed ? TextDirection.rtl : TextDirection.ltr,
            children: [formLabel, const SizedBox(width: 10), formDots],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
      child: ClipOval(
        child: Container(
          color: AppColors.surfaceContainerLowest,
          child: Image.asset('assets/logo_mascota.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}
