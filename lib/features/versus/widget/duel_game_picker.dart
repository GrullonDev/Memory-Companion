import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/pressable.dart';
import 'package:memory_companion/features/versus/model/duel_game.dart';

/// The games a duel can be played on, as a row of tiles in the mini-game
/// hub's colours. The selected one is outlined.
class DuelGamePicker extends StatelessWidget {
  const DuelGamePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final DuelGame selected;
  final ValueChanged<DuelGame> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocale.chooseGameLabel.getString(context),
          style: textTheme.labelLarge?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final game in DuelGame.values) ...[
              if (game != DuelGame.values.first)
                const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _GameTile(
                  game: game,
                  selected: game == selected,
                  onTap: () => onSelected(game),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppLocale.bestOfThreeLabel.getString(context),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.game,
    required this.selected,
    required this.onTap,
  });

  final DuelGame game;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = game.palette;
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedScale(
        scale: selected ? 1 : 0.94,
        duration: const Duration(milliseconds: 160),
        child: Pressable(
          onTap: onTap,
          child: Material(
            color: palette.background,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: selected ? AppColors.onSurface : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                children: [
                  Icon(game.icon, color: palette.foreground, size: 26),
                  const SizedBox(height: 4),
                  Text(
                    game.titleKey.getString(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: palette.foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks which game a new duel is played on. Null if dismissed.
Future<DuelGame?> showDuelGamePicker(
  BuildContext context, {
  DuelGame initial = DuelGame.memory,
}) {
  var selected = initial;
  return showModalBottomSheet<DuelGame>(
    context: context,
    backgroundColor: AppColors.surfaceContainerLowest,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DuelGamePicker(
                selected: selected,
                onSelected: (game) => setState(() => selected = game),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => Navigator.of(sheetContext).pop(selected),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(AppLocale.playLabel.getString(sheetContext)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
