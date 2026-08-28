import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';

/// Stylized stand-in for the illustrated "characters high-fiving in an
/// arcade" artwork — no such asset exists in the project, so this uses
/// flat gradients and icon chips instead of painted art.
class LobbyBanner extends StatelessWidget {
  const LobbyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pastelPurple, AppColors.secondaryContainer],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 14,
            left: 14,
            child: _Chip(icon: Icons.videogame_asset_rounded, label: 'GAME ON'),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: _Chip(icon: Icons.trending_up_rounded, label: 'LEVEL UP'),
          ),
          const Center(
            child: Icon(
              Icons.emoji_people_rounded,
              size: 72,
              color: Colors.white,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Text(
              AppLocale.multiplayerLobbyLabel.getString(context),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurface),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
