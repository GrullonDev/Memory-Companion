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
- **Cuenta opcional:** Google, teléfono o correo con Firebase Auth. El progreso de un jugador local se migra al vincular la cuenta.
- **Perfiles visuales y ajustes de pantalla**, con textos en español e inglés.

### En desarrollo (UI con datos de ejemplo)

- **Amigos** y **Versus:** las pantallas existen, pero los controladores devuelven datos simulados.
- **Tienda de planes:** la compra aún no está conectada a pagos reales; `ShopController.upgrade` solo cambia el plan activo.

---

## 🧭 Roadmap: contexto y búsqueda

Estas dos funciones aún **no están implementadas**. Son las siguientes apuestas para darle más valor a la app:

### Contexto automático inteligente

Cada partida guardará automáticamente dónde, cuándo y con quién se jugó:

- 📍 **Ubicación:** con qué frecuencia y dónde juegas (por ejemplo, "en casa" frente a "en el trayecto"), para ver dónde te concentras mejor.
- 🕒 **Hora y fecha:** detectar en qué momentos del día rinde más tu memoria y sugerir el mejor horario para el reto diario.
- 👥 **Personas cercanas (Bluetooth):** descubrir jugadores cerca para partidas Versus locales y registrar con quién jugaste.

### Búsqueda semántica natural

Preguntar sobre tu historial en lenguaje natural, sin filtros ni etiquetas:

- _"¿Cuál fue mi mejor partida del viernes?"_
- _"¿En qué categoría mejoré más este mes?"_
- _"¿Contra quién jugué la semana pasada en el parque?"_

### Plan técnico propuesto

- [ ] Columnas de contexto (ubicación, dispositivos cercanos) en la tabla `matches` de Drift, más su migración.
- [ ] `geolocator` para la ubicación y `flutter_blue_plus` para el escaneo de proximidad, siempre con permiso explícito y opcional.
- [ ] Embeddings locales del historial de partidas para la búsqueda semántica, sin enviar datos fuera del dispositivo.
- [ ] Conectar Amigos y Versus a Firestore y al descubrimiento por Bluetooth.
- [ ] Integrar pagos reales en la tienda.

---

## 🏗️ Arquitectura

Organización por _features_ (`lib/features/<feature>/{controller,model,repository,widget}`) con infraestructura compartida en `lib/core/`.

- **Estado:** Riverpod (`AsyncNotifier` / `Notifier`).
- **Offline-first:** la base local **Drift (SQLite)** es la fuente de verdad del juego. La UI siempre observa la base local; Firestore nunca alimenta una pantalla directamente.
- **Sincronización:** un motor con cola y reintentos con backoff (`lib/core/sync/`) sube los cambios a Firestore cuando hay conexión.

```
UI (Riverpod) ◄── Drift/SQLite ◄──► Sync engine ──► Firestore
```

Detalles completos en [docs/OFFLINE_FIRST.md](docs/OFFLINE_FIRST.md).

---

## 🛠️ Stack tecnológico

| Área | Paquetes |
| --- | --- |
| Framework | Flutter, Dart `^3.10.4` |
| Estado | `flutter_riverpod` |
| Persistencia local | `drift`, `sqlite3_flutter_libs`, `path_provider` |
| Nube | `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in` |
| Conectividad | `connectivity_plus` |
| Localización | `flutter_localization`, `intl` |
| UI | `google_fonts` |
| Utilidades | `uuid`, `share_plus` |

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

Sigue [FIRESTORE_SETUP.md](FIRESTORE_SETUP.md) y [FIREBASE_COMMANDS.md](FIREBASE_COMMANDS.md). Las reglas de seguridad están en `firestore.rules`.

### 5. Ejecutar

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

Las Pull Requests son bienvenidas. Para cambios grandes, en especial las funciones del roadmap, abre primero un issue para discutir el enfoque.

---

_Desarrollado con ❤️ para mantener la mente en forma._
