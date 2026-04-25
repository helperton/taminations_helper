#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_PATH="$ROOT_DIR/build/macos/Build/Products/Debug/taminations_flutter.app"
EXECUTABLE_PATH="$APP_PATH/Contents/MacOS/taminations_flutter"
DEBUG_DYLIB_PATH="$APP_PATH/Contents/MacOS/taminations_flutter.debug.dylib"
KERNEL_BLOB_PATH="$APP_PATH/Contents/Frameworks/App.framework/Resources/flutter_assets/kernel_blob.bin"
DEBUG_URL="http://localhost:7234/debug"

DART_API_SOURCE="$ROOT_DIR/lib/api_server.dart"
DART_MAIN_SOURCE="$ROOT_DIR/lib/main.dart"
NATIVE_WINDOW_SOURCE="$ROOT_DIR/macos/Runner/MainFlutterWindow.swift"
NATIVE_APP_SOURCE="$ROOT_DIR/macos/Runner/AppDelegate.swift"

function fail() {
  echo "ERROR: $*" >&2
  exit 1
}

function require_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "Missing file: $path"
}

function file_mtime() {
  stat -f "%m" "$1"
}

function assert_not_older_than_source() {
  local artifact="$1"
  local source="$2"
  local artifact_label="$3"
  local artifact_mtime source_mtime
  artifact_mtime="$(file_mtime "$artifact")"
  source_mtime="$(file_mtime "$source")"
  if (( artifact_mtime < source_mtime )); then
    fail "$artifact_label is older than source $source"
  fi
}

function wait_for_debug_endpoint() {
  local attempts=50
  local sleep_seconds=0.2
  local response=""
  for ((i=1; i<=attempts; i++)); do
    response="$(curl -fsS "$DEBUG_URL" 2>/dev/null || true)"
    if [[ -n "$response" ]]; then
      echo "$response"
      return 0
    fi
    sleep "$sleep_seconds"
  done
  return 1
}

function read_debug_marker() {
  sed -nE "s/.*static const debugBuildMarker = '([^']+)'.*/\1/p" "$DART_API_SOURCE" | head -n 1
}

DEBUG_MARKER="$(read_debug_marker)"
[[ -n "$DEBUG_MARKER" ]] || fail "Could not read debugBuildMarker from $DART_API_SOURCE"

echo "Building Debug macOS app..."
flutter build macos --debug "$@"

require_file "$EXECUTABLE_PATH"
require_file "$DEBUG_DYLIB_PATH"
require_file "$KERNEL_BLOB_PATH"

assert_not_older_than_source "$KERNEL_BLOB_PATH" "$DART_API_SOURCE" "Kernel blob"
assert_not_older_than_source "$KERNEL_BLOB_PATH" "$DART_MAIN_SOURCE" "Kernel blob"
assert_not_older_than_source "$DEBUG_DYLIB_PATH" "$NATIVE_WINDOW_SOURCE" "Debug dylib"
assert_not_older_than_source "$DEBUG_DYLIB_PATH" "$NATIVE_APP_SOURCE" "Debug dylib"

if lsof -n -P -iTCP:7234 -sTCP:LISTEN >/dev/null 2>&1; then
  fail "Port 7234 is already in use. Quit any running TamHelper before verification."
fi

"$EXECUTABLE_PATH" >/tmp/taminations_helper_verify.log 2>&1 &
APP_PID=$!
trap 'kill "$APP_PID" >/dev/null 2>&1 || true' EXIT

DEBUG_RESPONSE="$(wait_for_debug_endpoint)" || fail "Timed out waiting for TamHelper /debug endpoint"

if ! grep -Fq "\"debugBuildMarker\":\"$DEBUG_MARKER\"" <<<"$DEBUG_RESPONSE" && \
   ! grep -Fq "\"debugBuildMarker\" : \"$DEBUG_MARKER\"" <<<"$DEBUG_RESPONSE"; then
  fail "Live /debug response does not contain debug marker '$DEBUG_MARKER'"
fi

RUNTIME_EXECUTABLE_PATH="$(printf '%s' "$DEBUG_RESPONSE" | sed -nE 's/.*"executablePath"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | head -n 1)"
RUNTIME_EXECUTABLE_MODIFIED_AT="$(printf '%s' "$DEBUG_RESPONSE" | sed -nE 's/.*"executableModifiedAt"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | head -n 1)"
RUNTIME_KERNEL_BLOB_PATH="$(printf '%s' "$DEBUG_RESPONSE" | sed -nE 's/.*"kernelBlobPath"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | head -n 1)"
RUNTIME_KERNEL_BLOB_MODIFIED_AT="$(printf '%s' "$DEBUG_RESPONSE" | sed -nE 's/.*"kernelBlobModifiedAt"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | head -n 1)"

kill "$APP_PID" >/dev/null 2>&1 || true
wait "$APP_PID" 2>/dev/null || true
trap - EXIT

echo
echo "Verified Debug build:"
echo "  app:          $APP_PATH"
echo "  executable:   $EXECUTABLE_PATH"
echo "  debug dylib:  $DEBUG_DYLIB_PATH"
echo "  kernel blob:  $KERNEL_BLOB_PATH"
echo "  debug marker: $DEBUG_MARKER"
echo "  runtime:      /debug responded with current marker"
echo "  runtimeBuildInfo.executablePath: $RUNTIME_EXECUTABLE_PATH"
echo "  runtimeBuildInfo.executableModifiedAt: $RUNTIME_EXECUTABLE_MODIFIED_AT"
echo "  runtimeBuildInfo.kernelBlobPath: $RUNTIME_KERNEL_BLOB_PATH"
echo "  runtimeBuildInfo.kernelBlobModifiedAt: $RUNTIME_KERNEL_BLOB_MODIFIED_AT"
