import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';

/// "OR PLAY WITH" divider plus a row of quick-login provider buttons,
/// matching the providers enabled on the Firebase project (Google, Phone).
class SocialLoginRow extends StatelessWidget {
  const SocialLoginRow({super.key, this.onGoogleTap, this.onPhoneTap});

  final VoidCallback? onGoogleTap;
  final VoidCallback? onPhoneTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                AppLocale.orPlayWithLabel.getString(context),
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.outline),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.outlineVariant)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ProviderButton(
                icon: Icons.g_mobiledata_rounded,
                onTap: onGoogleTap,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ProviderButton(
                icon: Icons.phone_android_rounded,
                onTap: onPhoneTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Icon(icon, size: 28, color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}
