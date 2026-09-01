import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/core/sync/sync_controller.dart';
import 'package:memory_companion/features/account/repository/account_migration.dart';
import 'package:memory_companion/features/auth/controller/auth_controller.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/player/model/player_profile.dart';

final accountMigrationProvider = Provider<AccountMigration>((ref) {
  return AccountMigration(
    database: ref.watch(appDatabaseProvider),
    syncQueue: ref.watch(syncQueueProvider),
  );
});

/// En qué punto está la vinculación de la cuenta.
enum LinkStatus {
  /// Sin cuenta, o ya vinculado: no hay nada que decidir.
  settled,

  /// Cuenta nueva sin progreso en la nube: se adoptó el local sin preguntar.
  adopted,

  /// Ambos lados tienen progreso. Decide el jugador.
  needsChoice,
}

class AccountLinkState {
  const AccountLinkState({
    required this.status,
    this.localProfile,
    this.cloudProfile,
  });

  final LinkStatus status;
  final PlayerProfile? localProfile;
  final Map<String, Object?>? cloudProfile;

  bool get needsChoice => status == LinkStatus.needsChoice;
}

/// Vincula el perfil local con una cuenta de Firebase.
///
/// La regla que hace que esto no pueda perder progreso: **crear una cuenta no
/// crea un perfil nuevo**. Rellena `cloudUid` sobre la fila que ya existía.
/// No hay traspaso, hay vinculación.
///
/// Dos caminos:
///
///  * **Adopción** (el caso normal): la cuenta no tiene progreso en la nube.
///    Se vincula y se encola todo el estado local. Sin preguntas.
///  * **Fusión**: la cuenta ya tiene progreso, por ejemplo de otro teléfono.
///    Aquí no hay respuesta técnicamente correcta, y adivinar es exactamente
///    cómo se pierde el progreso de alguien. Se pregunta.
class AccountLinkController extends AsyncNotifier<AccountLinkState> {
  @override
  Future<AccountLinkState> build() async {
    final firebaseUser = ref.watch(authStateChangesProvider).value;
    final player = ref.watch(localPlayerProvider).value;

    if (firebaseUser == null || player == null) {
      return const AccountLinkState(status: LinkStatus.settled);
    }
    if (player.cloudUid == firebaseUser.uid) {
      return AccountLinkState(
        status: LinkStatus.settled,
        localProfile: player,
      );
    }

    final cloudProfile = await _readCloudProfile(firebaseUser.uid);

    // La cuenta está vacía: se adopta el progreso local tal cual.
    if (cloudProfile == null || _isEmptyProgress(cloudProfile)) {
      await _link(player, firebaseUser.uid);
      return AccountLinkState(
        status: LinkStatus.adopted,
        localProfile: player,
      );
    }

    // Progreso local irrelevante: nada que perder, se toma el de la cuenta.
    if (!_hasLocalProgress(player)) {
      await _keepCloud(player, firebaseUser.uid, cloudProfile);
      return AccountLinkState(
        status: LinkStatus.adopted,
        localProfile: player,
      );
    }

    return AccountLinkState(
      status: LinkStatus.needsChoice,
      localProfile: player,
      cloudProfile: cloudProfile,
    );
  }

  /// El jugador elige quedarse con lo de este dispositivo.
  Future<void> keepLocalProgress() async {
    final current = state.value;
    final firebaseUser = ref.read(authStateChangesProvider).value;
    final player = current?.localProfile;
    if (firebaseUser == null || player == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _link(player, firebaseUser.uid);
      return AccountLinkState(
        status: LinkStatus.adopted,
        localProfile: player,
      );
    });
  }

  /// El jugador elige quedarse con lo de su cuenta.
  Future<void> keepCloudProgress() async {
    final current = state.value;
    final firebaseUser = ref.read(authStateChangesProvider).value;
    final player = current?.localProfile;
    final cloudProfile = current?.cloudProfile;
    if (firebaseUser == null || player == null || cloudProfile == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _keepCloud(player, firebaseUser.uid, cloudProfile);
      return AccountLinkState(
        status: LinkStatus.adopted,
        localProfile: player,
      );
    });
  }

  Future<Map<String, Object?>?> _readCloudProfile(String cloudUid) async {
    try {
      return await ref.read(syncGatewayProvider).readProfile(cloudUid);
    } catch (_) {
      // Sin red no se puede decidir. Se deja sin vincular y se reintenta en
      // el próximo arranque: no vincular es reversible, elegir mal no.
      return null;
    }
  }

  Future<void> _link(PlayerProfile player, String cloudUid) async {
    await ref.read(playerRepositoryProvider).linkToCloud(
          localId: player.localId,
          cloudUid: cloudUid,
        );
    await ref.read(accountMigrationProvider).enqueueFullState(player.localId);
    unawaited(ref.read(syncControllerProvider.notifier).syncNow());
  }

  Future<void> _keepCloud(
    PlayerProfile player,
    String cloudUid,
    Map<String, Object?> cloudProfile,
  ) async {
    await ref.read(playerRepositoryProvider).linkToCloud(
          localId: player.localId,
          cloudUid: cloudUid,
        );
    await ref.read(accountMigrationProvider).adoptCloudProfile(
          playerLocalId: player.localId,
          cloudProfile: cloudProfile,
        );
  }

  static bool _hasLocalProgress(PlayerProfile player) {
    return player.totalXp > 0 ||
        player.totalCoins > 0 ||
        player.gamesWon > 0 ||
        player.hasPlayed;
  }

  static bool _isEmptyProgress(Map<String, Object?> profile) {
    int intOf(String key) {
      final value = profile[key];
      return value is int ? value : 0;
    }

    return intOf('totalXp') == 0 &&
        intOf('totalCoins') == 0 &&
        intOf('gamesWon') == 0;
  }
}

final accountLinkControllerProvider =
    AsyncNotifierProvider<AccountLinkController, AccountLinkState>(
      AccountLinkController.new,
    );
