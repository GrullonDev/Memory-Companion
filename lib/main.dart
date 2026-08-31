import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/utils/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solo se espera lo que hace falta para pintar el primer frame: los textos.
  await FlutterLocalization.instance.ensureInitialized();

  // Construir la base no toca el disco — `LazyDatabase` resuelve la ruta del
  // archivo en la primera consulta. Se crea aquí para que sea la misma
  // instancia durante toda la vida de la app.
  final database = AppDatabase();

  // Firebase ya no bloquea el arranque: se calienta desde el splash a través
  // de `firebaseInitializationProvider`.
  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const MyApp(),
    ),
  );
}
