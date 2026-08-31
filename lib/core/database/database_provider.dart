import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/app_database.dart';

/// Instancia única de la base local.
///
/// Se abre de forma perezosa: construir [AppDatabase] no toca el disco, y la
/// ruta del archivo se resuelve en la primera consulta. Por eso el arranque
/// puede pintar la Home sin esperar a nadie.
///
/// En `main` se sobrescribe con una instancia ya creada cuando conviene
/// tenerla lista antes del primer frame; en los tests se sobrescribe con
/// `AppDatabase.forTesting(NativeDatabase.memory())`.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
