import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/core/theme/visual_profile.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
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
            const SizedBox(height: AppSpacing.sectionGap - AppSpacing.md),
            const ContextSettingsSection(),
          ],
        ),
      ),
    );
  }
}
