#!/usr/bin/env bash
#
# Build de release con un número de build que sube solo.
#
# El nombre de la versión (1.0.1) sale de `pubspec.yaml` y se cambia a mano
# cuando toca. El número de build (versionCode en Android, CFBundleVersion en
# iOS) es el número de commits de la rama: cada merge a `main` lo sube, así
# que dos builds de commits distintos nunca comparten número y las tiendas
# siempre reciben uno mayor que el anterior.
#
# Uso:
#   bash scripts/build_release.sh                  # appbundle
#   bash scripts/build_release.sh apk
#   bash scripts/build_release.sh ipa --export-method app-store
#
# Variables:
#   BUILD_NUMBER  fuerza el número de build (por ejemplo, en CI).
#   FLUTTER       comando de Flutter; por defecto `fvm flutter` si hay FVM.
set -euo pipefail

cd "$(dirname "$0")/.."

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Hace falta el historial de git para calcular el número de build." >&2
  exit 1
fi
if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
  echo "El clon es superficial: el número de build saldría bajo." >&2
  echo "Ejecuta 'git fetch --unshallow' o define BUILD_NUMBER." >&2
  [ -n "${BUILD_NUMBER:-}" ] || exit 1
fi

build_number="${BUILD_NUMBER:-$(git rev-list --count HEAD)}"
version_name="$(sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml)"

if [ -z "${FLUTTER:-}" ]; then
  if command -v fvm >/dev/null 2>&1; then FLUTTER="fvm flutter"; else FLUTTER="flutter"; fi
fi

target="${1:-appbundle}"
[ $# -gt 0 ] && shift

echo "Build de release $version_name+$build_number ($target)"
$FLUTTER build "$target" --release --build-number="$build_number" "$@"
