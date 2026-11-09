#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
dispositivo="${1:-emulator-5554}"
if [[ ! "$dispositivo" =~ ^emulator-[0-9]+$ ]]; then
  echo 'Indica el identificador del emulador, por ejemplo emulator-5554.'
  exit 1
fi
proyecto=$(node -p 'JSON.parse(require("node:fs").readFileSync(".firebaserc")).projects.default')
temporal=$(mktemp -d)
trap 'rm -rf -- "$temporal"' EXIT
cp firestore.rules "$temporal/"
cat > "$temporal/firebase.json" <<'CONFIG'
{
  "firestore": {"rules": "firestore.rules"},
  "emulators": {
    "auth": {"host": "127.0.0.1", "port": 9099},
    "firestore": {"host": "127.0.0.1", "port": 8080},
    "ui": {"enabled": false}
  }
}
CONFIG

comando="flutter test integration_test/entrega_test.dart -d $dispositivo --dart-define=PRUEBA_LOCAL=true"
if [[ -n "${INDRIVE_CAPTURAS_DIR:-}" ]]; then
  comando="flutter drive --driver=test_driver/capturas.dart --target=integration_test/entrega_test.dart -d $dispositivo --dart-define=PRUEBA_LOCAL=true --dart-define=CAPTURAS=true"
fi

# El mismo ID hace que Auth y Firestore coincidan; todo el tráfico de la prueba va a localhost.
npx -y firebase-tools@15.35.0 emulators:exec --only auth,firestore \
  --project "$proyecto" --config "$temporal/firebase.json" "$comando"
