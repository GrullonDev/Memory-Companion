import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/core/theme/visual_profile.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/features/auth/controller/auth_controller.dart';
import 'package:memory_companion/features/settings/controller/display_preferences_controller.dart';
import 'package:memory_companion/features/settings/widget/context_settings_section.dart';
import 'package:memory_companion/features/settings/widget/visual_profile_option.dart';

/// Device settings: how the game looks, whether it runs on a clock, and the
/// opt-in automatic context.
///
/// Every change is written to the local database and takes effect at once
/// — the whole app re-themes under the player's finger, which is the best
/// preview there is. Nothing here needs a connection or an account.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(displayPreferencesProvider);
    final controller = ref.read(displayPreferencesControllerProvider.notifier);
    final tokens = ProfileTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocale.settingsLabel.getString(context))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.sm,
            AppSpacing.screenMargin,
            AppSpacing.xxl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                AppLocale.appearanceSectionTitle.getString(context),
                style: textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppLocale.appearanceSectionSubtitle.getString(context),
              style: textTheme.bodyMedium?.copyWith(
                color: tokens.supportingTextColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final profile in VisualProfile.values) ...[
              VisualProfileOption(
                profile: profile,
                selected: preferences.visualProfile == profile,
                onSelected: () => controller.setVisualProfile(profile),
              ),
              SizedBox(height: tokens.controlGap),
            ],
            const SizedBox(height: AppSpacing.sectionGap - AppSpacing.md),
            Semantics(
              header: true,
              child: Text(
                AppLocale.gameplaySectionTitle.getString(context),
                style: textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              // The card paints its own background; the tile needs a
              // Material above it for its ink splash to show.
              child: Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  value: preferences.timedMatches,
                  onChanged: controller.setTimedMatches,
                  activeTrackColor: AppColors.sunStrong,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  secondary: const Icon(Icons.timer_outlined),
                  title: Text(
                    AppLocale.timedMatchesTitle.getString(context),
                    style: textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    (preferences.timedMatches
                            ? AppLocale.timedMatchesOnSubtitle
                            : AppLocale.timedMatchesOffSubtitle)
                        .getString(context),
                    style: textTheme.bodyMedium?.copyWith(
                      color: tokens.supportingTextColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap - AppSpacing.md),
            const ContextSettingsSection(),
            const SizedBox(height: AppSpacing.sectionGap - AppSpacing.md),
            const _AccountSection(),
          ],
        ),
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    if (user == null) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final tokens = ProfileTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            AppLocale.accountSectionTitle.getString(context),
            style: textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${AppLocale.accountSignedInAs.getString(context)}: '
          '${user.displayName ?? user.email ?? ''}',
          style: textTheme.bodyMedium?.copyWith(
            color: tokens.supportingTextColor,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: EdgeInsets.zero,
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(AppLocale.signOutLabel.getString(context)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              leading: Icon(
                Icons.delete_forever_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                AppLocale.deleteAccountLabel.getString(context),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              onTap: () => _confirmDelete(context, ref),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocale.deleteAccountConfirmTitle.getString(context)),
        content: Text(
          AppLocale.deleteAccountConfirmMessage.getString(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocale.deleteAccountCancelButton.getString(context),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              AppLocale.deleteAccountConfirmButton.getString(context),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).deleteAccount();
    }
  }
}
