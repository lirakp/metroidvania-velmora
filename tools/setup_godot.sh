#!/usr/bin/env bash
# Lädt Godot 4.3 (Linux-Editor) und die Exportvorlagen nach tools/bin/. Idempotent.
set -euo pipefail
cd "$(dirname "$0")"
VER=4.3
BASE=https://github.com/godotengine/godot/releases/download/${VER}-stable
mkdir -p bin
if [ ! -x bin/Godot_v${VER}-stable_linux.x86_64 ]; then
  curl -fsSL -o bin/godot.zip "$BASE/Godot_v${VER}-stable_linux.x86_64.zip"
  (cd bin && unzip -oq godot.zip && rm godot.zip)
fi
ln -sf Godot_v${VER}-stable_linux.x86_64 bin/godot
TPL="$HOME/.local/share/godot/export_templates/${VER}.stable"
if [ "${SKIP_TEMPLATES:-0}" != "1" ] && [ ! -f "$TPL/windows_release_x86_64.exe" ]; then
  curl -fsSL -o bin/templates.tpz "$BASE/Godot_v${VER}-stable_export_templates.tpz"
  mkdir -p "$TPL"
  (cd bin && rm -rf templates && unzip -oq templates.tpz && cp templates/* "$TPL/" && rm -rf templates templates.tpz)
fi
echo "Godot bereit: $(./bin/godot --version 2>/dev/null | tail -1)"
