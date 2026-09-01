#!/usr/bin/env bash
#
# Agrupa el trabajo offline-first en commits temáticos.
#
# NOTA HONESTA: el historial resultante es legible, pero NO es bisecable.
# Todo el trabajo llegó al árbol a la vez, así que un commit intermedio puede
# referenciar código que aparece en uno posterior. Para leer qué cambió y por
# qué, sirve. Para hacer `git bisect`, no.
#
# Uso:  bash scripts/commit-offline-first.sh
set -u

commit_group() {
  local message="$1"; shift
  local added=0

  for path in "$@"; do
    if git add -- "$path" 2>/dev/null; then added=1; fi
  done

  if [ "$added" -eq 1 ] && ! git diff --cached --quiet; then
    git commit -q -m "$message"
    echo "✔  $message"
  else
    echo "·  (sin cambios) $message"
  fi
}

echo "Rama: $(git rev-parse --abbrev-ref HEAD)"
echo

commit_group "feat(db): base local Drift con el esquema offline-first

Drift (SQLite) pasa a ser la fuente de verdad del gameplay. Ocho tablas:
perfil, partidas, progreso de niveles, retos, vidas y la cola de
sincronización. Claves foráneas activadas y conexión con importación
condicional para que 'build web' siga compilando." \
  pubspec.yaml pubspec.lock analysis_options.yaml \
  lib/core/database test/core/database

commit_group "test(theme): guarda de contraste WCAG AA del design system

Sustituye al test de contador autogenerado, que probaba un widget que nunca
existió. Verifica con la fórmula WCAG 2.1 los pares de color documentados, e
incluye la comprobación de que el blanco sobre amarillo, verde o cian NO
alcanza 4.5:1 — que es la razón de usar tintes oscuros del propio tono." \
  test/core/theme test/widget_test.dart

commit_group "feat(sync): cola de operaciones, motor, idempotencia y reintentos

La cola guarda deltas, nunca totales. El opId es también el id del documento
en users/{uid}/sync_ops/{opId}, escrito en la misma transacción que el efecto:
reintentar una operación cuya respuesta se perdió no aplica nada dos veces.

El motor habla con una interfaz SyncGateway, no con Firestore, lo que permite
probar backoff, orden y rescate de operaciones colgadas sin red — y cambiar a
Cloud Functions en fase 2 sin tocar el motor. Un fallo transitorio detiene la
pasada: insistir con el resto solo gasta batería y las condena a todas." \
  lib/core/sync test/core/sync

commit_group "feat(player): identidad local, XP monótono y racha diaria

El localId es un UUID generado en el primer arranque y no cambia nunca; crear
cuenta rellena cloudUid sobre esa misma fila.

AppUser deja de guardar level y currentXp: guarda totalXp acumulado y el nivel
se deriva. Arregla que el nivel nunca subiera, y elimina una clase entera de
conflictos. Los documentos heredados migran al leerse.

La racha pasa de ser un campo que nadie escribía a funcionar: el cálculo de
días usa UTC sobre componentes locales para no romperse en los cambios de
horario de verano." \
  lib/features/player test/features/player \
  lib/features/auth/model lib/features/auth/repository \
  lib/features/auth/controller/user_controller.dart test/features/auth

commit_group "feat(startup): arranque sin bloqueo y Home desde la base local

main deja de esperar a Firebase; solo espera a la localización. El splash gana
la tercera vía: siempre va a la Home, incluso si el arranque falla. Los
repositorios resuelven FirebaseFirestore.instance de forma perezosa, porque
construir uno no debe exigir que Firebase esté inicializado.

Con esto la app es jugable sin cuenta por primera vez." \
  lib/main.dart lib/core/firebase lib/features/auth/splash \
  lib/features/auth/controller/auth_controller.dart \
  lib/features/home/controller lib/features/home/model/home_summary.dart \
  test/features/home

commit_group "fix(wallet): el saldo persiste de verdad

spend() y add() mutaban solo estado de Riverpod, que se revertía al primer
snapshot: comprar en la tienda no descontaba nada, nunca. Ahora el saldo se
deriva del perfil local y las operaciones escriben en SQLite. La comprobación
de saldo y el descuento van en la misma transacción." \
  lib/features/wallet test/features/wallet

commit_group "fix(game): una sola fórmula de recompensa y partidas locales

Había tres cálculos distintos para el mismo evento: el jugador veía un número,
cobraba otro y conservaba un tercero — y perder por tiempo abonaba 50 monedas.
Ahora existe una única calculateMatchRewards y un tipo MatchRewards.

El matchId se genera al EMPEZAR la partida, no al guardarla, lo que hace
idempotente el registro. La partida y sus recompensas se escriben en una sola
transacción." \
  lib/features/game lib/features/home/model/recent_match.dart \
  test/features/game

commit_group "fix(levels): definiciones locales y progreso persistido

Se retiran las 50 escrituras en Firestore por usuario nuevo: la definición del
nivel es determinista y se genera en código. El desbloqueo tampoco se guarda —
un nivel está abierto si el anterior está completado. bestScore se resuelve
con máximo, no con 'gana el último'.

LevelMapController deja de devolver cuatro nodos escritos a mano." \
  lib/features/level_map test/features/level_map

commit_group "fix(lives): vidas persistentes con recarga por reloj

Vivían solo en memoria: cerrar la app devolvía las cinco y el temporizador de
recarga solo corría con la app abierta. Ahora se guardan las vidas y el
instante de la última recarga, y al arrancar se deduce del reloj cuántas se
recuperaron — conservando el tiempo ya cumplido del intervalo en curso." \
  lib/features/lives test/features/lives

commit_group "feat(account): estado de guardado y vinculación local → nube

La tarjeta 'Guarda tu progreso' no aparece al instalar: espera a que el
jugador tenga algo que perder. Cuando la cuenta ya trae progreso propio, el
jugador elige con cuál se queda — adivinar por él es como se pierde el
progreso de alguien.

Los opId de la migración son deterministas: con UUIDs aleatorios, reencolar
tras un reinicio habría aplicado el XP y las monedas acumuladas dos veces.

El indicador de guardado usa lenguaje humano y ningún estado dice 'error'." \
  lib/features/account lib/features/home/widget lib/features/home/home_screen.dart \
  lib/core/localization test/features/account

commit_group "fix(security): cierra la fuga de datos y valida las escrituras

users/{uid} tenía 'allow read: if true', lo que exponía email y teléfono de
todos los jugadores sin autenticar. Lo público pasa a user_index/{uid} con
cuatro campos.

Se añade lista blanca de campos, monotonía en los acumulados, topes por
escritura, y partidas y registros de idempotencia inmutables.

Documenta el límite conocido: ninguna regla puede validar que la partida que
justifica una recompensa existió. Eso son Cloud Functions, fase 2." \
  firestore.rules docs

# Red de seguridad: cualquier cosa que se haya quedado fuera del reparto.
if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -q -m "chore: archivos restantes del trabajo offline-first"
  echo "✔  chore: archivos restantes"
fi

echo
echo "Historial resultante:"
git log --oneline -12
