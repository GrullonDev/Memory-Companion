import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/sync/sync_controller.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/app_badge.dart';

/// Dónde está guardado el progreso, en lenguaje humano.
///
/// Ninguno de los tres estados dice «error» ni menciona la nube, Firebase o
/// una cola. Para el jugador su progreso **siempre** está guardado; la única
/// variable es dónde. Un fallo de red no es una avería: es el estado normal
/// de un producto offline-first.
class SaveStateBadge extends ConsumerWidget {
  const SaveStateBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saveStateProvider);

    return switch (state) {
      SaveState.savedInCloud => AppBadge(
          icon: Icons.cloud_done_rounded,
          label: AppLocale.saveStateInCloud.getString(context),
          background: AppColors.mintSoft,
          foreground: AppColors.mintStrong,
          compact: true,
        ),
      SaveState.syncing => AppBadge(
          icon: Icons.sync_rounded,
          label: AppLocale.saveStateSyncing.getString(context),
          background: AppColors.skySoft,
          foreground: AppColors.skyStrong,
          compact: true,
        ),
      SaveState.savedOnDevice => AppBadge.neutral(
          icon: Icons.smartphone_rounded,
          label: AppLocale.saveStateOnDevice.getString(context),
          compact: true,
        ),
    };
  }
}
