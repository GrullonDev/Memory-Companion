import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';
import 'package:memory_companion/core/widgets/pinned_footer_layout.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

/// The first screen of a level-based mini-game: what to do, the level about
/// to be dealt, and "start" pinned at the bottom.
class MinigameIntro extends StatelessWidget {
  const MinigameIntro({
    super.key,
    required this.icon,
    required this.color,
    required this.level,
    required this.text,
    required this.onStart,
  });

  final IconData icon;
  final Color color;
  final int level;
  final String text;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PinnedFooterLayout(
      footer: AdaptiveButton(
        label: AppLocale.minigameStartLabel.getString(context),
        icon: Icons.play_arrow_rounded,
        onPressed: onStart,
      ),
      children: [
        Icon(icon, color: color, size: 72),
        const SizedBox(height: AppSpacing.md),
        Text(
          fill(AppLocale.minigameLevelLabel.getString(context), level),
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(color: color),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(text, textAlign: TextAlign.center, style: textTheme.bodyLarge),
      ],
    );
  }
}
