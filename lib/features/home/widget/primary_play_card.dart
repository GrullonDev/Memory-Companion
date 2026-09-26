import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_shadows.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/pressable.dart';

/// The Home's single primary action.
///
/// Everything else on the screen is deliberately quieter than this card: it
/// is the widest element, the only one in full-strength yellow, the only one
/// carrying the mascot, and the only one with a filled call-to-action inside
/// it. A player who understands nothing else on the screen still knows where
/// to press — which is the whole requirement for a 4-year-old and, in
/// practice, for a distracted adult too.
///
/// It replaces the old featured banner, which competed with an identically
/// weighted "Jugar Solo" tile pointing at the same route.
class PrimaryPlayCard extends StatelessWidget {
  const PrimaryPlayCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = AppLocale.modePlaySolo.getString(context);
    final subtitle = AppLocale.playSoloSubtitle.getString(context);
    final radius = BorderRadius.circular(AppRadius.hero);

    return Pressable(
      onTap: onTap,
      borderRadius: radius,
      shadow: AppShadows.tinted(AppColors.sunDeep),
      pressedShadow: AppShadows.tinted(AppColors.sunDeep, pressed: true),
      semanticLabel: '$title. $subtitle',
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppSize.primaryCardMinHeight,
        ),
        decoration: BoxDecoration(color: AppColors.sun, borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative light shapes. Purely atmospheric, clipped by the
            // card, and excluded from the semantics tree.
            const Positioned(right: -36, top: -46, child: _Blob(size: 150)),
            const Positioned(right: 54, bottom: -58, child: _Blob(size: 116)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.headlineSmall?.copyWith(
                            color: AppColors.onSun,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSun.withValues(alpha: 0.78),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const _PlayCta(),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ExcludeSemantics(
                    child: Image.asset(
                      'assets/logo_mascota.png',
                      width: 84,
                      height: 84,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The filled pill inside the primary card. Not a separate tap target — the
/// whole card is tappable — but it names the action in words for players who
/// read, while the arrow names it for players who don't.
class _PlayCta extends StatelessWidget {
  const _PlayCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppSize.touchMin),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.onSun,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: AppSize.iconMd,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              AppLocale.continueLabel.getString(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}
