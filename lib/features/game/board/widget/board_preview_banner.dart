import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';

/// Shown while the board is face up before play: an eye and a countdown.
///
/// Deliberately wordless, so it reads the same for a child who cannot read
/// yet and needs no translation.
class BoardPreviewBanner extends StatelessWidget {
  const BoardPreviewBanner({super.key, required this.secondsRemaining});

  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '$secondsRemaining',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.visibility_rounded,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 10),
          Text(
            '$secondsRemaining',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
