import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/game/board/model/memory_card.dart';

class MemoryCardTile extends StatelessWidget {
  const MemoryCardTile({super.key, required this.card, required this.onTap});

  final MemoryCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final revealed = card.isFaceUp || card.isMatched;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: card.isMatched ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: revealed
              ? _FaceUp(key: const ValueKey('up'), symbol: card.symbol)
              : const _FaceDown(key: ValueKey('down')),
        ),
      ),
    );
  }
}

class _FaceDown extends StatelessWidget {
  const _FaceDown({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: ClipRRect(
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
  const _FaceUp({super.key, required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryFixedDim, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(symbol, style: const TextStyle(fontSize: 28)),
    );
  }
}
