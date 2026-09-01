import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_shadows.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/core/widgets/game_icon.dart';
import 'package:memory_companion/core/widgets/pressable.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';

/// Si el jugador apartó la propuesta en esta sesión.
///
/// Solo dura lo que dure la sesión: «Ahora no» significa ahora no, no nunca
/// más. Vuelve a aparecer en el siguiente arranque, cuando además tendrá más
/// progreso que perder.
class AccountPromptDismissed extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;
}

final accountPromptDismissedProvider =
    NotifierProvider<AccountPromptDismissed, bool>(
      AccountPromptDismissed.new,
    );

/// «Guarda tu progreso»: la propuesta de crear cuenta.
///
/// No aparece al instalar. Espera a que el jugador tenga algo que perder,
/// porque pedir una cuenta a alguien que aún no ha jugado es un peaje, y
/// pedírsela a quien lleva ocho niveles es una oferta.
///
/// Habla de lo que el jugador gana —recuperar, jugar en otro móvil, amigos,
/// competir— y no menciona ni la nube, ni cuentas de Firebase, ni
/// sincronización.
class SaveProgressCard extends ConsumerWidget {
  const SaveProgressCard({super.key});

  /// XP a partir del cual la propuesta merece la pena mostrarse.
  static const int _minimumXpToOffer = 200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(accountPromptDismissedProvider)) {
      return const SizedBox.shrink();
    }

    final player = ref.watch(localPlayerProvider).value;
    if (player == null || player.isLinkedToCloud) {
      return const SizedBox.shrink();
    }
    final hasSomethingToLose =
        player.totalXp >= _minimumXpToOffer || player.gamesWon > 0;
    if (!hasSomethingToLose) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: AppCard(
        color: AppColors.violet,
        radius: AppRadius.xl,
        padding: const EdgeInsets.all(AppSpacing.lg),
        shadow: AppShadows.tinted(AppColors.violetDeep),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GameIcon(
                  icon: Icons.workspace_premium_rounded,
                  color: AppColors.onViolet,
                  background: Colors.white.withValues(alpha: 0.38),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocale.saveProgressTitle.getString(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.onViolet,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        AppLocale.saveProgressSubtitle.getString(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.onViolet.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final benefit in [
              AppLocale.saveProgressBenefitRecover,
              AppLocale.saveProgressBenefitDevices,
              AppLocale.saveProgressBenefitFriends,
              AppLocale.saveProgressBenefitCompete,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: AppSize.iconXs,
                      color: AppColors.onViolet,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        benefit.getString(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.onViolet,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: () =>
                        Navigator.of(context).pushNamed(RoutePaths.register),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    semanticLabel:
                        AppLocale.createAccountLabel.getString(context),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: AppSize.touchMin,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.onViolet,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        AppLocale.createAccountLabel.getString(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Pressable.small(
                  onTap: () => ref
                      .read(accountPromptDismissedProvider.notifier)
                      .dismiss(),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: AppSize.touchMin,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Text(
                      AppLocale.notNowLabel.getString(context),
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.onViolet.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
