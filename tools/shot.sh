#!/usr/bin/env bash
# Rendert eine Szene unter virtuellem Bildschirm und speichert das letzte Bild.
# Aufruf: tools/shot.sh res://battle/battle_scene.tscn out.png [frames]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d)
xvfb-run -a -s "-screen 0 1920x1080x24" "$ROOT/tools/bin/godot" --path "$ROOT/game" --rendering-driver opengl3 \
  --write-movie "$TMP/f.png" --fixed-fps 30 --quit-after "${3:-60}" "$1" -- ${4:-} >/dev/null 2>&1 || true
LAST=$(ls "$TMP"/f*.png | tail -1)
cp "$LAST" "$2"
rm -rf "$TMP"
