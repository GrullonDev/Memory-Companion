import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/features/auth/splash/controller/splash_controller.dart';
import 'package:memory_companion/features/auth/splash/splash_screen.dart';

/// Conecta el arranque con la navegación.
///
/// Antes esto miraba `FirebaseAuth.currentUser` y mandaba al login a quien no
/// tuviera sesión: no existía tercera vía, y jugar exigía cuenta.
///
/// Ahora **siempre** se va a la Home. La identidad local se garantiza en el
/// arranque, así que siempre hay un jugador al que mostrarle su progreso.
/// Crear cuenta pasa a ser una propuesta de valor que aparece cuando el
/// jugador ya tiene algo que perder, no un peaje en la puerta.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(splashBootProvider, (previous, next) {
      next.whenOrNull(
        data: (_) => Navigator.pushReplacementNamed(context, RoutePaths.home),
        // Ni siquiera un fallo del arranque deja al jugador fuera: la Home
        // sabe renderizarse con un perfil vacío.
        error: (_, _) =>
            Navigator.pushReplacementNamed(context, RoutePaths.home),
      );
    });

    return const SplashScreen();
  }
}
