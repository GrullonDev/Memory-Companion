import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/firebase/firebase_initialization.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/player/model/player_profile.dart';

/// Tiempo mínimo en el splash.
///
/// No es una espera técnica —el arranque real es más corto— sino que evita
/// que la marca aparezca y desaparezca de golpe. Bajó de 2s a 600ms: la
/// promesa del producto es que la Home se sienta instantánea.
const Duration _minimumSplashDuration = Duration(milliseconds: 600);

/// Secuencia de arranque.
///
/// Lo único que se espera de verdad es la identidad local, que se crea sin
/// red, sin cuenta y sin preguntar nada. Firebase se calienta en paralelo y
/// **no se espera**: si tarda, falla o el dispositivo está sin cobertura, el
/// jugador entra igual.
final splashBootProvider = FutureProvider<PlayerProfile>((ref) async {
  final minimumSplash = Future<void>.delayed(_minimumSplashDuration);

  unawaited(
    ref.read(firebaseInitializationProvider.future).catchError((Object _) {
      // Sin Firebase se juega igual; el motor de sincronización lo reintentará.
    }),
  );

  final profile = await ref.read(playerRepositoryProvider).ensureLocalProfile();
  await minimumSplash;
  return profile;
});
