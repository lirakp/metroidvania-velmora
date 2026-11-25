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
    assert Image.open(ART / "tiles.png").size == (16 * 15, 16)


BIOMES = ("innen_gilde", "innen_haus", "innen_kammer", "innen_muehle")


def test_background_layers():
    for b in BIOMES:
        for i in range(3):
            p = ART / f"bg/{b}/layer_{i}.png"
            assert p.exists(), p
            assert Image.open(p).size == (480, 270), p
        assert Image.open(ART / f"bg/{b}/layer_0.png").convert("RGBA").getextrema()[3][0] == 255, f"{b}: Ebene 0 deckend"


def test_safe_backgrounds_have_warm_light():
    _, warm = palettes()
    for b in ("innen_gilde", "innen_haus", "innen_kammer"):
        cols = set()
        for i in range(3):
            cols |= colors_of(ART / f"bg/{b}/layer_{i}.png")
        assert cols & warm, f"{b} ohne warmes Licht"
    for b in ("innen_muehle",):
        for i in range(3):
            assert not (colors_of(ART / f"bg/{b}/layer_{i}.png") & warm), f"{b} soll kalt bleiben"


def test_expected_files():
    need = ["ui/plakette.png", "tiles.png"]
    for rel in need:
        assert (ART / rel).exists(), rel


def test_all_pixels_in_palette():
    base, warm = palettes()
    for p in ART.rglob("*.png"):
        if "cosy" in p.parts:
            continue
        extra = colors_of(p) - base - warm
        assert not extra, f"{p.relative_to(ART)}: {sorted(extra)[:3]}"


def test_warm_colors_only_in_safe_art():
    base, warm = palettes()
    forbidden = [ART / "tiles.png"] + list(ART.glob("bg/dungeon_*/*.png")) + list(ART.glob("bg/innen_muehle/*.png"))
    for p in forbidden:
        assert not (colors_of(p) & warm), f"warme Farbe in {p.relative_to(ART)}"


DECO_WARM = ("altar", "schrein", "bogen_warm")
DECO_COLD = ("baum", "zaun", "wegweiser", "kristall", "kette", "toter_abenteurer", "bogen", "tuer", "tresen", "kiste")


def test_deco_files_and_warmth():
    _, warm = palettes()
    for n in DECO_WARM:
        assert colors_of(ART / f"deco/{n}.png") & warm, f"{n} ohne warmes Licht"
    for n in DECO_COLD:
        assert not (colors_of(ART / f"deco/{n}.png") & warm), f"{n} soll kalt sein"


def test_light_textures():
    for kind in ("kalt",):
        for r in (16, 24, 32, 48):
            im = Image.open(ART / f"light/{kind}_{r}.png")
            assert im.size == (r * 2, r * 2)


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
