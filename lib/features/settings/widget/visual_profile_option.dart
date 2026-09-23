import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/core/theme/visual_profile.dart';
import 'package:memory_companion/core/widgets/pressable.dart';

/// One choice in the visual-profile selector: a live preview of the
/// profile, its name, what it changes, and whether it is the active one.
///
/// Behaves as a radio button for assistive technology — one node that
/// reads "Clear view, selected, 1 of 2" — rather than a pile of texts.
/// Selection is shown with a check icon and a label as well as the thick
/// border, so it never depends on colour alone.
class VisualProfileOption extends StatelessWidget {
  const VisualProfileOption({
    super.key,
    required this.profile,
    required this.selected,
    required this.onSelected,
  });

  final VisualProfile profile;
  final bool selected;
  final VoidCallback onSelected;

  String _name(BuildContext context) => switch (profile) {
    VisualProfile.vibrant => AppLocale.profileVibrantName.getString(context),
    VisualProfile.accessible => AppLocale.profileAccessibleName.getString(
      context,
    ),
  };

  String _description(BuildContext context) => switch (profile) {
    VisualProfile.vibrant => AppLocale.profileVibrantDescription.getString(
      context,
    ),
    VisualProfile.accessible =>
      AppLocale.profileAccessibleDescription.getString(context),
  };

  @override
  Widget build(BuildContext context) {
    // The *surrounding* tokens size the control; the preview shows the
    // option's own look.
    final tokens = ProfileTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadius.xl);

    return MergeSemantics(
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        child: Pressable(
          onTap: selected ? null : onSelected,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: tokens.flipDuration,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.sunSoft
                  : AppColors.surfaceContainerLowest,
              borderRadius: radius,
              border: Border.all(
                color: selected ? AppColors.sunStrong : tokens.outlineColor,
                width: selected ? 3 : 1.5,
              ),
            ),
            child: Row(
              children: [
                ExcludeSemantics(child: _ProfilePreview(profile: profile)),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name(context), style: textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _description(context),
                        style: textTheme.bodyMedium?.copyWith(
                          color: tokens.supportingTextColor,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(height: AppSpacing.sm),
                        // The `checked` flag above already announces this.
                        ExcludeSemantics(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.sunStrong,
                                size: AppSize.iconSm,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  AppLocale.profileSelectedLabel.getString(
                                    context,
                                  ),
                                  style: textTheme.labelLarge?.copyWith(
                                    color: AppColors.sunStrong,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A two-card miniature drawn with the option's own tokens, so the player
/// sees the difference instead of reading about it.
class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({required this.profile});

  final VisualProfile profile;

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileTokens.forProfile(profile);
    const cardSize = 34.0;

    Widget card({required bool faceUp}) {
      return Container(
        width: cardSize,
        height: cardSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: faceUp
              ? AppColors.surfaceContainerLowest
              : tokens.cardFaceDownColor,
          borderRadius: BorderRadius.circular(tokens.cardRadius / 2),
          border: faceUp
              ? Border.all(
                  color: tokens.cardFaceUpBorderColor,
                  width: tokens.cardBorderWidth / 2,
                )
              : null,
        ),
        child: Text(
          faceUp ? 'Aa' : '?',
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontSize: tokens.isAccessible ? 15 : 11,
            fontWeight: FontWeight.w800,
            color: faceUp ? AppColors.onSurface : tokens.onCardFaceDownColor,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          card(faceUp: false),
          const SizedBox(width: AppSpacing.xs),
          card(faceUp: true),
        ],
      ),
    );
  }
}
