#!/usr/bin/env bash
# Führt alle Tests headless aus. Optional: Filter auf Dateinamen (z. B. combat_core).
# Schlägt auch fehl, wenn während der Tests ein GDScript-Fehler auftritt.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT=$(mktemp)
"$ROOT/tools/bin/godot" --headless --path "$ROOT/game" --import >/dev/null 2>&1
"$ROOT/tools/bin/godot" --headless --path "$ROOT/game" res://tests/test_runner.tscn -- "${1:-}" >"$OUT" 2>&1
CODE=$?
grep -v -e "resources still in use" -e "resource.cpp" -e "object.cpp" -e "ObjectDB instances leaked" "$OUT"
if grep -q -e "SCRIPT ERROR" -e "Parse Error" "$OUT"; then
  echo "FEHLER: GDScript-Fehler während der Tests (siehe oben)"
  CODE=1
fi
rm -f "$OUT"
exit $CODE
