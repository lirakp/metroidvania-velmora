"""Erzeugt die gesamte Grafik des Spiels aus der festen Palette.

Aufruf: python3 tools/gen_art.py
Figuren/Häuser stehen als Pixel-Textraster in tools/art/rasters/, alles andere wird per Skript gezeichnet.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "art"))

import backgrounds  # noqa: E402
import chars  # noqa: E402
import legacy  # noqa: E402
import tiles  # noqa: E402

if __name__ == "__main__":
    legacy.make_all()
    tiles.make_all()
    backgrounds.make_all()
    chars.make_all()
    print("Grafik erzeugt.")
