import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';

/// A screen body whose content scrolls while its [footer] — the controls
/// the player needs right now — stays pinned to the bottom edge.
///
/// On a short phone, or with large text, the content scrolls under the
/// footer instead of pushing the keypad or the answer buttons off screen.
/// Without a [footer] it is a plain padded, width-capped scroll view, so
/// every phase of a game can share one layout.
class PinnedFooterLayout extends StatelessWidget {
  const PinnedFooterLayout({
    super.key,
    required this.children,
    this.footer,
    this.maxWidth = 480,
  });

  final List<Widget> children;
  final Widget? footer;

  /// Content stays a comfortable reading width on tablets.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final footer = this.footer;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenMargin),
                children: children,
              ),
            ),
            if (footer != null)
              DecoratedBox(
                // Same colour as the screen: content scrolling underneath is
                // cut off cleanly instead of showing through.
                decoration: const BoxDecoration(color: AppColors.background),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin,
                    AppSpacing.sm,
                    AppSpacing.screenMargin,
                    AppSpacing.screenMargin,
                  ),
                  child: footer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
