# Arquitectura offline-first

> El principio del producto: **el jugador siempre debe poder jugar, aunque no
> tenga Internet.** Firebase sincroniza, respalda y conecta con otros. No es
> un requisito para jugar.

---

## 1. El flujo de datos

```
        JUGADOR LOCAL                JUGADOR CON CUENTA
              │                              │
              └──────────────┬───────────────┘
                             ▼
                   BASE LOCAL (Drift/SQLite)
                   fuente de verdad del gameplay
                             │
                    ┌────────┴────────┐
                    ▼                 ▲
              SYNC ENGINE  ────►  FIRESTORE
              cola · backoff      respaldo · social
                    │
                    ▼
                 RIVERPOD
                    │
                    ▼
                   HOME
```

La UI observa **siempre** la base local. Firestore nunca alimenta una
pantalla directamente: escribe en la base local, y la base local despierta a
Riverpod.

## 2. La base local

`lib/core/database/` — Drift sobre SQLite. Ocho tablas:

| Tabla | Qué guarda |
| --- | --- |
| `player_profiles` | El jugador: identidad, acumulados, racha |
| `matches` | Historial de partidas |
| `level_progress` | Solo el progreso; la definición se genera en código |
| `daily_challenge_defs` | Caché del contenido del reto |
| `daily_challenge_progress` | Progreso del jugador en el reto |
| `lives_states` | Vidas y momento de la última recarga |
| `sync_operations` | La cola de subida |

Para regenerar el código tras tocar una tabla:

```bash
fvm dart run build_runner build
```

**`shared_preferences` no guarda datos de juego.** Queda para preferencias
simples (idioma, sonido).

## 3. Identidad: jugador local y jugador con cuenta

`player_profiles.localId` es un UUID que se genera en el **primer arranque**,
sin red y sin preguntar nada. **Nunca cambia.**

Crear una cuenta **no crea un perfil nuevo**: rellena `cloudUid` sobre esa
misma fila. No hay traspaso, hay vinculación — y por eso vincular no puede
perder progreso.

No se usa `signInAnonymously()` de Firebase: exigiría red justo en el primer
arranque, el momento que más queremos blindar, y ataría la identidad a un
servicio que debe ser opcional.

## 4. El motor de sincronización

`lib/core/sync/`

- **`SyncQueue`** — DAO sobre `sync_operations`. Al compartir la base con los
  repositorios, encolar dentro de la transacción que hace el cambio local
  participa de esa transacción: nunca queda progreso local sin su orden de
  subida.
- **`SyncEngine`** — procesa la cola en serie y en orden de creación.
- **`SyncGateway`** — la interfaz. `FirestoreSyncGateway` la implementa; los
  tests usan una falsa para poder provocar fallos a voluntad.

### Idempotencia

`opId` es además el id del documento en `users/{uid}/sync_ops/{opId}`. La
transacción remota lo lee primero; si existe, la operación ya se aplicó y no
hace nada. Si no, aplica el efecto **y** escribe el registro, ambos dentro de
la misma transacción.

Eso cubre el caso peligroso: la operación se envía, la respuesta se pierde, y
se reintenta.

### Reintentos

| Fallo | Qué se hace |
| --- | --- |
| Red, `unavailable`, `deadline-exceeded` | Backoff: 2s, 8s, 30s, 2min, 10min, 1h. Ocho intentos. |
| `permission-denied`, `invalid-argument` | No se reintenta. Insistir no lo arregla. |
| Sin cuenta | La operación espera indefinidamente: es el backlog del jugador. |

Un fallo transitorio **detiene la pasada**: si la red está caída, seguir con
las 24 operaciones restantes solo gasta batería y las condena a todas.

Lo que quedó en `syncing` por una muerte de la app se rescata al arrancar el
motor. Como la subida es idempotente, reintentarlo no puede duplicar nada.

## 5. Resolución de conflictos

Cuatro clases de dato, cuatro reglas. La mayoría de los conflictos no se
resuelven: **se hacen imposibles**.

| Clase | Ejemplos | Regla |
| --- | --- | --- |
| Acumulativos | `totalXp`, `totalCoins`, `gamesWon`, `totalMoves` | Se sincroniza el **delta**, nunca el total, con `FieldValue.increment`. Conmutativo. |
| Derivados | `level`, progreso de la barra | **No se sincronizan.** Se recalculan desde `totalXp`. |
| Valor único | `displayName`, `avatarSeed` | Last-write-wins por `version`. |
| Colecciones | `matches`, `level_progress` | Id único. Las partidas son inmutables; en niveles gana el `bestScore` mayor. |

**El ejemplo canónico:** dispositivo A gana 450 XP sin conexión, dispositivo B
gana 620. Con totales, uno pisa al otro y se pierden 450 o 620. Con deltas, el
servidor queda en **+1.070**. Nadie sobrescribe a nadie porque nadie envía un
total.

### La racha

Ni acumulativa ni LWW. Se guarda `lastPlayedDate` como `'YYYY-MM-DD'` en zona
**local** —texto, no timestamp— para que funcione sin servidor y sobreviva a
un cambio de huso horario.

El cálculo de días **no resta dos `DateTime` locales**: construye un número de
día en UTC a partir de los componentes locales. Restar fechas locales daría 23
o 25 horas en los cambios de horario de verano, y la racha se rompería dos
veces al año sin que el jugador fallara un día.

Al fusionar: `longestStreak = max(local, nube)`, y `currentStreak` se toma del
lado con `lastPlayedDate` más reciente.

## 6. Vinculación local → nube

```
PERFIL LOCAL  ──►  crear cuenta  ──►  ¿existe users/{uid}?
                                            │
                          ┌─────────────────┴─────────────────┐
                          ▼                                   ▼
                  NO → ADOPCIÓN                        SÍ → FUSIÓN
             se sube el local tal cual              decide el jugador
```

**Adopción** (el caso normal): se vincula y se encola el estado completo. Los
totales viajan como deltas equivalentes al acumulado, lo cual es correcto
precisamente porque el documento remoto está a cero.

**Fusión**: se muestra un diálogo con los dos progresos, en términos que el
jugador reconoce (nivel y monedas). Adivinar por él es exactamente cómo se
pierde el progreso de alguien.

**Nada local se borra jamás** durante la adopción. No hace falta rollback: una
migración interrumpida a la mitad simplemente se reanuda, porque las
operaciones que faltan siguen en la cola y son idempotentes.

## 7. Qué vive dónde

| Dato | Local | Nube |
| --- | :---: | :---: |
| Perfil y acumulados | ✅ | ✅ |
| Historial de partidas | ✅ | ✅ |
| Progreso de niveles | ✅ | ✅ |
| Definición de niveles | ✅ | ❌ generada en código |
| Vidas | ✅ | ❌ |
| Cola de operaciones | ✅ | ❌ |
| Registro de idempotencia | ❌ | ✅ |
| Perfil público (`user_index`) | ❌ | ✅ |
| Retos diarios | caché | ✅ origen |
| Rankings | ❌ | ✅ |

Regla de reparto: **lo determinista se genera, lo acumulado se sincroniza con
incrementos, lo derivado se recalcula, y lo social vive solo en la nube.**

## 8. Seguridad

Ver `firestore.rules`. Lo que las reglas **sí** hacen hoy:

- El perfil privado deja de ser público. `email` y `phoneNumber` ya no se
  exponen; lo público vive en `user_index/{uid}` con cuatro campos.
- Lista blanca de campos: una clave desconocida rechaza la escritura entera.
- Monotonía en `totalXp`, `gamesWon`, `totalMoves`, `longestStreak`.
- Topes por escritura, con excepción para la adopción inicial.
- Partidas y registros de idempotencia inmutables.

Lo que las reglas **no pueden** hacer: validar que la partida que justifica
una recompensa existió. Solo ven la escritura.

### Fase 2 — Cloud Functions

El camino ya está abierto y no requiere tocar el cliente:

1. El cliente escribe **solo** en `users/{uid}/sync_ops/{opId}` — la partida
   jugada, no el premio.
2. Una Function `onCreate` valida la coherencia (marcador alcanzable con esos
   movimientos, tiempo creíble, ritmo razonable) y es la única que escribe
   `totalXp` y `totalCoins`.
3. `users/{uid}` pasa a `write: if false` para el cliente.

El registro de operaciones existe desde la fase 1 precisamente para esto,
aunque hoy solo sirva para idempotencia.

## 9. Qué se prueba, y cómo

Los tests **no dependen de Firebase**. Dos decisiones lo permiten:

- Drift corre sobre `NativeDatabase.memory()`.
- El motor habla con `SyncGateway`, no con Firestore; los tests usan una
  implementación falsa que puede fallar a voluntad.

```bash
fvm flutter test
```

## 10. Estado actual

| Fase | Estado |
| --- | --- |
| Base local, identidad, XP/nivel derivado | ✅ |
| Arranque sin bloqueo, jugar sin cuenta | ✅ |
| Wallet, partidas, racha, niveles, vidas | ✅ |
| Cola, motor, idempotencia, reintentos | ✅ |
| Estado de guardado en la UI | ✅ |
| Vinculación local → nube | ✅ |
| Reglas de seguridad | ✅ |
| Cloud Functions | ⏳ fase 2 |
| Multijugador, amigos, rankings | ⏳ |
| Reto diario con backend | ⏳ |
