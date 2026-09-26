# 🧠 Memory Arcade

> "Entrena tu memoria jugando, con o sin Internet."

**Memory Arcade** (antes _Memory Companion_) es un juego de memoria para Flutter: parejas de cartas, mapa de niveles, reto diario y estadísticas de progreso. La dificultad se adapta a cada jugador y todo funciona offline; la cuenta en la nube solo respalda y sincroniza.

---

## ✨ Características

### Disponibles

- **Tablero de parejas con tres categorías:** Clásica, Numérica y Asociación (`lib/features/game/board/category/`).
- **Dificultad adaptativa:** cada ronda ajusta el número de parejas y el tiempo según los errores de memoria, las pistas usadas y el tiempo restante (`lib/features/game/board/difficulty/`).
- **Mapa de niveles** con progreso y estrellas por nivel.
- **Reto diario** con semilla compartida, racha y resultado para compartir (`share_plus`).
- **Sistema de vidas** con recarga por tiempo.
- **Estadísticas:** métricas clave, tendencias, gráfica de evolución e historial de partidas.
- **Perfil:** nivel del jugador, logros e historial.
- **Hub de minijuegos:** registrar un juego nuevo es una línea en `MinigameRegistry`. Además del tablero de memoria incluye:
  - **Dígitos:** recuerda un número que crece un dígito por acierto, en orden o al revés (memoria de trabajo).
  - **Palabras:** estudia una lista y luego di qué palabras estaban en ella; cada nivel superado suma dos palabras (memoria de reconocimiento).
  - **Crucigrama:** desliza el dedo sobre una rueda de 3 a 6 letras para formar palabras que llenan un pequeño crucigrama, con pistas y botón de mezclar. 12 niveles en español y 12 en inglés; el progreso se guarda por idioma.
- **Amigos:** cada jugador con cuenta tiene un código de amigo de 6 caracteres para compartir o copiar. Se agrega a alguien escribiendo su código; las solicitudes se aceptan o rechazan, y la lista muestra nivel y estado (en línea, en partida o desconectado).
- **Versus:** duelos asíncronos contra un amigo. Los dos juegan el mismo tablero (misma semilla y dificultad fija), cada uno cuando pueda, y gana la mejor puntuación (desempata el tiempo). La pantalla muestra tu carta frente a la del rival, tu forma en los últimos duelos, los retos pendientes y los resultados.
  - **Contra la CPU:** duelo sin conexión ni cuenta, en tres niveles (fácil, normal, difícil). La CPU juega el mismo tablero con una memoria que olvida: recuerda cada carta vista con una probabilidad según el nivel, y su resultado se puntúa con la misma fórmula del tablero. La semilla del duelo fija el resultado, así que salir y volver no cambia el rival (`lib/features/versus/cpu/`).
  - **Salas con código:** en Amigos, la tarjeta "Sala de juego" crea una sala con un código aleatorio de 6 caracteres; quien lo escriba se une al duelo sin necesidad de ser amigos. Compartir el código es la invitación.
- **Cerca de ti (Bluetooth):** en Amigos, "Buscar cerca" encuentra a otros jugadores con la app abierta alrededor, para agregarlos o retarlos sin escribir el código. Los dos tienen que estar buscando a la vez (o tener activadas las "Personas cercanas").
- **Contexto automático (opcional, apagado por defecto):** en Ajustes › Contexto automático se activa, por separado y solo tras conceder el permiso:
  - **Ubicación:** cada partida guarda en qué _lugar_ se jugó. Las posiciones se agrupan en lugares de unos 150 m que puedes nombrar ("Casa", "Parque"); las partidas no guardan coordenadas.
  - **Personas cercanas:** mientras la app está abierta te anuncias por Bluetooth con tu código de amigo, y al terminar cada partida se registra quién jugaba cerca (4 s de escaneo).
  - El historial de Estadísticas muestra el lugar y las personas de cada partida. Nada de esto sale del dispositivo.
- **Búsqueda en tu historial:** en Estadísticas, "Pregúntale a tu historial" responde preguntas en español o inglés, por ejemplo:
  - _"¿Cuál fue mi mejor partida del viernes?"_
  - _"¿En qué categoría mejoré más este mes?"_
  - _"¿Contra quién jugué la semana pasada en el parque?"_
  - _"¿Dónde me concentro mejor?"_ / _"¿A qué hora rindo mejor?"_ / _"¿Cuántas partidas gané esta semana?"_

  Todo se calcula en el dispositivo (ver [Búsqueda semántica](#-búsqueda-semántica-local)).

- **Cuenta opcional:** Google, teléfono o correo con Firebase Auth. El progreso de un jugador local se migra al vincular la cuenta. Al entrar por teléfono, que no trae nombre, se pide completar el perfil con un nombre visible (`lib/features/auth/complete_profile/`). Amigos, Versus en línea, las salas y las Personas cercanas requieren cuenta.
- **Perfiles visuales y ajustes de pantalla**, con textos en español e inglés.

### En desarrollo

- **Tienda de planes:** oculta en la UI (pestaña, acceso desde las monedas, tarjeta de la Home y botón del diálogo sin vidas están comentados). El código y la ruta `/shop` siguen en el proyecto; la compra aún no está conectada a pagos reales y `ShopController.upgrade` solo cambia el plan activo.

---

## 🔎 Búsqueda semántica local

La búsqueda (`lib/features/history_search/`) no usa ningún servicio externo ni descarga modelos:

1. **Analizador de preguntas** (`QueryParser`): reglas en español e inglés que detectan qué se pregunta (mejor o peor partida, qué categoría mejoró, con quién, dónde, a qué hora, cuántas) y cuándo ("hoy", "el viernes", "los viernes", "la semana pasada", "este mes", "en marzo", "últimos 7 días"), además del lugar mencionado ("en el parque").
2. **Filtros:** fechas, lugar, categoría y persona que nombre la pregunta.
3. **Respuesta:** si la pregunta tiene una forma conocida, una métrica la contesta: la precisión es Σ parejas / Σ turnos, como en Estadísticas. Si no, se ordenan las partidas por similitud con la pregunta.

La similitud usa **embeddings léxicos locales** (`LexicalEmbedder`): cada partida se describe como texto (juego, día, mes, franja horaria, resultado, lugar y personas) y se convierte en un vector de 512 dimensiones. El vector combina conceptos compartidos entre idiomas ("viernes" = "Friday", "gané" = "won", "casa" = "home") y trigramas de caracteres, que toleran tildes, plurales y erratas. Es un modelo léxico, no neuronal: entiende palabras y sinónimos del léxico, no paráfrasis libres. Está detrás de la interfaz `TextEmbedder`, así que puede cambiarse por un modelo on-device sin tocar el resto.

Si la pregunta nombra un lugar que no existe, la respuesta lo dice en vez de ignorarlo, y siempre muestra cómo se interpretó la pregunta ("Entendí: 14–20 sept · Parque").

### Pendiente

- [ ] Sugerir el mejor horario para el reto diario a partir de la franja en la que más rindes (hoy solo se consulta con "¿A qué hora rindo mejor?").
- [ ] Integrar pagos reales en la tienda y volver a mostrarla.

---

## 🏗️ Arquitectura

Organización por _features_ (`lib/features/<feature>/{controller,model,repository,widget}`) con infraestructura compartida en `lib/core/`.

- **Estado:** Riverpod (`AsyncNotifier` / `Notifier`).
- **Offline-first:** la base local **Drift (SQLite)** es la fuente de verdad del juego. La UI siempre observa la base local; Firestore nunca alimenta una pantalla directamente.
- **Sincronización:** un motor con cola y reintentos con backoff (`lib/core/sync/`) sube los cambios a Firestore cuando hay conexión.
- **Reintentos de providers:** `appProviderRetry` (`lib/core/firebase/provider_retry.dart`) conserva el reintento con backoff de Riverpod, pero no reintenta los errores permanentes de Firebase (`permission-denied`, `unauthenticated`, `not-found`…): la pantalla muestra "Reintentar" al momento en vez de quedarse cargando ~40 s.
- **Contexto y búsqueda, solo locales:** el lugar y las personas cercanas se guardan en `game_stats` (tabla que nunca se sincroniza) y en `places`, no en `matches`, que sí sube a la nube. La captura (`lib/features/game_context/`) corre al registrar cada resultado en `MinigameResultReporter`; si falla o no hay permiso, la partida se guarda igual, sin contexto.
- **Bluetooth:** `flutter_blue_plus` solo escanea, así que el anuncio usa `flutter_ble_peripheral`. El código de amigo viaja dentro de un UUID de servicio de 128 bits (prefijo fijo de Memory Arcade + 6 caracteres), el único campo que Android e iOS anuncian y leen por igual. No se transmite nada más, ni nombre ni ubicación.

```
UI (Riverpod) ◄── Drift/SQLite ◄──► Sync engine ──► Firestore
```

Detalles completos en [docs/OFFLINE_FIRST.md](docs/OFFLINE_FIRST.md).

---

## 🛠️ Stack tecnológico

| Área               | Paquetes                                                              |
| ------------------ | --------------------------------------------------------------------- |
| Framework          | Flutter, Dart `^3.10.4`                                               |
| Estado             | `flutter_riverpod`                                                    |
| Persistencia local | `drift`, `sqlite3_flutter_libs`, `path_provider`                      |
| Nube               | `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in` |
| Conectividad       | `connectivity_plus`                                                   |
| Localización       | `flutter_localization`, `intl`                                        |
| UI                 | `google_fonts`                                                        |
| Utilidades         | `uuid`, `share_plus`                                                  |
| Contexto           | `geolocator`, `flutter_blue_plus`, `flutter_ble_peripheral`           |

---

## 🚀 Configuración inicial

### Requisitos previos

- Flutter SDK (canal stable). El proyecto usa [FVM](https://fvm.app/); los comandos se muestran con `fvm`.
- Android Studio o Xcode para emuladores y dependencias nativas.
- Un proyecto de Firebase (solo necesario para cuentas y sincronización).

### 1. Clonar el repositorio

```bash
git clone https://github.com/GrullonDev/Memory-Companion.git
cd Memory-Companion
```

### 2. Instalar dependencias

```bash
fvm flutter pub get
```

### 3. Generar el código de Drift

Necesario la primera vez y cada vez que cambies una tabla en `lib/core/database/tables/`:

```bash
fvm dart run build_runner build
```

### 4. Configurar Firebase

Sigue [FIRESTORE_SETUP.md](FIRESTORE_SETUP.md) y [FIREBASE_COMMANDS.md](FIREBASE_COMMANDS.md). Las reglas de seguridad están en `firestore.rules`; Amigos, Versus y las salas usan las colecciones `user_index`, `friendships` y `duels`, así que hay que desplegar las reglas actualizadas:

```bash
firebase deploy --only firestore:rules --project memory-compaknion
```

> Si Amigos o Versus muestran "Reintentar" con `permission-denied`, casi siempre es que las reglas desplegadas están desactualizadas.

### 5. Permisos (contexto automático)

Ya están declarados; solo se piden cuando el jugador activa cada opción en Ajustes:

- **Android:** `ACCESS_COARSE_LOCATION` en `AndroidManifest.xml`. Los de Bluetooth (`BLUETOOTH_SCAN`, `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT`) los aporta `flutter_ble_peripheral`.
- **iOS:** `NSLocationWhenInUseUsageDescription` y `NSBluetoothAlwaysUsageDescription` en `Info.plist`. iOS solo se anuncia con la app en primer plano.

### 6. Ejecutar

```bash
fvm flutter run
```

### Pruebas

```bash
fvm flutter test
```

> **Nota:** el paquete de Dart sigue llamándose `memory_companion` (los imports usan `package:memory_companion/...`). El cambio de nombre a Memory Arcade es, por ahora, solo de marca.

---

## 🤝 Contribuir

Las Pull Requests son bienvenidas. Para cambios grandes, en especial las funciones pendientes, abre primero un issue para discutir el enfoque.

---

_Desarrollado con ❤️ para mantener la mente en forma._
