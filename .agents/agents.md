# 🧠 Memory Arcade — Agent Context

> Documento de referencia para cualquier agente de IA que trabaje con este proyecto.
> Proporciona contexto arquitectónico, mapa de features y áreas de mejora.

---

## 📌 Visión general

**Memory Arcade** es un juego de memoria multiplataforma desarrollado en Flutter (Dart `^3.10.4`). Es un juego de parejas de cartas con mapa de niveles, reto diario, estadísticas de progreso, minijuegos y componentes sociales. Funciona completamente offline; Firebase solo sincroniza y respalda cuando hay conexión.

- **Nombre anterior:** Memory Companion
- **Paquete Dart:** `memory_companion` (sin cambiar por ahora)
- **Idiomas soportados:** Español e Inglés
- **Repositorio:** `https://github.com/GrullonDev/Memory-Companion.git`

---

## 🏗️ Arquitectura

Organización por **features** (`lib/features/<feature>/{controller,model,repository,widget}`) con infraestructura compartida en `lib/core/`.

```
UI (Riverpod) ◄── Drift/SQLite ◄──► Sync engine ──► Firestore
```

### Principios clave

| Principio | Detalle |
|---|---|
| **Offline-first** | Drift/SQLite es la fuente de verdad. La UI siempre observa la base local. Firestore nunca alimenta una pantalla directamente. |
| **Estado** | Riverpod (`AsyncNotifier` / `Notifier`). |
| **Sincronización** | Motor con cola y reintentos con backoff (`lib/core/sync/`). |
| **Idempotencia** | Cada operación de sync tiene un `opId` único; reintentos no duplican datos. |
| **Identidad** | `localId` (UUID) generado en el primer arranque sin red. Vincular cuenta rellena `cloudUid` sobre el mismo perfil. |

### Stack tecnológico

| Área | Paquetes |
|---|---|
| Framework | Flutter, Dart `^3.10.4` |
| Estado | `flutter_riverpod` |
| Persistencia local | `drift`, `sqlite3_flutter_libs`, `path_provider` |
| Nube | `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in` |
| Conectividad | `connectivity_plus` |
| Localización | `flutter_localization` (mapas `es`/`en` en `lib/core/localization/app_locale.dart`), `intl` |
| UI | `google_fonts` |
| Utilidades | `uuid`, `share_plus` |
| Contexto | `geolocator`, `flutter_blue_plus`, `flutter_ble_peripheral` |
| Búsqueda | `LexicalEmbedder` (embeddings léxicos locales, sin modelos externos) |

### Estructura de features (19 directorios)

`account`, `auth`, `daily_challenge`, `friends`, `game_context`, `game`, `home`, `history_search`, `ladder`, `level_map`, `lives`, `minigames`, `player`, `profile`, `settings`, `shop`, `statistics`, `versus`, `wallet`

### Base de datos local (Drift/SQLite — 12 tablas, esquema v7)

Definidas en `lib/core/database/tables/` (11 archivos: `daily_challenges.dart` contiene dos tablas) y registradas en `@DriftDatabase` de `lib/core/database/app_database.dart`, que documenta el historial de migraciones (`schemaVersion => 7`).

| Tabla | Archivo | Contenido | ¿Sincroniza? |
|---|---|---|---|
| `player_profiles` | `player_profiles.dart` | Identidad (`localId` + `cloudUid`), acumulados, racha | Sí |
| `matches` | `matches.dart` | Partidas terminadas, inmutables; `id` generado al iniciar | Sí |
| `level_progress` | `level_progress.dart` | Progreso por nivel (la definición del nivel se genera en código) | Sí (`completeLevel`) |
| `daily_challenge_defs` | `daily_challenges.dart` | Caché de la definición del reto diario | Caché de nube |
| `daily_challenge_progress` | `daily_challenges.dart` | Progreso y resultado del reto (movimientos, tiempo, cuadrícula) | Sí (`completeChallenge`) |
| `lives_states` | `lives_states.dart` | Vidas y `lastRefillAt` para recargar por reloj | No (no hay operación de sync) |
| `sync_operations` | `sync_operations.dart` | Cola de subida; `opId` = id del doc en `sync_ops` | — (es la cola) |
| `display_settings` | `display_settings.dart` | Perfil visual, temporizador y permisos de contexto. Del dispositivo, no del jugador | No |
| `game_stats` | `game_stats.dart` | Métricas por partida para Estadísticas, más lugar y personas cercanas | No, solo local |
| `category_levels` | `category_levels.dart` | Nivel y habilidad adaptativa por categoría (`SkillState`) | No |
| `places` | `places.dart` | Lugares agrupados (~150 m) donde se juega; las partidas no guardan coordenadas | No, solo local |
| `ladder_rewards` | `ladder_rewards.dart` | Hasta qué nivel de cada escalera ya se pagó el premio | No |

Historial de esquema: 1 inicial · 2 `display_settings` · 3 `game_stats` · 4 resultado del reto en `daily_challenge_progress` · 5 `category_levels` · 6 contexto (`places`, columnas en `game_stats` y `display_settings`) · 7 `ladder_rewards`.

---

## 🎮 Features disponibles

### Juego principal
- **Tablero de parejas** con tres categorías: Clásica, Numérica y Asociación.
- **Dificultad adaptativa:** ajusta parejas y tiempo según errores, pistas y tiempo restante.
- **Mapa de niveles** con progreso y estrellas.

### Minijuegos
- **Dígitos:** memoria de trabajo (número que crece por acierto).
- **Palabras:** memoria de reconocimiento (lista que crece con cada nivel).
- **Crucigrama:** deslizar dedo sobre rueda de letras, 12 niveles en cada idioma.

### Social y competencia
- **Amigos:** código de 6 caracteres, solicitudes, lista con estado en línea.
- **Versus:** duelos asíncronos con misma semilla y dificultad.
- **Cerca de ti (Bluetooth):** descubrimiento local de jugadores.
- **Reto diario:** semilla compartida, racha, resultado para compartir.

### Contexto y búsqueda
- **Contexto automático** (opcional): ubicación del lugar y personas cercanas por Bluetooth. Todo local, nada sale del dispositivo.
- **Búsqueda semántica local:** preguntas en español/inglés sobre el historial usando `LexicalEmbedder` (512 dimensiones, trigramas de caracteres).

### Perfil y economía
- **Estadísticas:** métricas, tendencias, gráfica de evolución, historial.
- **Sistema de vidas** con recarga por tiempo.
- **Tienda de planes** (código presente, pagos reales pendientes).

---

## ⏳ Features pendientes / En desarrollo

| Feature | Estado |
|---|---|
| Tienda de planes (pagos reales) | Código y ruta `/shop` existentes, `ShopController.upgrade` solo cambia plan. Sin integración de pagos. |
| Sugerencia de horario para reto diario | Pendiente; se calcula a partir de la franja de mejor rendimiento. |
| Cloud Functions (validación de partidas) | Fase 2 — cliente escribe solo en `sync_ops`; Function valida y escribe XP/monedas. |
| Multijugador en tiempo real, rankings | Planeado. |

---

## 🎯 Mejoras potenciales

### UX — Interactividad y engagement

1. **Animaciones de carta más expresivas**
   - Ya existe: `SuccessPulse` (`lib/core/widgets/success_pulse.dart`) hace pop + brillo al emparejar cartas, encontrar palabras en el crucigrama y acertar en Dígitos/Palabras; la victoria tiene confeti (`ConfettiOverlay`).
   - Pendiente:
     - Animación de sacudida al fallar una pareja.
     - Volteo 3D de carta (hoy es un fundido con `AnimatedSwitcher`).

2. **Retroalimentación háptica y sonora contextual**
   - La háptica usa `HapticFeedback` de Flutter (`package:flutter/services.dart`); no hace falta ningún paquete. Ya la usan `Pressable` (al pulsar) y `SuccessPulse` (al acertar).
   - Pendiente: patrón distinto al fallar y al voltear carta.
   - No hay audio todavía: los sonidos (éxito, error, tiempo agotándose, racha) requieren añadir un paquete de audio.

3. **Onboarding interactivo con tutorial paso a paso**
   - Primera experiencia del usuario con un walkthrough animado que muestre:
     - Cómo voltear cartas.
     - Cómo funciona la dificultad adaptativa.
     - Cómo funcionan las vidas.
     - Cómo se conectan amigos.
   - Puntos de control con "pruébalo tú" en lugar de solo texto.

4. **Modo práctica / Entrenamiento libre**
   - Antes de jugar un nivel, permitir "calentar" con 2-3 cartas gratis sin penalización.
   - Reducir la ansiedad del primer intento y mejorar la retención de nuevos jugadores.

5. **Perfil visual más personalizable**
   - Avatar con opciones gráficas (mascotas, íconos, colores temáticos).
   - Efectos visuales de perfil que reflejen logros (marco dorado por racha, corona por nivel máximo).
   - Posibilidad de desbloquear "trajes" o temas visuales jugando.

6. **Notificaciones inteligentes y proactivas**
   - Recordatorios de reto diario con horario sugerido (basado en la franja de mejor rendimiento).
   - Notificación cuando un amigo esté en línea o te haya desafiado.
   - Alerta de racha a punto de romperse ("¡Juega ahora para mantener tu racha de 5 días!").
   - Uso de `flutter_local_notifications` para recordatorios contextuales.

7. **Gamificación avanzada**
   - Sistema de logros/badges visibles con descripciones ("Primera victoria sin pistas", "10 partidas seguidas").
   - Tabla de clasificación semanal/mensual (local o entre amigos).
   - Misiones diarias/semanales con recompensa de monedas ("Juega 3 partidas en la categoría Numérica").
   - Puntos de experiencia visibles con barra de progreso animada hacia el siguiente nivel.

8. **Interacción social enriquecida**
   - Chat rápido preescrito durante un Versus ("¡Vaya!", "Casi lo logro", "Te gané").
   - Replays compartibles de partidas (captura de momento + resultado).
   - Sistema de "desafío vocal" o grabación de intentos para compartir.
   - Salas de amigos con estado compartido ("jugando ahora", "viendo estadísticas").

9. **Accesibilidad mejorada**
   - Modo alto contraste para personas con baja visión.
   - Tamaño de cartas escalable.
   - Soporte de lector de pantalla más robusto en todas las pantallas.
   - Reducir dependencia del color para diferenciar categorías (añadir patrones/íconos).

10. **Temas dinámicos y personalización de ambiente**
    - Temas visuales desbloqueables temáticos (espacio, océano, bosque, ciudad).
    - Música de fondo adaptativa al nivel de dificultad o categoría.
    - Posibilidad de crear playlists propias desde el dispositivo.

### UX — Funcionalidad y flujo

11. **Modo split-screen para Versus local**
    - Dos tableros en pantalla cuando ambos jugadores usan el mismo dispositivo.
    - Turnos alternos con indicador visual claro.

12. **Recomendación inteligente de dificultad**
    - Tras 3-5 partidas, el sistema sugiere automáticamente el nivel óptimo según el historial.
    - Indicador visual: "Tu nivel recomendado: Intermedio (3 estrellas en los últimos 5 intentos)".

13. **Resumen post-partida mejorado**
    - Después de cada partida, mostrar:
      - Heatmap de qué parejas tomaste más tiempo.
      - Comparativa con tu promedio histórico.
      - Consejo específico ("Practica la categoría Numérica — tu tiempo ahí es 20% peor").
      - Opción de volver a intentar una pareja fallida inmediatamente.

14. **Buscador de partidas con filtros visuales**
    - Además de la búsqueda semántica, añadir filtros visuales tipo "tag" (categoría, dificultad, lugar, personas).
    - Posibilidad de exportar/resumen de sesiones en formato visual (gráfico de barras de progreso semanal).

15. **Modo avión / práctica offline completa**
    - Garantizar que toda la experiencia (incluyendo Versus con amigos offline vía Bluetooth local) funcione sin conexión.
    - Modo "desafío contra IA" para practicar cuando no hay amigos disponibles.

### Arquitectura y mantenibilidad

16. **Separación del package `memory_companion`**
    - El paquete sigue llamándose `memory_companion`. Una migración limpia a `memory_arcade` requeriría actualizar imports, `pubspec.yaml` y referencias. Hacerlo como un paso de marca definitivo.

17. **Cloud Functions fase 2**
    - Implementar validación de partidas en el servidor para que `totalXp` y `totalCoins` no puedan ser manipulados por el cliente.
    - Hacer `users/{uid}` de solo escritura server-side.

18. **Tests de widgets y golden tests**
    - Añadir tests de widget para las pantallas principales (tablero, estadísticas, perfil).
    - Golden tests para capturas de pantalla de componentes clave y asegurar consistencia visual.

19. **Internacionalización robusta**
    - Verificar que todas las cadenas de texto pasen por `intl` y `flutter_localizations`.
    - Añadir tests de regresión para que nuevas traducciones no rompan layouts.
    - Documentar el proceso de añadir un nuevo idioma.

20. **Monitoreo y analytics discreto**
    - Implementar eventos anónimos de uso (voluntarios, desactivables) para entender qué features se usan más.
    - Métricas de retención (D1, D7, D30) para guiar decisiones de producto.
    - Crash reporting con `firebase_crashlytics`.

---

## 📂 Referencias del proyecto

| Documento | Ruta |
|---|---|
| README | `README.md` |
| Arquitectura offline-first | `docs/OFFLINE_FIRST.md` |
| Reglas de Firestore | `firestore.rules` |
| Setup Firebase | `FIRESTORE_SETUP.md`, `FIREBASE_COMMANDS.md` |
| Auditoría Offline-First | `docs/Auditoria-Offline-First.pdf` |
| Auditoría Rediseño UI | `docs/Auditoria-Rediseno-UI.pdf` |

---

## 📝 Notas para agentes

- **El paquete se llama `memory_companion`** en `pubspec.yaml` y todos los imports usan `package:memory_companion/...`. Esto es solo de marca por ahora.
- **Los tests no dependen de Firebase** — Drift corre en `NativeDatabase.memory()` y el sync usa una `SyncGateway` falsa.
- **`shared_preferences` no es dependencia directa.** Llega de forma transitiva por `flutter_localization`, que guarda ahí el idioma elegido. Los datos de juego y las preferencias de pantalla viven en Drift (`display_settings`).
- **Textos:** toda cadena visible pasa por `AppLocale.<clave>.getString(context)`. Al añadir una clave, decláralo como `static const String clave = 'clave';` y añádela a **ambos** mapas (`es` y `en`) con los mismos marcadores (`{n}`, `{level}`…). `test/core/localization/app_locale_test.dart` falla si falta alguna; si no, en pantalla aparece `clave not found`.
- **Textos que dependen de la hora** ("Hace 2 h") se formatean al pintar con `timeAgoLabel` (`lib/core/localization/time_ago.dart`), nunca en un controlador.
- **Widgets compartidos de disposición y feedback:** `PinnedFooterLayout` (contenido desplazable con controles fijos abajo; lo usan Dígitos y Palabras) y `SuccessPulse` (pop + brillo de acierto; respeta "reducir movimiento").
- **Gestos dentro de listas:** un `GestureDetector` con `onPan*` dentro de un `ListView` pierde los deslizamientos verticales (la lista gana a 18 px, el pan a 36 px). Ver `_LetterGrabRecognizer` en `letter_wheel.dart`.
- **Las reglas de Firestore** validan monotonía en acumulados, listas blancas de campos, e inmutabilidad de partidas.
- **La búsqueda semántica** es completamente local — no usa servicios externos ni modelos descargados. Usa `LexicalEmbedder` con vectores de 512 dimensiones.
- **Cuando modifiques tablas de Drift**, sube `schemaVersion`, añade el paso en `migration` y documéntalo en el historial de `app_database.dart`; luego regenera con `fvm dart run build_runner build --delete-conflicting-outputs`.
- **Flutter vía FVM:** si `flutter` no está en el PATH, usa `.fvm/versions/stable/bin/flutter`.
