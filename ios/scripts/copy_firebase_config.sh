#!/bin/bash
# Copies the right GoogleService-Info.plist into the app bundle based on
# the Xcode CONFIGURATION. Place the two plists in ios/Runner/Firebase/:
#
#   Firebase/GoogleService-Info-Dev.plist    → debug & profile
#   Firebase/GoogleService-Info-Prod.plist   → release
#
# Add this as a "Run Script" build phase in Xcode **before**
# "Copy Bundle Resources", with:
#
#   ${PROJECT_DIR}/scripts/copy_firebase_config.sh

set -euo pipefail

FIREBASE_DIR="${PROJECT_DIR}/Runner/Firebase"
DEST="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"

case "${CONFIGURATION}" in
  Release)
    SRC="${FIREBASE_DIR}/GoogleService-Info-Prod.plist"
    ;;
  *)
    SRC="${FIREBASE_DIR}/GoogleService-Info-Dev.plist"
    ;;
esac

if [ ! -f "${SRC}" ]; then
  echo "warning: ${SRC} not found — Firebase will not work on iOS."
  echo "Register the iOS apps in Firebase Console and place the plists."
  exit 0
fi

cp "${SRC}" "${DEST}"
echo "Copied ${SRC} → ${DEST}"
