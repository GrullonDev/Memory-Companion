---
name: uiux-skill
description: When the user asks about UI, UX, design, visual design, user interface, user experience, animations, interactions, theming, layout, accessibility, color schemes, typography, component design, or anything related to how the app looks and feels — use this skill. Also triggers on phrases like "make it look better," "improve the interface," "design system," "make it more interactive," "add animations," "better onboarding," "visual refresh," "accessibility improvements," "color palette," "component library," or "user experience." This skill should be used whenever working on any visual or interaction aspect of Memory Arcade, even when the user doesn't explicitly mention design or UI.
compatibility: [Dart, Flutter, Material Design 3, Riverpod, Firebase]
---

# 🎨 UI/UX-Skill — Dynamic & User-Friendly Interface for Memory Arcade

> Skill especializado para diseñar, mejorar e implementar la interfaz y experiencia de usuario de **Memory Arcade**. Garantiza que la aplicación se sienta dinámica, atractiva y accesible.

---

## 🧠 Conocimiento del proyecto

### Sistema de diseño existente: "Vibrant Kinetic"

El diseño de Memory Arcade está documentado en `assets/DESIGN.md` y implementado en `lib/core/theme/`. Se basa en un sistema de tokens completo con dos perfiles visuales.

**Frase guía del diseño:**
> "La personalidad vive en las formas, los colores y el motion — nunca en el tamaño de texto, la densidad o el contraste. La tipografía permanece grande y tranquila; el color y la geometría llevan el juego."

### Paleta de colores (5 familias)

| Familia | Significado | Color |
|---|---|---|
| **Sun** | Acción primaria, XP, monedas | `#ffc531` |
| **Sky** | Competencia, multiplayer, social | `#35c4f0` |
| **Mint** | Progreso, rachas, éxito | `#3dd07f` |
| **Violet** | Tienda, cosméticos, desbloqueos | `#a78bfa` |
| **Streak** | Urgencia, "no lo pierdas" | `#ff7a3d` |

Cada familia expone: `X` (saturado), `onX` (texto), `X-soft` (tinte pálido), `X-strong` (oscuro), `X-deep` (presionado).

### Tipografía

- **Quicksand** — Títulos, números, display (redondeada, amigable)
- **Plus Jakarta Sans** — Body, labels, botones (legible a 13px)
- Escalas: `display-lg` (40px) → `label-sm` (12px)

### Motion System

| Token | Duración | Uso |
|---|---|---|
| `instant` | 90ms | Confirmación de presión |
| `fast` | 160ms | Release, toggles |
| `normal` | 220ms | Movimiento/fade default |
| `slow` | 420ms | Progress bars, contadores |
| `celebrate` | 700ms | Efectos de celebración |
| `page` | 280ms | Transiciones de página |

### Dos Perfiles Visuales

| Perfil | Motion | Tipo | Targets | Confeti |
|---|---|---|---|---|
| **Vibrant** (default) | Completo | Normal | 52dp | ✅ |
| **Accessible** | Reducido | +25% | 72dp | ❌ |

### Widgets de diseño implementados

- **Pressable** — Interacción principal: scale + depth + shadow flattening + haptics
- **AppCard** — Contenedor base con radius, shadow, padding
- **GameIcon** — Ícono en well tintado (nunca bare)
- **AppBadge** — Status pill (siempre icon + word)
- **AppStatChip** — Número vivo con icono (tabular figures)
- **AppProgressBar** — Grueso, redondeado, animado con gloss
- **SectionHeader** — Header semántico + acción opcional
- **FloatingBob** — Motion de balanceo suave
- **ConfettiOverlay** — Lluvia de confeti continua
- **AvatarPicker** — Selección de perfil visual

### Estructura de features con UI

- `game/board/` — Tablero de cartas con 3 categorías
- `game/board/category/` — Clásica, Numérica, Asociación
- `game/board/difficulty/` — Adaptativa
- `home/` — Pantalla principal con navegación inferior
- `statistics/` — Métricas y gráficas
- `profile/` — Perfil y logros
- `settings/` — Ajustes y configuración
- `lives/` — Sistema de vidas
- `wallet/` — Monedas y economía visual

### Layouts clave

- Home columna limitada a **560px** (tablets/unfoldables)
- **20px** margins laterales, **14px** gutters, **28px** section gap
- **4px** vertical rhythm
- Squircles (border-radius: `xl` = 24px, hero = 32px)
- Sombras suaves con offset Y (nunca Material tonal elevation)

---

## 🎯 Alcance del skill

Cuando se active, el agente debe:

1. **Analizar** el estado actual de UI/UX usando `assets/DESIGN.md` y `lib/core/theme/`
2. **Identificar** oportunidades de mejora en interactividad, feedback visual, navegación y flujo
3. **Proponer e implementar** mejoras con código Dart, widgets nuevos, o ajustes de tema
4. **Verificar** que los cambios respetan ambos perfiles visuales (vibrant/accessible) y WCAG AA
5. **Mantener** el sistema de tokens — nunca hardcodear colores, spacing o tipografía fuera de `lib/core/theme/`

---

## 📋 Áreas de mejora UI/UX

### 1. Animaciones de transición entre pantallas

**Problema actual:** Las transiciones entre pantallas usan navegación estándar de Flutter sin personalización.

**Mejoras:**
- Implementar `PageRouteBuilder` personalizado con el motion token `page: 280ms`
- Añadir efecto de "carta volando" al navegar al tablero (la carta emerge del nivel seleccionado)
- Transiciones diferenciadas por tipo de navegación: push, pop, replace, new route
- Añadir shared element transitions al navegar desde Home → LevelMap (el medallion del nivel crece hasta llenar la pantalla)
- Responder a `MediaQuery.disableAnimationsOf()` para el perfil accessible

**Archivos afectados:**
- `lib/core/routes/` (adaptar navegación)
- `lib/features/home/` (añadir hero animations)

### 2. Feedback visual en tiempo real durante el juego

**Problema actual:** El juego tiene `Pressable` y `FloatingBob` pero las cartas del tablero carecen de feedback enriquecido.

**Mejoras:**
- Cuando se revela una carta: efecto de "glow" pulsante usando `AnimatedContainer` con `BoxShadow` animada
- Cuando se encuentra pareja: animación de coincidencia con `ConfettiOverlay` (ya existente) + `scale` burst + `HapticFeedback.lightImpact()`
- Cuando se falla: la carta vuelve a girar con efecto de "shake" horizontal (`Transform.translate` oscilante a `instant` 90ms)
- Timer visual: barra circular animada que se contrae (`AnimatedBuilder` + `CustomPainter`) alrededor del borde de la pantalla
- Indicador de streak: efecto de fuego/partículas alrededor del badge de racha (`FloatingBob` con colores de Streak)

**Archivos afectados:**
- `lib/features/game/board/` (widgets de cartas)
- `lib/core/widgets/confetti_overlay.dart` (ya existe, extender)
- `lib/features/lives/` (badges de streak)

### 3. Micro-interacciones en Home y navegación

**Problema actual:** La Home tiene `PrimaryPlayCard` y `SectionHeader` pero las interacciones secundarias son estáticas.

**Mejoras:**
- **Sistema de badges animados**: Cuando hay notificaciones pendientes, el badge en el nav item pulsa con `scale` alternado
- **Bottom Navigation**: Cada ícono tiene un `FloatingBob` sutil (amplitud 3px, duration 3s) y al presionar muestra un `AppBadge` con ripple
- **Pull-to-refresh**: En la Home, gesto de pull que muestra una animación del logo de la mascota
- **Cards con hover intent**: Cuando el cursor pasa sobre una tarjeta en desktop, se eleva suavemente (`BoxShadow` intenso + `Transform.translate`)
- **Scroll effects**: Los headers se contraen al hacer scroll (collapsing header), y los íconos de stats flotan encima del contenido
- **Skeleton loading**: Mientras carga datos, mostrar placeholders con shimmer en lugar de spinners circulares

**Archivos afectados:**
- `lib/features/home/widget/home_bottom_nav.dart`
- `lib/features/home/home_screen.dart`
- `lib/core/widgets/app_badge.dart` (extender)

### 4. Onboarding interactivo con tutorial contextual

**Problema actual:** No hay sistema de onboarding. El usuario llega a la Home sin guía.

**Mejoras:**
- **Tutoría paso a paso** con overlays semitransparentes (`scrimColor` del perfil) que guían el dedo al elemento relevante:
  - Paso 1: "Presiona aquí para jugar" → señal al PrimaryPlayCard
  - Paso 2: "Aquí tienes tu racha" → señal al streak badge
  - Paso 3: "Tu reto diario" → señal al DailyChallengeCard
  - Paso 4: "Busca minijuegos" → señal al minigame grid
- Cada paso usa un `FloatingBob` con la mascota apuntando al elemento
- Al completar onboarding, mostrar `ConfettiOverlay` breve + `HapticFeedback.successFeedback()`
- El onboarding solo se muestra una vez (guardar en `shared_preferences` con clave `onboarding_complete`)
- Permitir skip y re-acceso desde Settings

**Archivos afectados:**
- `lib/features/home/home_screen.dart` (inyectar onboarding)
- `lib/features/settings/` (agregar opción de reiniciar onboarding)
- Nuevo: `lib/features/onboarding/`

### 5. Personalización visual avanzada

**Problema actual:** El sistema tiene `VisualProfile` (vibrant/accessible) y `avatarSeed` pero la personalización es limitada.

**Mejoras:**
- **Tema dinámico**: Añadir un tercer perfil "Seasonal" que cambie los tonos de `Sun` y `Mint` según la estación del año del dispositivo
- **Accentos de color**: Permitir que el jugador seleccione un color de acento desde la paleta de 5 familias (`AppColors`) que reemplace el `Sun` primario
- **Mascota personalizable**: Extender `AvatarPicker` con accesorios (gorros, monturas, alas) desbloqueables con monedas
- **Temas de carta**: Desbloquear skins para las cartas (ej: "Espacio", "Océano", "Fuego") que cambien el diseño de `cardFaceDownColor`, `cardFaceUpBorderColor`, y el símbolo de los íconos
- **Notificaciones personalizadas**: Elegir qué tipo de notificaciones mostrar (streak, amigos, nuevos niveles)
- **Guardar preferencias en `player_profiles`**: No en `shared_preferences` — la identidad visual es parte del perfil del jugador

**Archivos afectados:**
- `lib/core/theme/` (extender ProfileTokens)
- `lib/features/settings/settings_screen.dart`
- `lib/features/profile/`
- `lib/features/wallet/` (gastar monedas en skins)

### 6. Animaciones de progreso y recompensa

**Problema actual:** `AppProgressBar` existe pero las recompensas se sienten planas.

**Mejoras:**
- **Contador animado**: Cuando sube el contador de monedas/XP, que el número cuente hacia arriba (como un odometer) usando `TweenAnimationBuilder` con `slow: 420ms`
- **Glow en recompensas**: Cuando se ganan monedas, mostrar un `AnimatedContainer` con `BoxShadow` expandiéndose en color `Sun` durante `celebrate: 700ms`
- **Barra de nivel progresiva**: Cuando se sube de nivel, la barra se llena con un efecto de "líquido" (`ClipPath` con wave animation) + confeti burst
- **Racha visual**: Cuando se extiende la racha, el badge de streak se enciende con un gradiente animado de `Streak` → `Sun` y partículas
- **Nivel desbloqueado**: Cuando se desbloquea un nuevo nivel, el medallion del mapa brilla con `BoxShadow` pulsante

**Archivos afectados:**
- `lib/core/widgets/app_progress_bar.dart`
- `lib/features/wallet/` (animaciones de monedas)
- `lib/features/level_map/` (medallones animados)
- `lib/features/lives/` (badge de racha)

### 7. Accesibilidad mejorada

**Problema actual:** El perfil accessible existe pero algunas pantallas no lo respetan completamente.

**Mejoras:**
- **Focus navigation**: Implementar navegación por tabulación para desktop con `FocusNode` visible y `FocusHighlight` personalizado
- **Screen reader mejorado**: Todos los widgets interactivos tienen `semanticsLabel` + `semanticsHint`. Verificar cada pantalla del juego
- **Contrast mode**: Añadir un modo de alto contraste real (no solo el perfil accessible) que use `Colors.black` y `Colors.white` absolutos
- **Texto dinámico**: Probar con `MediaQuery.textScaleFactor` hasta 2.0 (más allá del clamp actual de 1.35)
- **Botones de acción masiva**: En pantinas con muchos elementos, añadir un "modo simplificado" que reduzca la Home a 5 elementos principales
- **Navegación por voz preliminar**: Integrar `speech_to_text` para navegar por la app con comandos de voz simples ("Jugar", "Estadísticas", "Amigos")

**Archivos afectados:**
- `lib/features/` (cada pantalla)
- `lib/core/theme/app_theme.dart` (modo alto contraste)
- `lib/features/settings/settings_screen.dart` (toggle de modo simplificado)

### 8. Dark Mode y temas extendidos

**Problema actual:** No hay modo oscuro. Todo funciona sobre colores claros (`surface: '#f7f8fc'`).

**Mejoras:**
- Implementar `ThemeMode.system` + toggle manual en Settings
- Crear variantes oscuras de TODOS los tokens en `app_colors.dart`:
  - `surface` → `#1b2434` (inverse-surface actual)
  - `on-surface` → `#eef2f9` (inverse-on-surface actual)
  - Las 5 familias necesitan variantes dark (ej: Sun dark = `#ffd666`, no la versión clara)
- Asegurar que todos los WCAG ratios se mantengan en dark mode
- `ProfileTokens` necesita extenderse con tokens dark
- Transición suave entre light/dark con `AnimatedTheme`

**Archivos afectados:**
- `lib/core/theme/app_colors.dart` (variantes dark)
- `lib/core/theme/app_theme.dart` (ThemeMode)
- `lib/core/theme/profile_tokens.dart` (tokens dark)
- `lib/features/settings/` (toggle de tema)

### 9. Interacción social en UI

**Problema actual:** Las pantallas de amigos y versus tienen UI funcional pero sin micro-interacciones.

**Mejoras:**
- **Avatar stacking**: Cuando hay múltiples amigos online, mostrar sus avatares en un stack superpuesto con `FloatingBob` desfasado
- **Estado en línea**: Indicador de estado con pulso verde (`AnimatedContainer` con `scale` alternado)
- **Versus countdown**: Antes de iniciar un duelo, mostrar un cronómetro circular animado con los avatares de ambos jugadores
- **Chat de reacciones**: En Versus, añadir reacciones rápidas con animación de "vuelo" hacia el otro jugador
- **Result sharing**: Al compartir resultado, animación de la imagen "volando" hacia el icono de compartir (`share_plus`)
- **Friend request animation**: Cuando llega una solicitud, la tarjeta se desliza desde el borde derecho con `SlideTransition` + `HapticFeedback.mediumImpact()`

**Archivos afectados:**
- `lib/features/friends/`
- `lib/features/versus/`
- `lib/features/account/`

### 10. Gestos y navegación táctil

**Problema actual:** La navegación es principalmente por bottom navigation. Faltan gestos avanzados.

**Mejoras:**
- **Swipe to dismiss**: En el historial de partidas, deslizar para archivar/eliminar con `Dismissible` + snap-back animation
- **Long press context menu**: Mantener presionado un nivel en el mapa para ver opciones (jugar, ver stats, compartir)
- **Drag to reorder**: En el tablero de cartas, permitir reorganizar manualmente (modo experto) con `ReorderableListView`
- **Pull-to-reveal**: En el perfil, hacer pull desde el header para revelar opciones de edición rápida
- **Edge swipe**: Volver atrás con gesto de borde en todas las pantallas (sistema de `WillPopScope` con animación personalizada)
- **Pinch to zoom**: En la gráfica de estadísticas, permitir zoom con `InteractiveViewer`

**Archivos afectados:**
- `lib/features/statistics/`
- `lib/features/level_map/`
- `lib/features/history/` (o equivalente)
- `lib/features/profile/`

### 11. Rendimiento y percepción de velocidad

**Problema actual:** El diseño prioriza la suavidad pero puede haber percepción de lentitud en cargas.

**Mejoras:**
- **Staggered list animations**: Los elementos de la Home aparecen secuencialmente (100ms cada uno) con `StaggeredAnimation` en `ListView`
- **Skeleton shimmer**: Mientras cargan datos, mostrar `Shimmer` con tono de `surface-container-high` sobre los widgets
- **Optimistic UI**: Cuando una acción es inmediata (como aceptar amigo), actualizar la UI instantáneamente antes de que el servidor confirme
- **Prefetch**: Cargar imágenes de avatares y assets de cartas anticipadamente al abrir la Home
- **Frame budget**: Asegurar que las animaciones del juego corren a 120fps en dispositivos que lo soportan (`SchedulerBinding` + `RasterCache`)
- **Lazy loading**: La grid de minijuegos carga perezosamente con `ListView.builder` y `SliverToBoxAdapter`

**Archivos afectados:**
- `lib/features/home/home_screen.dart` (staggered animations)
- `lib/features/minigames/hub/` (lazy loading)
- `lib/friends/`, `lib/versus/` (optimistic UI)

### 12. Sonido y retroalimentación háptica

**Problema actual:** `Pressable` tiene `HapticFeedback.selectionClick()` y `mediumImpact()` pero el sistema de sonido es inexistente.

**Mejoras:**
- **Sistema de audio contextual**: Usar `just_audio` o `audioplayers`:
  - Click suave al voltear carta (`instant` 90ms)
  - Ascendencia al encontrar pareja (melodía de 2 notas, `slow: 420ms`)
  - Error: tono bajo descendente (`instant`)
  - Timer bajo: pulso rítmico creciente (`normal: 220ms`)
  - Victoria: progresión armónica completa (`celebrate: 700ms`)
  - Cada perfil tiene su propio set de sonidos (vibrant = alegre, accessible = suave)
- **Silenciador persistente**: El usuario puede silenciar en Settings; la preferencia se guarda en el perfil del jugador
- **Audio spatial**: Para Versus, el sonido del rival viene de la dirección opuesta
- **Haptic patterns avanzados**: Diferentes patrones para cada evento:
  - Acierto: `[HapticFeedback.lightImpact()]` x2 rápido
  - Error: `[HapticFeedback.heavyImpact()]` largo
  - Streak: `[light, light, heavy]` (patrón de racha)
  - Nuevo nivel: `[light, light, light, light, heavy]`

**Archivos afectados:**
- `lib/core/` (nuevo directorio `audio/`)
- `lib/features/game/board/` (integrar audio)
- `lib/features/settings/` (toggle de sonido)

---

## ⚠️ Principios de UI/UX del proyecto

Cualquier mejora debe respetar:

1. **Tokens primero**: Nunca hardcodear colores, spacing, o tipografía fuera de `lib/core/theme/`
2. **Dos perfiles**: Cada cambio debe funcionar en `VisualProfile.vibrant` Y `VisualProfile.accessible`
3. **Motion en transform/opacity**: `Pressable` ya honra `prefers-reduced-motion` — extender eso a todos los nuevos widgets
4. **WCAG AA**: Cada par foreground/background debe pasar 4.5:1 para texto, 3:1 para iconos. Consultar `assets/DESIGN.md`
5. **Touch targets**: Mínimo 48dp (56dp en controles primarios). Consultar `ProfileTokens`
6. **Off-screen first**: Los widgets no deben depender de datos de red para renderizar. El estado local es la fuente de verdad.
7. **Colour + Icon + Word**: Nunca usar color solo como portador de significado
8. **Squircles**: Todos los corners deben tener radius definido. Cero 90-degree corners
9. **Tipografía**: Quicksand para headings, Plus Jakarta Sans para body. Nunca mezclar familias
10. **4px rhythm**: Todo spacing debe ser múltiplo de 4px

---

## 🔧 Cómo trabajar con este skill

### Al recibir una tarea UI/UX:

1. **Clasificar** la tarea en una de las 12 secciones anteriores
2. **Leer** `assets/DESIGN.md` y los archivos relevantes en `lib/core/theme/`
3. **Verificar** que los tokens existentes cubren lo necesario — si no, extender `ProfileTokens` primero
4. **Implementar** con widgets que respeten `Pressable`, `AppCard`, y el sistema de motion
5. **Probar** con ambos perfiles (vibrant y accessible)
6. **Verificar** que `fvm flutter test` sigue pasando
7. **Documentar** cualquier nuevo token añadido a `app_colors.dart` o `profile_tokens.dart`

### Priorización recomendada:

| Prioridad | Área | Impacto UX |
|---|---|---|
| 🔴 Alta | 2 (Feedback en juego), 6 (Progreso/recompensa) | Core del juego |
| 🟠 Media-Alta | 1 (Transiciones), 3 (Home), 4 (Onboarding) | Primera impresión |
| 🟡 Media | 5 (Personalización), 8 (Dark Mode), 9 (Social) | Retención |
| 🟢 Baja-Media | 7 (Accesibilidad), 10 (Gestos), 11 (Rendimiento), 12 (Audio) | Robustez |

---

## 📂 Referencias del proyecto

| Documento | Ruta |
|---|---|
| DESIGN.md | `assets/DESIGN.md` |
| Theme colors | `lib/core/theme/app_colors.dart` |
| Theme motion | `lib/core/theme/app_motion.dart` |
| Theme spacing | `lib/core/theme/app_spacing.dart` |
| Theme typography | `lib/core/theme/app_typography.dart` |
| Theme shadows | `lib/core/theme/app_shadows.dart` |
| Visual profiles | `lib/core/theme/visual_profile.dart` |
| Profile tokens | `lib/core/theme/profile_tokens.dart` |
| App theme | `lib/core/theme/app_theme.dart` |
| Pressable widget | `lib/core/widgets/pressable.dart` |
| Confetti overlay | `lib/core/widgets/confetti_overlay.dart` |
| Floating bob | `lib/core/widgets/floating_bob.dart` |
| Home screen | `lib/features/home/home_screen.dart` |
| Auth controller | `lib/features/auth/controller/auth_controller.dart` |
| Agents context | `.agents/agents.md` |
| Security skill | `.agents/skills/security-skill/SKILL.md` |
