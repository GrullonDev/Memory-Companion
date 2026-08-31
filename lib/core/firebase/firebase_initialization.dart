import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/firebase_options.dart';

/// Arranque de Firebase, como algo que se espera solo cuando hace falta.
///
/// Antes `main` hacía `await Firebase.initializeApp(...)` antes de `runApp`:
/// nada se dibujaba hasta que Firebase terminaba. Ahora la inicialización es
/// un [FutureProvider] que se calienta en segundo plano desde el splash, y
/// solo lo esperan las piezas que de verdad necesitan Firebase —autenticación
/// y Firestore—. El gameplay no lo espera nunca.
///
/// Ojo: `initializeApp` es una operación **local** (lee la configuración
/// empaquetada), así que no necesita red y resuelve rápido incluso en avión.
/// Lo que quitamos no es tiempo de espera, es una dependencia estructural.
final firebaseInitializationProvider = FutureProvider<void>((ref) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
});
