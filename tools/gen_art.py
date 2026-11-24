"""Erzeugt die gesamte Grafik des Spiels aus der festen Palette.

Aufruf: python3 tools/gen_art.py
Erzeugt die eigenen Kacheln, Innenraum-Hintergründe und Deko. Figuren, Gegner, Gebäude, Lampen und
Oberfläche kommen aus dem Grafik-Repo (tools/import_cosy.py).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "art"))

import backgrounds  # noqa: E402
import deco  # noqa: E402
import tiles  # noqa: E402

if __name__ == "__main__":
    tiles.make_all()
    backgrounds.make_all()
    deco.make_all()
    print("Grafik erzeugt.")
