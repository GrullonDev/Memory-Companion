# AGENTS.md

Instrucciones para agentes que trabajan en este repositorio. Consultar README y configuración para el detalle; este archivo no autoriza publicación ni cambios fuera de la tarea.

## Propósito del proyecto

Memory Arcade es una app de juegos y entrenamiento de memoria, retos, progreso y experiencias sociales. El nombre técnico sigue siendo memory_companion. Gameplay local primero; funciones sociales dependen de Firebase y conectividad.

## Stack y plataformas

Riverpod/flutter_riverpod, Drift/SQLite, Firebase Auth/Firestore, flutter_localization, geolocator y Bluetooth opcional.

Requisito Dart declarado: `^3.10.4` en `pubspec.yaml`; los rangos de dependencias no prueban la versión resuelta. SDK mediante FVM: `stable` según `.fvmrc` (canal móvil, no versión fija).

Proyectos de plataforma presentes: android, ios, linux, macos, web, windows. Esto no garantiza que todos los plugins funcionen en cada plataforma.

## Estructura del repositorio

`lib/core/database/` tablas/conexiones; `lib/core/sync/` cola y reconciliación; `lib/core/localization/` claves/traducciones; rutas/tema/widgets en core. `lib/features/` organiza juego, retos, amigos, cuenta y game_context con controller/model/repository/widget.

## Preparación y comandos

Requisitos: FVM y SDK de `.fvmrc`; ejecutar `fvm install` sin modificar el pin. Android necesita su toolchain/JDK de Gradle; iOS requiere macOS/Xcode y la gestión de dependencias del proyecto. Integraciones Firebase requieren configuración de desarrollo existente.

| Acción | Comando desde la raíz |
| --- | --- |
| Dependencias | `fvm flutter pub get` |
| Ejecutar | `fvm flutter run -d <dispositivo>` |
| Formato | `fvm dart format lib test` |
| Análisis | `fvm flutter analyze` |
| Pruebas | `fvm flutter test` |
| Build Android de comprobación | `fvm flutter build apk --debug` |

`fvm dart run build_runner build --delete-conflicting-outputs` al modificar Drift. Leer `docs/OFFLINE_FIRST.md`, `FIRESTORE_SETUP.md` y `FIREBASE_COMMANDS.md`; no ejecutar comandos de publicación como validación.

Los comandos fueron contrastados con dependencias, documentación/configuración y suites presentes; no ejecutados al redactar este archivo. Build de distribución requiere firma/configuración adicional; no sustituye despliegue.

## Arquitectura y convenciones

Drift es fuente de verdad: la UI observa datos locales, no espera una escritura Firestore para avanzar. Usar Notifier/AsyncNotifier y repositorios existentes. Mantener localId estable y enlazar cloudUid sin reemplazarlo; sync con opId y reintentos idempotentes. Cambios de tablas requieren schemaVersion/migración y build_runner. No introducir SharedPreferences para gameplay. Reutilizar PinnedFooterLayout/SuccessPulse y LexicalEmbedder local.

Conservar nombres y convenciones del módulo: Dart snake_case para archivos, UpperCamelCase para tipos y lowerCamelCase para miembros. No renombrar APIs/campos persistidos incidentalmente; respetar lints de analysis_options.yaml.

## Experiencia de usuario

Progreso y partidas CPU deben conservarse sin internet. Explicar estado de sincronización y fallos sociales sin bloquear juego. Traducciones mediante AppLocale, claves y mapas ES/EN con placeholders iguales; fechas relativas se formatean al renderizar. Respetar movimiento reducido y permisos opcionales.

En el flujo afectado, contemplar carga, vacío, éxito y error; dar feedback claro, conservar entradas/datos ante fallos y permitir recuperación. Reutilizar componentes visuales; revisar semántica, foco, contraste y escalado de texto.

## Seguridad y datos

No incluir secretos, credenciales ni datos personales en código, documentación o logs. Usar configuración de entorno existente, validar entradas y manejar fallos de servicios. Respetar autenticación, autorización y permisos. No ejecutar operaciones destructivas sobre datos sin autorización explícita.

No subir contexto de ubicación/Bluetooth local por defecto. Preservar reglas Firestore de propietario, invariantes y contadores monotónicos. No sustituir localId al iniciar sesión ni mezclar partidas entre cuentas. No probar contra Firebase de producción.

## Pruebas y validación

Usar tests existentes con Drift en memoria y fake_cloud_firestore. Ejecutar pruebas de localización al cambiar copy, de migraciones/sync al cambiar datos y de reglas de juegos al cambiar puntuación. Validar invitado → login, offline → reconexión, deduplicación, progreso y denegación de permisos.

Ejecutar análisis y pruebas relevantes según el cambio; compilar solo plataformas afectadas. Un cambio exclusivamente documental requiere revisar rutas, comandos, alcance y diff, sin pruebas artificiales que repliquen el texto. No afirmar que una prueba pasó si no se ejecutó.

## Flujo de trabajo del agente

Leer también `.agents/agents.md`; conservar sus reglas válidas. Sus cifras/pendientes históricos se contrastan con código/configuración vigente. Leer instrucciones aplicables antes de modificar archivos, incluidas las de subdirectorios: su alcance local se respeta. Las instrucciones explícitas del usuario prevalecen.

1. Revisar estado del trabajo y comprender el flujo afectado antes de implementar.
2. Hacer cambios acotados al objetivo; respetar cambios existentes del usuario y evitar refactorizaciones ajenas.
3. Reutilizar componentes y dependencias disponibles; justificar dependencias nuevas.
4. Actualizar documentación si cambia comportamiento o configuración.
5. Ejecutar verificaciones pertinentes y comunicar resultados y pendientes con su motivo.
6. No hacer commits, push o despliegues salvo solicitud o autorización previa del usuario. Esta regla prevalece sobre recomendaciones de commit automático en guías antiguas.

No imponer una política nueva de ramas/commits; seguir documentación y CI existentes.

No activar workflows de publicación ni scripts de release como comprobación rutinaria.

## Criterios de finalización

La tarea cumple el comportamiento solicitado, contempla errores/estados relevantes, mantiene convenciones y pasa las verificaciones aplicables que puedan ejecutarse. Comunicar archivos modificados, resultados reales y cualquier validación pendiente con su motivo.

## Limitaciones y aspectos por confirmar

FVM usa canal `stable`, sin pin numérico. Los scaffolds de seis plataformas no demuestran disponibilidad de todos los plugins (SQLite/BLE/geolocalización). Pagos mencionados como futuros en la guía no equivalen a integración implementada.
