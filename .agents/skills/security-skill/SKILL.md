---
name: security-skill
description: When the user asks about security, hardening, authentication improvements, data protection, or any aspect of securing the Memory Arcade app — including Firestore rules, auth flows, local database encryption, network security, dependency auditing, or privacy — use this skill. Also triggers on phrases like "secure the app," "improve authentication," "protect user data," "security audit," "make it safer," "encryption," or "vulnerability." This skill should be used even when the user doesn't explicitly say "security" but is working on features that touch user data, privacy, or trust.
compatibility: [Dart, Flutter, Firebase, Drift, Python (for audit script)]
---

# 🔒 Security-Skill — Security Enhancement for Memory Arcade

> Skill especializado para identificar, diseñar e implementar mejoras de seguridad en **Memory Arcade** (juego de memoria Flutter, offline-first con Drift + Firebase). Cada recomendación de este documento está verificada contra el código del proyecto y contra el comportamiento real de Firebase y Flutter. Si algo de aquí contradice el código, **manda el código**: verifícalo y corrige este documento.

---

## 🧠 Conocimiento del proyecto

### Estado de seguridad actual (verificado)

| Capa | Estado real | Valoración |
|---|---|---|
| **Autenticación** | Firebase Auth: correo/contraseña, Google, teléfono. Cuenta opcional; sin cuenta se juega con un `localId` (UUID) local. | ✅ |
| **Sesión y tokens** | Los gestiona el SDK de Firebase Auth: persiste la sesión en almacenamiento privado de la app (Keychain en iOS), el ID token dura 1 h y el SDK lo refresca solo. La app **no** guarda tokens propios. | ✅ Nada que hacer |
| **Throttling de login** | Firebase Auth limita intentos en el servidor y devuelve `too-many-requests`, que ya se traduce en `lib/features/auth/util/auth_error_mapper.dart`. | ✅ |
| **Reglas Firestore** | `firestore.rules`: lista blanca de campos, acumulados monótonos, topes por escritura (`deltaWithin`), `matches` y `sync_ops` inmutables, acceso por membresía en `friendships`/`duels`. | ✅ |
| **Base local** | Drift sobre `sqlite3_flutter_libs`, **sin cifrar**. | ⚠️ Ver A |
| **Copia de seguridad de Android** | `AndroidManifest.xml` no fija `allowBackup`, así que vale `true`: Auto Backup sube la base local a Google Drive, **incluidas** las tablas "solo locales" (`places`, `game_stats` con personas cercanas). | ⚠️ Ver B |
| **Firma de release** | `android/app/build.gradle.kts` firma `release` con el keystore de `android/key.properties`; sin ese archivo cae a la clave de **debug**. | ⚠️ Ver C (falta crear el keystore) |
| **Validación en servidor** | No hay Cloud Functions: el cliente escribe XP y monedas dentro de los topes de las reglas. | ⚠️ Ver D |
| **App Check** | No configurado: cualquiera con la configuración pública de Firebase puede llamar a Auth/Firestore desde un script (las reglas siguen aplicando). | ⚠️ Ver E |
| **Datos de contexto** | Ubicación agrupada y personas cercanas se guardan solo en Drift (`places`, `game_stats`); nunca pasan por la cola de sync. | ✅ (salvo B) |
| **`shared_preferences`** | No es dependencia directa. Llega por `flutter_localization`, que guarda solo el idioma elegido. | ✅ |

### Puntos ya robustos — no reabrir sin motivo

- **Reglas Firestore**: `profileFields()`, monotonía en `totalXp`, `gamesWon`, `totalMoves`, `longestStreak`; `deltaWithin`; documentos inmutables. Perfil privado `users/{uid}` (`isOwner`), perfil público `user_index/{uid}` con 4 campos.
- **Idempotencia**: cada operación de sync lleva un `opId` que es el id del documento en `users/{uid}/sync_ops/{opId}`; reintentar no duplica.
- **Offline-first**: el gameplay nunca espera a Firebase.

---

## 🚫 Mitos descartados — no los reintroduzcas

Versiones anteriores de este skill proponían lo siguiente. Es incorrecto o contraproducente para esta app:

| Afirmación anterior | Realidad |
|---|---|
| "Los tokens de Firebase Auth viven solo en memoria; hay que guardarlos en `flutter_secure_storage`." | Falso. El SDK persiste y refresca la sesión. Copiar tokens a otro almacén solo crea una segunda copia que proteger. |
| "Cifrar con `sqflite` + `sqlcipher`." | Drift aquí usa el paquete `sqlite3`, no `sqflite`. El cifrado se hace sustituyendo `sqlite3_flutter_libs` por `sqlcipher_flutter_libs` (ver A). |
| "Ofuscar clases con `@dart=nnbd-strong`." | No existe. La ofuscación real es `flutter build … --obfuscate --split-debug-info=<dir>`, y solo encarece la ingeniería inversa. |
| "Hash de `main.dart` al arrancar para verificar integridad." | En release no hay `main.dart`: el código Dart va compilado AOT. Cualquier autocomprobación en el cliente se desactiva parcheando el cliente. |
| "`ptrace(PT_DENY_ATTACH)`, `root_checker`, `android:resizeableActivity="false"`, `extractNativeLibs="false"` como anti-tampering." | Se saltan con facilidad, castigan a usuarios legítimos (root) o no tienen relación con la seguridad (`resizeableActivity`, `extractNativeLibs`). La defensa real es servidor + App Check (D, E). |
| "Certificate pinning para las llamadas a Firebase." | Google rota certificados e intermedios; un pin fijo rompería la sincronización sin aviso. TLS del SDK + App Check son suficientes. |
| "Usar `fetchSignInMethodsForEmail` para detectar correos filtrados." | Esa API no consulta filtraciones: dice qué métodos tiene un correo, está obsoleta y facilita enumerar cuentas (con la protección contra enumeración activada devuelve vacío). |
| "No hay rate limiting en autenticación." | Firebase Auth limita en el servidor (`too-many-requests`). Un cooldown en el cliente es solo UX, no seguridad. |

---

## 📋 Áreas de mejora (priorizadas)

### A. Cifrado de la base local (Media)

**Por qué:** la mayoría de los datos son de juego (poco sensibles), pero `places` y `game_stats` guardan dónde y con quién juega el jugador. En un dispositivo rooteado o con una copia extraída, eso se lee en claro.

**Cómo, bien hecho:**
- Sustituir `sqlite3_flutter_libs` por `sqlcipher_flutter_libs` en `pubspec.yaml` (no pueden convivir: ambos traen `libsqlite3`).
- En `lib/core/database/connection/native.dart`, abrir con `NativeDatabase.createInBackground(file, setup: (db) { db.execute("PRAGMA key = '…'"); })` y comprobar con `PRAGMA cipher_version` que SQLCipher está realmente cargado.
- La clave: aleatoria (32 bytes, `Random.secure()`), generada en el primer arranque y guardada con `flutter_secure_storage` (Keystore/Keychain). Este es el **único** uso justificado de secure storage en la app. Nunca derivarla de la cuenta ni de nada que necesite red: el juego debe abrir sin conexión.
- Migración: una base existente sin cifrar se convierte una vez (`ATTACH … KEY …` + `SELECT sqlcipher_export(…)`) antes de abrirla con Drift. Probar el camino "usuario que actualiza la app".
- Los tests siguen usando `AppDatabase.forTesting(NativeDatabase.memory())`, sin clave.
- Web (`connection/web.dart`) queda fuera: no hay SQLCipher en WASM.

### B. Excluir la base local de Auto Backup (Media-Alta, fácil)

**Por qué:** el README promete que el contexto "no sale del dispositivo", pero Auto Backup sube `databases/` a Google Drive.

**Cómo:** en `android/app/src/main/AndroidManifest.xml`, o bien `android:allowBackup="false"`, o bien reglas que excluyan la base:
- Android 12+: `android:dataExtractionRules="@xml/data_extraction_rules"` con `<exclude domain="database" path="." />` (o solo el archivo de Drift) en `cloud-backup` y `device-transfer`.
- Android ≤ 11: `android:fullBackupContent="@xml/backup_rules"` con la misma exclusión.

Decidir con producto: excluir la base significa que el progreso local sin cuenta no se restaura en un teléfono nuevo. La cuenta vinculada sí lo restaura desde Firestore.

### C. Firma de release propia (Alta — bloquea publicar)

Crear un keystore de subida, referenciarlo desde `android/key.properties` (fuera del repo, en `.gitignore`) y usarlo en `buildTypes.release` de `android/app/build.gradle.kts`. Activar Play App Signing. Nunca commitear el keystore ni sus contraseñas.

Hecho en código: `android/app/build.gradle.kts` lee `android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`) y, si no existe, firma con la clave de debug para que `flutter run --release` siga funcionando en local. Falta crear el keystore de subida y ese archivo en la máquina que publica.

### D. Validación en servidor con Cloud Functions (Alta)

**Problema:** ninguna regla puede comprobar que una partida justifica su recompensa; un cliente modificado puede inventar partidas dentro de los topes.

**Mejora:**
- El cliente escribe solo `users/{uid}/sync_ops/{opId}`; una Function (`onDocumentCreated`) valida marcador, movimientos y tiempo creíbles, y es la única que escribe `totalXp` y `totalCoins`.
- `users/{uid}` pasa a `allow write: if false` para los campos de economía.
- Mantener la idempotencia por `opId`.

Archivos: `firebase.json` (functions), `functions/` (nuevo), `firestore.rules`, `lib/core/sync/`.

### E. Firebase App Check (Media-Alta)

Registrar `firebase_app_check` con Play Integrity (Android) y App Attest/DeviceCheck (iOS), activar primero en modo **monitor** en la consola y luego **enforcement** para Firestore y Auth. En debug, el proveedor de depuración. Esta es la respuesta correcta a "clientes manipulados" y sustituye a detección de root, pinning y autocomprobaciones.

Offline-first: App Check solo afecta a las llamadas a Firebase; el juego local no cambia.

### F. Reglas Firestore — endurecimiento (Media)

- `request.time` para que `updatedAt`/`playedAt` no vengan del futuro ni de hace meses.
- `user_index`: `friendCode` inmutable tras crearse.
- Revisar que cada colección nueva tenga lista blanca de campos y tests con el emulador.

Archivo: `firestore.rules`. Guía de patrones: `references/firestore-rules.md`.

### G. Re-autenticación en operaciones sensibles (Media)

Antes de borrar la cuenta, cambiar correo o contraseña, o desvincular un proveedor, pedir `reauthenticateWithCredential` (Firebase lo exige además con `requires-recent-login`). Es más útil para este juego que MFA.

**MFA (Baja):** requiere actualizar a Firebase Authentication with Identity Platform; para un juego rara vez compensa. Si se hace, segundo factor por SMS/TOTP con `multiFactor`.

### H. Protección de cuentas en la consola (Baja, sin código)

- Activar la **protección contra enumeración de correos** (por defecto en proyectos nuevos).
- Política de contraseñas en el servidor (Identity Platform) y, en el registro, un indicador de fortaleza como ayuda visual (`register_screen.dart`). La validación que cuenta es la del servidor.

### I. Dependencias (Media)

- `flutter pub outdated` periódicamente; `pub get` ya muestra avisos de seguridad publicados para paquetes de pub.dev.
- Dependabot con `package-ecosystem: "pub"` en `.github/dependabot.yml` (el repo aún no tiene `.github/`).
- Revisar `pubspec.yaml` al añadir paquetes con permisos (Bluetooth, ubicación).

### J. Monitoreo (Baja-Media)

- `firebase_crashlytics`; con builds ofuscadas, subir los símbolos de `--split-debug-info` para leer las trazas.
- Eventos anónimos y desactivables para fallos de login y vinculación de cuenta. Nunca registrar correos, códigos de amigo ni ubicación.

### K. Ofuscación (Baja)

`flutter build appbundle --obfuscate --split-debug-info=build/symbols`. Encarece leer el código; no protege secretos. **No hay secretos en el cliente**: la configuración de Firebase es pública por diseño y la protegen las reglas y App Check.

---

## ⚠️ Principios de seguridad del proyecto

Cualquier mejora debe respetar estos principios no negociables:

1. **Offline-first es sagrado:** nada puede romper jugar sin conexión. El cifrado local no puede depender del servidor.
2. **El servidor decide:** las reglas de Firestore (y, en el futuro, las Functions) son la frontera de confianza. Nada que corra en el cliente es una barrera de seguridad.
3. **Privacidad por diseño:** los datos de contexto (ubicación, Bluetooth) siguen siendo locales, y eso incluye las copias de seguridad (B).
4. **Simplicidad sobre complejidad:** si una mejora añade complejidad sin reducir un riesgo real de esta app, no se implementa. Ver "Mitos descartados".
5. **Sin backdoors:** ninguna "funcionalidad de desarrollo" en producción (emuladores, proveedor de depuración de App Check, logs con datos personales).
6. **Fallo seguro:** si un sistema de seguridad falla, el fallback es el modo más restrictivo, salvo el juego local, que siempre sigue disponible.

---

## 🔧 Cómo trabajar con este skill

### Al recibir una tarea de seguridad:

1. **Clasificar** la tarea en una de las secciones A-K.
2. **Leer** los archivos del proyecto implicados y confirmar que el estado descrito aquí sigue siendo cierto.
3. **Evaluar** el impacto en offline-first y en la privacidad de los datos locales.
4. **Implementar** con código Dart, reglas Firestore o configuración nativa.
5. **Verificar** que `fvm flutter analyze` y `fvm flutter test` siguen limpios (sin `fvm` en el PATH: `.fvm/versions/stable/bin/flutter`, si `fvm install` ya creó `.fvm/`).
6. **Actualizar** la tabla "Estado de seguridad actual" de este documento.

### Auditoría automática

```bash
python .agents/skills/security-skill/scripts/security_audit.py          # informe legible
python .agents/skills/security-skill/scripts/security_audit.py --json   # JSON
```

Es un escáner de patrones: sus hallazgos son pistas que hay que confirmar leyendo el código, no veredictos.

### Priorización recomendada

| Prioridad | Área | Riesgo real |
|---|---|---|
| 🔴 Alta | C (firma release), D (Cloud Functions) | No se puede publicar / manipulación de progreso |
| 🟠 Media-Alta | B (Auto Backup), E (App Check) | Datos "solo locales" en la nube / abuso de la API |
| 🟡 Media | A (cifrado local), F (reglas), G (re-auth), I (dependencias) | Lectura local, escrituras anómalas, cuenta tomada |
| 🟢 Baja | H (consola), J (monitoreo), K (ofuscación), MFA | Detección tardía, coste de ingeniería inversa |

---

## 📂 Referencias del proyecto

| Documento | Ruta |
|---|---|
| README | `README.md` |
| Arquitectura offline-first | `docs/OFFLINE_FIRST.md` |
| Reglas de Firestore | `firestore.rules`, `references/firestore-rules.md` |
| Configuración Firebase | `FIRESTORE_SETUP.md`, `FIREBASE_COMMANDS.md`, `firebase.json`, `lib/firebase_options.dart` |
| Auth | `lib/features/auth/controller/auth_controller.dart`, `lib/features/auth/util/auth_error_mapper.dart` |
| Base local | `lib/core/database/app_database.dart`, `lib/core/database/connection/native.dart` |
| Android | `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts` |
| Stack | `pubspec.yaml` |
