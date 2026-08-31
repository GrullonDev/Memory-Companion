import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/game/controller/game_controller.dart';
import 'package:memory_companion/features/home/model/home_summary.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/home/model/recent_match.dart';

/// Loads the data the home screen shows beyond the static mode grid: the
/// player's most recent match.
class HomeController extends AsyncNotifier<RecentMatch> {
  @override
  Future<RecentMatch> build() async {
    // Fetch recent matches from Firestore
    final matches = await ref.watch(userMatchHistoryProvider.future);

    // If no matches, return empty state
    if (matches.isEmpty) {
      return const RecentMatch(
        titleKey: AppLocale.sampleMatchTitle,
        score: '--',
        timeAgoKey: AppLocale.sampleMatchTimeAgo,
        isPlaceholder: true,
      );
    }

    // Get the most recent match (first in the list, since it's ordered by date)
    final lastMatch = matches.first;

    return RecentMatch(
      titleKey: 'SOLO', // Game mode as title
      score: _formatNumber(lastMatch.score),
      timeAgoKey: _getTimeAgoString(lastMatch.playedAt),
    );
  }

  /// Format large numbers (e.g., 14200 -> "14,200")
  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  /// Convert datetime to "time ago" format
  String _getTimeAgoString(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace ${weeks}w';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'Hace ${months}mo';
    }
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

  if (player == null) {
    return HomeSummary.empty(isLoading: playerAsync.isLoading);
  }

  return HomeSummary(
    playerName: player.displayName,
    totalXp: player.totalXp,
    streakDays: player.currentStreak,
    isLoading: false,
  );
});
