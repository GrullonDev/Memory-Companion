import 'package:memory_companion/core/sync/sync_operation.dart';

/// Fallo al aplicar una operación contra el backend.
///
/// [permanent] distingue «vuelve a intentarlo» de «esto nunca va a
/// funcionar». Reintentar un `permission-denied` solo quema cuota.
class SyncFailure implements Exception {
  const SyncFailure(this.message, {this.permanent = false});

  final String message;
  final bool permanent;

  @override
  String toString() =>
      'SyncFailure($message${permanent ? ', permanente' : ''})';
}

/// Lo que el motor necesita del backend, y nada más.
///
/// Existe como interfaz por dos razones. La primera es poder probar el motor
/// —reintentos, backoff, orden, idempotencia— sin Firestore de por medio. La
/// segunda es la fase 2 de seguridad: cuando el cliente deje de escribir los
/// totales y lo haga una Cloud Function, se sustituye la implementación y el
/// motor no se entera.
abstract interface class SyncGateway {
  /// Aplica [operation] de forma **idempotente**.
  ///
  /// Debe escribir el registro `users/{cloudUid}/sync_ops/{opId}` dentro de
  /// la misma transacción que el efecto, y no hacer nada si ya existe.
  Future<void> apply(SyncOperation operation, {required String cloudUid});

  /// Si ya hay un perfil en la nube para esta cuenta.
  ///
  /// Lo usa la vinculación para distinguir adopción de fusión.
  Future<Map<String, Object?>?> readProfile(String cloudUid);
}
