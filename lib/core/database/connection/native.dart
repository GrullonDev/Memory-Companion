import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Nombre del archivo SQLite en el directorio de documentos de la app.
///
/// Vive en el directorio de *documentos* y no en el de caché a propósito:
/// el progreso de un jugador sin cuenta es el único ejemplar que existe, y
/// el sistema operativo puede vaciar la caché cuando le convenga.
const String kDatabaseFileName = 'memory_companion.sqlite';

/// Abre la base local sobre el sistema de archivos del dispositivo.
///
/// [LazyDatabase] retrasa la resolución de la ruta hasta la primera consulta,
/// de modo que construir [AppDatabase] no bloquea el arranque.
/// `createInBackground` mueve SQLite a un isolate propio: las escrituras de
/// fin de partida no compiten con el hilo de UI.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, kDatabaseFileName));
    return NativeDatabase.createInBackground(file);
  });
}
