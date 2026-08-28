import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';

/// Full-width "3D lip" button used for the main call to action on the
/// login and register screens (LOGIN / CREATE ACCOUNT).
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: const Border(
                bottom: BorderSide(color: AppColors.tertiary, width: 4),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40E6B400),
                  offset: Offset(0, 6),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onPrimaryFixed,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, color: AppColors.onPrimaryFixed),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
