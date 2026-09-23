import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/core/sync/sync_controller.dart';
import 'package:memory_companion/features/auth/controller/auth_controller.dart';
import 'package:memory_companion/features/game/model/match.dart';
import 'package:memory_companion/features/game/model/match_rewards.dart';
import 'package:memory_companion/features/game/repository/local_match_repository.dart';
import 'package:memory_companion/features/game/repository/match_repository.dart';
import 'package:memory_companion/features/level_map/controller/level_controller.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository();
});

/// Repositorio local de partidas: la fuente de verdad del historial.
final localMatchRepositoryProvider = Provider<LocalMatchRepository>((ref) {
  return LocalMatchRepository(
    database: ref.watch(appDatabaseProvider),
    playerRepository: ref.watch(playerRepositoryProvider),
    levelRepository: ref.watch(localLevelRepositoryProvider),
    syncQueue: ref.watch(syncQueueProvider),
  );
});

/// La última partida del jugador, leída de SQLite.
///
/// Es lo que alimenta la tarjeta «Tu última partida» de la Home, y por eso
/// funciona sin cuenta y sin conexión.
final lastLocalMatchProvider = StreamProvider<MatchRow?>((ref) async* {
  ref.keepAlive();
  final player = await ref.watch(localPlayerProvider.future);
  yield* ref
      .watch(localMatchRepositoryProvider)
      .watchLastMatch(player.localId);
});

/// Historial de partidas en la nube.
///
/// Sigue existiendo para el Perfil de un jugador con cuenta; el gameplay ya
/// no depende de él.
final userMatchHistoryProvider = StreamProvider<List<Match>>((ref) {
  final matchRepository = ref.watch(matchRepositoryProvider);

  return ref.watch(authStateChangesProvider).maybeWhen(
    data: (firebaseUser) {
      if (firebaseUser == null) return Stream.value([]);
      return matchRepository.getUserMatches(firebaseUser.uid);
    },
    orElse: () => Stream.value([]),
  );
});

/// Operaciones de partida.
class GameController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);

  /// Cierra una partida en solitario: la registra y entrega sus recompensas.
  ///
  /// Escribe **solo en local**, dentro de una transacción. No toca Firestore
  /// ni exige sesión: un jugador sin cuenta guarda su progreso igual que uno
  /// con cuenta. La subida a la nube la hará el motor de sincronización a
  /// partir de la cola de operaciones.
  ///
  /// [rewards] llega calculado desde el tablero para que el número que el
  /// jugador ve sea exactamente el que se guarda.
  Future<void> completeSoloGame({
    required String matchId,
    required int score,
    required int moves,
    required int secondsElapsed,
    required int timeLimit,
    required bool won,
    required MatchRewards rewards,
    int? levelNumber,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final player = await ref.read(localPlayerProvider.future);

      await ref.read(localMatchRepositoryProvider).recordMatch(
            matchId: matchId,
            playerLocalId: player.localId,
            gameMode: 'solo',
            score: score,
            moves: moves,
            secondsElapsed: secondsElapsed,
            timeLimit: timeLimit,
            rewards: rewards,
            won: won,
            levelNumber: levelNumber,
          );
    });
  }

  /// Estadísticas agregadas en la nube, para el Perfil de un jugador con
  /// cuenta.
  Future<Map<String, dynamic>> getGameStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      return await ref.read(matchRepositoryProvider).getUserStats(user.uid);
    } catch (e) {
      return {};
    }
  }
}

final gameControllerProvider = AsyncNotifierProvider<GameController, void>(
  GameController.new,
);
