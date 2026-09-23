import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/features/game/board/model/card_face.dart';
import 'package:memory_companion/features/game/board/model/memory_card.dart';

/// One memory card. Size, colours, border and flip speed come from the
/// active [ProfileTokens]; the tile itself never checks the profile.
///
/// For assistive technology the card is a single button that says where it
/// is and what state it is in — "Card 3, face down" / "Card 3: 🍓, pair
/// found" — instead of an unlabeled image.
class MemoryCardTile extends StatelessWidget {
  const MemoryCardTile({
    super.key,
    required this.card,
    required this.onTap,
    this.position,
  });

  final MemoryCard card;
  final VoidCallback onTap;

  /// 1-based place on the board, announced by screen readers so the player
  /// can refer back to a card they heard earlier.
  final int? position;

  String _semanticLabel(BuildContext context, bool revealed) {
    final name = position == null
        ? AppLocale.cardLabel.getString(context)
        : '${AppLocale.cardLabel.getString(context)} $position';
    if (!revealed) {
      return '$name, ${AppLocale.cardFaceDownLabel.getString(context)}';
    }
    final face = '$name: ${card.face.semanticLabel}';
    return card.isMatched
        ? '$face, ${AppLocale.cardMatchedLabel.getString(context)}'
        : face;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileTokens.of(context);
    final revealed = card.isFaceUp || card.isMatched;
    final radius = BorderRadius.circular(tokens.cardRadius);

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: !card.isMatched,
        label: _semanticLabel(context, revealed),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: card.isMatched ? null : onTap,
            borderRadius: radius,
            child: ExcludeSemantics(
              child: AnimatedSwitcher(
                duration: tokens.flipDuration,
                child: revealed
                    ? _FaceUp(
                        key: const ValueKey('up'),
                        face: card.face,
                        isMatched: card.isMatched,
                        tokens: tokens,
                      )
                    : _FaceDown(key: const ValueKey('down'), tokens: tokens),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FaceDown extends StatelessWidget {
  const _FaceDown({super.key, required this.tokens});

  final ProfileTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.cardFaceDownColor,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        boxShadow: tokens.isAccessible
            ? null
            : const [
                BoxShadow(
                  color: Color(0x22000000),
                  offset: Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
      ),
      alignment: Alignment.center,
      // The accessible back is a plain, high-contrast "?" — nothing on the
      // back competes for attention with the faces the player must recall.
      child: tokens.isAccessible
          ? FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.question_mark_rounded,
                  color: tokens.onCardFaceDownColor,
                  size: tokens.cardSymbolSize,
                ),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/logo_mascota.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
    );
  }
}

class _FaceUp extends StatelessWidget {
  const _FaceUp({
    super.key,
    required this.face,
    required this.isMatched,
    required this.tokens,
  });

  final CardFace face;
  final bool isMatched;
  final ProfileTokens tokens;

  @override
  Widget build(BuildContext context) {
    // Matched cards say so with a check mark, not only with a colour.
    final showMatchedBadge = isMatched && tokens.isAccessible;

    return Container(
      decoration: BoxDecoration(
        color: isMatched && tokens.isAccessible
            ? tokens.cardMatchedColor
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(
          color: tokens.cardFaceUpBorderColor,
          width: tokens.cardBorderWidth,
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: Stack(
        alignment: Alignment.center,
        children: [
          switch (face) {
            // The card's own size already follows the profile; scaling the
            // glyph by the text scale on top would overflow it.
            SymbolFace(:final symbol) => FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                symbol,
                textScaler: TextScaler.noScaling,
                style: TextStyle(fontSize: tokens.cardSymbolSize),
              ),
            ),
            // Words and sums shrink to fit rather than wrap or clip; the
            // cap keeps short ones ("7") from ballooning.
            TextFace(:final text) => FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 2,
                textScaler: TextScaler.noScaling,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: tokens.cardSymbolSize * 0.8,
                ),
              ),
            ),
          },
          if (showMatchedBadge)
            const Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.mintStrong,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
