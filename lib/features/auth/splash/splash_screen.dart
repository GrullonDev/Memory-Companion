import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/auth/splash/widget/loading_indicator.dart';
import 'package:memory_companion/features/auth/splash/widget/mascot_badge.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.secondaryContainer, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              MascotBadge(),
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
              const LoadingIndicator(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
