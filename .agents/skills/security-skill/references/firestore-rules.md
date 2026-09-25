# 🔒 Firestore Rules — Análisis Profundo

> Documento de referencia para el skill `security-skill`.
> Detalla cada regla, su propósito, y posibles mejoras.

---

## Estructura actual

```
users/{uid}          — Perfil privado (solo dueño)
  ├── /matches/{matchId}  — Historial (inmutable)
  ├── /level_progress/{levelNumber} — Progreso (solo actualizable)
  ├── /sync_ops/{opId}    — Registro de idempotencia (inmutable)
  └── /achievements/{achievementId} — Logros (propietario)

user_index/{uid}     — Perfil público (campos limitados)

friendships/{pairId} — Relaciones (dos miembros, estado)

duels/{duelId}       — Duelos (miembros, resultados)

daily_challenges/{challengeId} — Retos (solo lectura)

leaderboards/{leaderboardId}   — Rankings (solo lectura)
```

## Funciones auxiliares

| Función | Propósito | Límite conocido |
|---|---|---|
| `signedIn()` | Verifica autenticación | Ninguno |
| `isOwner(uid)` | `request.auth.uid == uid` | Cliente falsifica uid si tiene token válido |
| `incoming()` | Atajo para `request.resource.data` | Ninguno |
| `current()` | Atajo para `resource.data` | Ninguno |
| `profileFields()` | Lista blanca de campos | No incluye `achievements` |
| `monotonic(field)` | Campo no puede bajar | Solo compara, no valida coherencia |
| `unchanged(field)` | Campo no puede cambiar | Ninguno |
| `deltaWithin(field, cap)` | Delta máximo por escritura | Excepción de valor cero para adopción |

## Regla por regla — Riesgo y mejora

### `users/{uid}`

| Operación | Regla actual | Riesgo | Mejora |
|---|---|---|---|
| `read` | `isOwner(uid)` | ✅ Robusto | Ninguno |
| `create` | `isOwner(uid) && hasOnly(profileFields())` | ✅ Robusto | Añadir `request.time < timestamp(2050, 1, 1)` |
| `update` | Lista blanca + monotonic + deltaWithin | ⚠️ `createdAt`/`email` no cambian, pero no hay `request.time` validation | Añadir `request.time > current().updatedAt` para evitar replay |
| `delete` | `if false` | ✅ Robusto | Ninguno |

### `users/{uid}/matches/{matchId}`

| Operación | Regla actual | Riesgo | Mejora |
|---|---|---|---|
| `read` | `isOwner(uid)` | ✅ Robusto | Ninguno |
| `create` | `isOwner(uid)` | ⚠️ Cualquier partida se puede crear | Cloud Functions validación |
| `update` | `if false` | ✅ Robusto | Ninguno |
| `delete` | `if false` | ✅ Robusto | Ninguno |

### `users/{uid}/sync_ops/{opId}`

| Operación | Regla actual | Riesgo | Mejora |
|---|---|---|---|
| `read` | `isOwner(uid)` | ✅ Robusto | Ninguno |
| `create` | `isOwner(uid)` | ⚠️ Sin rate limiting | Añadir `request.time` gap check |
| `update` | `if false` | ✅ Robusto | Ninguno |
| `delete` | `if false` | ✅ Robusto | Ninguno |

### `user_index/{uid}`

| Operación | Regla actual | Riesgo | Mejora |
|---|---|---|---|
| `read` | `signedIn()` | ⚠️ Cualquier usuario autenticado puede leer cualquier perfil público | ✅ Intencional para amigos/rankings |
| `write` | `isOwner(uid) && hasOnly([...])` | ⚠️ `friendCode` derivado del uid — no verificable por reglas | Documentado como limitación; el daño es limitado |

### `friendships/{pairId}`

| Operación | Regla actual | Riesgo | Mejora |
|---|---|---|---|
| `read` | `signedIn && resource==null || member` | ✅ Robusto | Ninguno |
| `create` | Miembros ordenados, `requestedBy == auth.uid`, `status == pending` | ✅ Robusto | Añadir `request.time` freshness |
| `update` | Solo aceptar (`status == 'accepted'`), solo quien recibió | ✅ Robusto | Ninguno |
| `delete` | `isMember()` | ✅ Robusto | Ninguno |

### `duels/{duelId}`

| Operación | Regla actual | Riesgo | Mejora | Mejora |
|---|---|---|---|
| `read` | `isMember()` | ✅ Robusto | Ninguno |
| `create` | Amistad aceptada verificada con `get()`, miembros correctos | ⚠️ Sin `request.time` check | Añadir freshness check |
| `update` | Cada jugador añade resultado una sola vez; rival puede rechazar | ✅ Robusto | Ninguno |
| `delete` | `if false` | ✅ Robusto | Ninguno |

## Reglas que necesitan Cloud Functions

Estas validaciones son imposibles con las reglas actuales:

1. **Coherencia de partida**: El marcador reportado es alcanzable con los movimientos
2. **Tiempo creíble**: La partida no duró 2 segundos para 20 parejas
3. **Razonabilidad del progreso**: `totalXp` incremento consistente con el nivel jugado
4. **Duplicación de partidas**: Una misma semilla+jugador no puede generar múltiples partidas

---

## Checklist de seguridad para nuevas colecciones

Cuando se añada una nueva colección a Firestore, validar:

- [ ] ¿Hay una regla `read` que restrinja al propietario?
- [ ] ¿Los campos escritos están en una lista blanca?
- [ ] ¿Los acumulados son monotonic?
- [ ] ¿Los documentos críticos son inmutables después de crear?
- [ ] ¿Hay `request.time` validation para prevenir replay?
- [ ] ¿La operación es idempotente?
- [ ] ¿Los datos derivados se recalculan, no se almacenan?
- [ ] ¿La colección tiene un `write: if false` si es de solo lectura?
