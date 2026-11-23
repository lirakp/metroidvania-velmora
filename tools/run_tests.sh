#!/usr/bin/env bash
# Führt alle Tests headless aus. Optional: Filter auf Dateinamen (z. B. combat_core).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/tools/bin/godot" --headless --path "$ROOT/game" --import >/dev/null 2>&1
"$ROOT/tools/bin/godot" --headless --path "$ROOT/game" res://tests/test_runner.tscn -- "${1:-}"
