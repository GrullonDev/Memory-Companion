import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';

class ProfileStatGrid extends StatelessWidget {
  const ProfileStatGrid({
    super.key,
    required this.gamesWon,
    required this.totalMoves,
    required this.bestStreak,
    required this.totalCoins,
  });

  final int gamesWon;
  final String totalMoves;
  final int bestStreak;
  final String totalCoins;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.emoji_events_rounded,
          accent: AppColors.secondary,
          label: AppLocale.gamesWonLabel.getString(context),
          value: '$gamesWon',
        ),
        _StatCard(
          icon: Icons.touch_app_rounded,
          accent: AppColors.tertiary,
          label: AppLocale.totalMovesLabel.getString(context),
          value: totalMoves,
        ),
        _StatCard(
          icon: Icons.bolt_rounded,
          accent: AppColors.error,
          label: AppLocale.bestStreakLabel.getString(context),
          value: '$bestStreak',
          suffix: AppLocale.winsUnit.getString(context),
        ),
        _StatCard(
          icon: Icons.monetization_on_rounded,
          accent: AppColors.onPrimaryFixedVariant,
          label: AppLocale.totalCoinsLabel.getString(context),
          value: totalCoins,
          filled: true,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    this.suffix,
    this.filled = false,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final String? suffix;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: filled ? AppColors.primaryFixed : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: filled
            ? null
            : Border(top: BorderSide(color: accent, width: 3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 6),
                Text(
                  suffix!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
