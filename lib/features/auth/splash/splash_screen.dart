import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Splash screen shown while the app boots up.
///
/// This widget is UI-only (stateless); loading/navigation logic is handled
/// elsewhere (e.g. a Riverpod provider/controller) and drives this screen.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondaryContainer,
              AppColors.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              _MascotBadge(),
              const SizedBox(height: 24),
              Text(
                'MEMORY ARCADE',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(flex: 4),
              const _LoadingIndicator(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _MascotBadge extends StatelessWidget {
  const _MascotBadge();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
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
          child: Image.asset(
            'assets/logo_mascota.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'IDEAFLOW',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Loading',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 96,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: AppColors.onPrimary.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryFixed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
