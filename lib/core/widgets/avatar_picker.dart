import 'package:flutter/material.dart';

import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';

/// Tappable avatar circle with a "randomize" dice button, used to let a new
/// player roll a random look while creating their account.
///
/// No illustrated avatar set exists in the project yet, so a plain icon on
/// a gradient background stands in for the generated character art.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({super.key, this.onRandomize, this.seed = 0});

  final VoidCallback? onRandomize;

  /// Picks which gradient/icon combo to show, so tapping "randomize" is
  /// visibly different each time even without real avatar art.
  final int seed;

  static const _gradients = [
    [AppColors.mintGreen, AppColors.secondaryContainer],
    [AppColors.pastelPurple, AppColors.tertiaryFixed],
    [AppColors.secondary, AppColors.primaryFixed],
    [AppColors.tertiary, AppColors.mintGreen],
  ];

  static const _icons = [
    Icons.face_rounded,
    Icons.pets_rounded,
    Icons.emoji_emotions_rounded,
    Icons.mood_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[seed % _gradients.length];
    final icon = _icons[seed % _icons.length];
    return Column(
      children: [
        GestureDetector(
          onTap: onRandomize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 108,
                height: 108,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryFixed,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 56,
                    color: AppColors.surfaceContainerLowest,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondaryContainer,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.casino_rounded,
                    size: 18,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          AppLocale.randomizeAvatarLabel.getString(context),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
