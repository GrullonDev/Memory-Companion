import 'package:flutter/material.dart';

import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';

/// Renders [value]'s loading/error/data states consistently across screens
/// that back their content with a Riverpod provider.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.minHeight = 240,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) data;
  final VoidCallback? onRetry;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (value) => data(context, value),
      loading: () => SizedBox(
        height: minHeight,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryFixedDim),
        ),
      ),
      error: (error, stackTrace) => SizedBox(
        height: minHeight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocale.genericErrorMessage.getString(context),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onRetry,
                  child: Text(AppLocale.retryLabel.getString(context)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
