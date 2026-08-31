import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/player/model/player_profile.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepository(database: ref.watch(appDatabaseProvider));
});

/// El jugador de este dispositivo.
///
/// Crea el perfil si es el primer arranque y luego sigue emitiendo cada
/// cambio. Sustituirá a `currentUserProvider` como fuente de la Home: local,
/// instantáneo y disponible sin cuenta ni conexión.
final localPlayerProvider = StreamProvider<PlayerProfile>((ref) async* {
  final repository = ref.watch(playerRepositoryProvider);

  // Primera emisión inmediata: la Home no espera a nadie.
  yield await repository.ensureLocalProfile();

  yield* repository
      .watchLocalProfile()
      .where((profile) => profile != null)
      .map((profile) => profile!);
});

/// El `localId` del jugador actual, para las escrituras que lo necesitan.
final currentPlayerIdProvider = Provider<String?>((ref) {
  return ref.watch(localPlayerProvider).value?.localId;
});
