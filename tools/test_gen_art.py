"""Tests für die erzeugte Platzhalter-Grafik. Aufruf: python3 tools/test_gen_art.py"""
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "game" / "art"


def palette():
    cols = json.loads((ART / "palette.json").read_text())["colors"]
    return {tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)) for c in cols}


def test_palette_has_32_colors():
    assert len(palette()) == 32


def test_atlas_size():
    im = Image.open(ART / "tiles.png")
    assert im.size == (16 * 13, 16), im.size


def test_expected_files():
    for rel in ["chars/warschick.png", "chars/lira.png", "ui/plakette.png",
                "bg/kornfeld.png", "bg/stadt.png", "bg/dungeon_blut.png",
                "enemies/goblin.png", "enemies/gruenschleim.png", "enemies/skelettkrieger.png",
                "enemies/riesenspinne.png", "enemies/ghul.png", "enemies/skelett_bogner.png",
                "enemies/blutwolf_alpha.png"]:
        assert (ART / rel).exists(), rel


def test_sprite_sizes():
    assert Image.open(ART / "chars/lira.png").size == (16 * 4, 32 * 4)
    assert Image.open(ART / "enemies/goblin.png").size == (32 * 2, 32 * 2)
    assert Image.open(ART / "enemies/blutwolf_alpha.png").size == (64 * 2, 64 * 2)
    assert Image.open(ART / "bg/kornfeld.png").size == (480, 270)


def test_all_pixels_in_palette():
    pal = palette()
    for p in ART.rglob("*.png"):
        im = Image.open(p).convert("RGBA")
        for _, (r, g, b, a) in im.getcolors(1 << 20):
            if a == 0:
                continue
            assert a == 255 and (r, g, b) in pal, f"{p.name}: {(r, g, b, a)}"


if __name__ == "__main__":
    failed = 0
    for name, fn in list(globals().items()):
        if name.startswith("test_"):
            try:
                fn()
                print("PASS", name)
            except Exception as e:  # noqa: BLE001
                failed += 1
                print("FAIL", name, e)
    sys.exit(1 if failed else 0)
