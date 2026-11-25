#!/usr/bin/env bash
# Baut das Windows-Spiel nach build/Blutmond-windows.zip (Blutmond.exe + Blutmond.pck).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -x "$ROOT/tools/bin/godot" ] || bash "$ROOT/tools/setup_godot.sh"
rm -rf "$ROOT/build" && mkdir -p "$ROOT/build/Blutmond"
"$ROOT/tools/bin/godot" --headless --path "$ROOT/game" --import >/dev/null 2>&1
"$ROOT/tools/bin/godot" --headless --path "$ROOT/game" --export-release "Windows Desktop" "$ROOT/build/Blutmond/Blutmond.exe"
cp "$ROOT/README.md" "$ROOT/build/Blutmond/LIESMICH.md"
(cd "$ROOT/build" && zip -qr Blutmond-windows.zip Blutmond)
echo "Fertig: build/Blutmond-windows.zip"
