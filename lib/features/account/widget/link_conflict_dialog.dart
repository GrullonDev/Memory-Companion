import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/features/player/model/player_level.dart';
import 'package:memory_companion/features/player/model/player_profile.dart';

/// Qué progreso conservar cuando ambos lados tienen uno.
enum LinkChoice { keepLocal, keepCloud }

/// El diálogo de fusión.
///
/// Aquí no hay respuesta técnicamente correcta —el jugador es el único que
/// sabe cuál de los dos progresos le importa—, y adivinar es exactamente cómo
/// se pierde el progreso de alguien. Así que se pregunta, con los dos estados
/// puestos uno al lado del otro en términos que el jugador reconoce: nivel y
/// monedas, no XP acumulado ni identificadores.
Future<LinkChoice?> showLinkConflictDialog(
  BuildContext context, {
  required PlayerProfile local,
  required Map<String, Object?> cloud,
}) {
  return showDialog<LinkChoice>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _LinkConflictDialog(local: local, cloud: cloud),
  );
}

class _LinkConflictDialog extends StatelessWidget {
  const _LinkConflictDialog({required this.local, required this.cloud});

  final PlayerProfile local;
  final Map<String, Object?> cloud;

  int _intOf(String key) {
    final value = cloud[key];
    return value is int ? value : 0;
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern();
    final levelLabel = AppLocale.levelShortLabel.getString(context);
    final coinsLabel = AppLocale.coinsShortLabel.getString(context);

    String describe(int totalXp, int coins) {
      return '$levelLabel ${levelFromTotalXp(totalXp)} · '
          '${numberFormat.format(coins)} $coinsLabel';
    }

    return AlertDialog(
      icon: const Icon(
        Icons.compare_arrows_rounded,
        color: AppColors.violetStrong,
        size: AppSize.iconLg,
      ),
      title: Text(
        AppLocale.linkConflictTitle.getString(context),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocale.linkConflictSubtitle.getString(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ProgressRow(
            label: AppLocale.linkInThisAccount.getString(context),
            value: describe(_intOf('totalXp'), _intOf('totalCoins')),
            background: AppColors.skySoft,
            foreground: AppColors.skyStrong,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProgressRow(
            label: AppLocale.linkOnThisDevice.getString(context),
            value: describe(local.totalXp, local.totalCoins),
            background: AppColors.sunSoft,
            foreground: AppColors.sunStrong,
          ),
        ],
      ),
      actionsOverflowButtonSpacing: AppSpacing.sm,
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(LinkChoice.keepCloud),
          child: Text(AppLocale.linkKeepCloud.getString(context)),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(LinkChoice.keepLocal),
          child: Text(AppLocale.linkKeepLocal.getString(context)),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground,
                ),
          ),
        ],
      ),
    );
  }
}
