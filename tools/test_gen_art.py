"""Tests für die erzeugte Grafik. Aufruf: python3 tools/test_gen_art.py"""
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "game" / "art"


def _rgb(c):
    return tuple(int(c[i:i + 2], 16) for i in (1, 3, 5))


def palettes():
    d = json.loads((ART / "palette.json").read_text())
    return {_rgb(c) for c in d["colors"]}, {_rgb(c) for c in d["warm"]}


def colors_of(p):
    im = Image.open(p).convert("RGBA")
    return {(r, g, b) for _, (r, g, b, a) in im.getcolors(1 << 22) if a}


def test_palette_sizes():
    base, warm = palettes()
    assert len(base) == 32 and len(warm) == 6 and not (base & warm)


def test_atlas_size():
    assert Image.open(ART / "tiles.png").size == (16 * 13, 16)


def test_expected_files():
    need = ["chars/warschick.png", "chars/lira.png", "chars/kartograf.png", "chars/gildenmeisterin.png",
            "ui/plakette.png"]
    need += [f"enemies/{e}.png" for e in ("goblin", "gruenschleim", "skelettkrieger", "riesenspinne", "ghul",
                                           "skelett_bogner", "blutwolf_alpha")]
    for rel in need:
        assert (ART / rel).exists(), rel


def test_sprite_sizes():
    for n in ("warschick", "lira", "kartograf", "gildenmeisterin"):
        assert Image.open(ART / f"chars/{n}.png").size == (24 * 4, 40 * 4), n
    assert Image.open(ART / "enemies/goblin.png").size == (32 * 2, 32 * 2)
    assert Image.open(ART / "enemies/blutwolf_alpha.png").size == (64 * 2, 64 * 2)


def test_figures_smaller_than_door():
    """Figuren (ohne Transparenz) sind niedriger als die Tür des Gildenhauses (46 px)."""
    im = Image.open(ART / "chars/warschick.png").crop((0, 0, 24, 40))
    box = im.getbbox()
    assert box[3] - box[1] < 46


def test_all_pixels_in_palette():
    base, warm = palettes()
    for p in ART.rglob("*.png"):
        extra = colors_of(p) - base - warm
        assert not extra, f"{p.relative_to(ART)}: {sorted(extra)[:3]}"


def test_warm_colors_only_in_safe_art():
    base, warm = palettes()
    forbidden = list((ART / "enemies").glob("*.png")) + [ART / "tiles.png"] + list(ART.glob("bg/dungeon_*/*.png"))
    for p in forbidden:
        assert not (colors_of(p) & warm), f"warme Farbe in {p.relative_to(ART)}"


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
