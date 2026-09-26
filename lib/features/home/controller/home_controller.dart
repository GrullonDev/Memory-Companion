import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/game/controller/game_controller.dart';
import 'package:memory_companion/features/home/model/home_summary.dart';
import 'package:memory_companion/features/ladder/ladder_controller.dart';
import 'package:memory_companion/features/home/model/recent_match.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';

/// La última partida del jugador, para la tarjeta de cierre de la Home.
///
/// Lee de la base local. Un jugador recién instalado no tiene ninguna, y eso
/// no es un error: la Home muestra un estado vacío que invita a jugar en vez
/// de una fila de guiones.
class HomeController extends AsyncNotifier<RecentMatch> {
  @override
  Future<RecentMatch> build() async {
    final match = await ref.watch(lastLocalMatchProvider.future);

    if (match == null) {
      return const RecentMatch(
        titleKey: AppLocale.modePlaySolo,
        score: '--',
        isPlaceholder: true,
      );
    }

    return RecentMatch(
      titleKey: AppLocale.modePlaySolo,
      score: _formatNumber(match.score),
      playedAt: DateTime.fromMillisecondsSinceEpoch(match.playedAt),
    );
  }

  /// 14200 -> "14,200"
  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }
}

final homeControllerProvider =
    AsyncNotifierProvider<HomeController, RecentMatch>(HomeController.new);

/// La instantánea del jugador que hay detrás de la cabecera de la Home.
///
/// Lee de la **base local**, no de Firestore. Ese es el cambio que hace que
/// la Home funcione sin cuenta y sin conexión: el nombre, el nivel, el XP y
/// la racha salen de SQLite y están disponibles en el primer frame.
///
/// Firestore ya no aparece en esta ruta. Cuando el motor de sincronización
/// entre en escena, escribirá en la base local y la Home reaccionará sola.
final homeSummaryProvider = Provider<HomeSummary>((ref) {
  final playerAsync = ref.watch(localPlayerProvider);
  final player = playerAsync.value;
  // El nivel de cada juego sale de su escalera, no del XP: es el número que
  // el jugador ve subir en el mapa al ganar un tablero.
  final ladders = ref.watch(gameLaddersProvider);

  if (player == null) {
    return HomeSummary.empty(
      isLoading: playerAsync.isLoading,
      ladders: ladders,
    );
  }

  return HomeSummary(
    playerName: player.displayName,
    totalXp: player.totalXp,
    streakDays: player.currentStreak,
    isLoading: false,
    ladders: ladders,
  );
});
