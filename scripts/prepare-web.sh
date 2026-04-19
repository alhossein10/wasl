#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(dirname "$SCRIPT_DIR")
cd "$REPO_ROOT"

for cmd in git cargo flutter_rust_bridge_codegen flutter dart awk readlink; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

version=$(awk '
  $1 == "flutter_vodozemac:" { in_pkg = 1; next }
  in_pkg && $1 == "version:" {
    gsub(/"/, "", $2)
    print $2
    exit
  }
' pubspec.lock)

if [ -z "$version" ]; then
  echo "Unable to detect flutter_vodozemac version from pubspec.lock" >&2
  exit 1
fi

rm -rf .vodozemac
git clone https://github.com/famedly/dart-vodozemac.git -b "$version" .vodozemac
cd .vodozemac
flutter_rust_bridge_codegen build-web --dart-root dart --rust-root "$(readlink -f rust)" --release
cd "$REPO_ROOT"

rm -f ./assets/vodozemac/vodozemac_bindings_dart*
mv .vodozemac/dart/web/pkg/vodozemac_bindings_dart* ./assets/vodozemac/
rm -rf .vodozemac

flutter pub get
dart compile js ./web/native_executor.dart -o ./web/native_executor.js -m
