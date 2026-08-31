import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_motion.dart';
import 'package:memory_companion/core/theme/app_shadows.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/pressable.dart';

/// Bottom navigation shared by Home, Versus, Friends and Shop.
///
/// Fixes carried over from the previous version:
///  * labels were hard-coded English strings in a bilingual app;
///  * each item was a bare `GestureDetector` with no press feedback and a
///    tap area smaller than the 48dp minimum;
///  * the active state changed instantly, giving no sense of movement.
///
/// The active item keeps both a filled pill *and* a heavier icon, so the
/// current tab is not communicated by colour alone.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, this.activeIndex = 0, this.onTap});

  final int activeIndex;
  final ValueChanged<int>? onTap;

  static const List<({IconData icon, IconData activeIcon, String labelKey})>
      _items = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      labelKey: AppLocale.navHome,
    ),
    (
      icon: Icons.sports_esports_outlined,
      activeIcon: Icons.sports_esports_rounded,
      labelKey: AppLocale.navVersus,
    ),
    (
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
      labelKey: AppLocale.navFriends,
    ),
    (
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
      labelKey: AppLocale.navShop,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: AppShadows.navBar,
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: Pressable.small(
                onTap: onTap == null ? null : () => onTap!(i),
                semanticLabel: _items[i].labelKey.getString(context),
                child: _NavItem(
                  icon: _items[i].icon,
                  activeIcon: _items[i].activeIcon,
                  label: _items[i].labelKey.getString(context),
                  active: i == activeIndex,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.onSun : AppColors.outline;

    return AnimatedContainer(
      duration: AppMotion.normal,
      curve: AppMotion.emphasized,
      constraints: const BoxConstraints(minHeight: AppSize.touchMin),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: active ? AppColors.sun : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            active ? activeIcon : icon,
            color: color,
            size: AppSize.iconMd,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
