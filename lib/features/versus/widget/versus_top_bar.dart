import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';

class VersusTopBar extends StatelessWidget {
  const VersusTopBar({super.key, required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryFixedDim,
          ),
          child: ClipOval(
            child: Container(
              color: AppColors.surfaceContainerLowest,
              child: Image.asset('assets/logo_mascota.png', fit: BoxFit.cover),
            ),
          ),
        ),
        Expanded(
          child: Text(
            AppLocale.appTitle.getString(context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                size: 18,
                color: AppColors.onPrimaryFixed,
              ),
              const SizedBox(width: 6),
              Text(
                NumberFormat.decimalPattern().format(coins),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.onPrimaryFixed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
