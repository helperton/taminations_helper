#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$ROOT_DIR/build/macos/Build/Products/Debug/taminations_flutter.app"

if [[ -d "$APP_PATH" ]]; then
  echo "Launching $APP_PATH"
  open "$APP_PATH"
else
  echo "No debug build found at $APP_PATH — running via flutter..."
  cd "$ROOT_DIR"
  flutter run -d macos
fi
