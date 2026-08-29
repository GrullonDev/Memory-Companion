import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';

class MascotBadge extends StatelessWidget {
  const MascotBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _FloatingBadge(),
        /*         const SizedBox(height: 8),
        Text(
          'MEMORY ARCADE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ), */
      ],
    );
  }
}

/// Makes the logo square float up and down in a continuous loop.
class _FloatingBadge extends StatefulWidget {
  const _FloatingBadge();

  @override
  State<_FloatingBadge> createState() => _FloatingBadgeState();
}

class _FloatingBadgeState extends State<_FloatingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _offset = Tween<double>(
    begin: -8,
    end: 8,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _offset.value),
          child: child,
        );
      },
      child: Container(
        width: 148,
        height: 148,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              offset: Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: Image.asset('assets/logo_mascota.png', fit: BoxFit.contain),
      ),
    );
  }
}
