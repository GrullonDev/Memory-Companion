import 'package:drift/drift.dart';

/// Reemplazo para compilaciones web.
///
/// El objetivo del producto es móvil. Drift sí funciona en web, pero exige
/// publicar `sqlite3.wasm` y `drift_worker.js` como assets; hasta que exista
/// una razón de producto para soportar web, este stub mantiene la compilación
/// verde y falla de forma explícita en vez de silenciosa.
QueryExecutor openConnection() {
  throw UnsupportedError(
    'La base de datos local aún no está disponible en web. '
    'Requiere publicar sqlite3.wasm y drift_worker.js como assets.',
  );
}
