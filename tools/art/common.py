"""Gemeinsame Grundlagen der Grafik: Palette, Zeichenfläche, Raster, Lichtschein."""
import json
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent.parent
ART = ROOT / "game" / "art"
RASTERS = Path(__file__).resolve().parent / "rasters"

_PAL = json.loads((ART / "palette.json").read_text())


def hexc(c):
    return tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


P = [hexc(c) for c in _PAL["colors"]]
WARM = [hexc(c) for c in _PAL["warm"]]
CLEAR = (0, 0, 0, 0)
BLACK, INK, NIGHT, SHADOW = P[0:4]
ST = P[4:11]        # Stein/Grau, dunkel → hell
MOSS = P[11:16]
SLATE = P[16:20]
BROWN = P[20:24]
RED = P[24:29]
GOLD0, GOLD, GOLD2 = P[29:32]
WSHADE, WEMBER, WGLUT, WAMBER, WCANDLE, WLIGHT = WARM

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def bayer(x, y):
    return (BAYER[y % 4][x % 4] + 0.5) / 16


def lum(c):
    return (c[0] * 3 + c[1] * 6 + c[2]) / 10


class Canvas:
    """Zeichenfläche mit Pixel-, Raster- und Lichthelfern."""

    def __init__(self, w, h, fill=CLEAR):
        self.w, self.h = w, h
        self.im = Image.new("RGBA", (w, h), fill)
        self.d = ImageDraw.Draw(self.im)

    def px(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h and c[3]:
            self.im.putpixel((x, y), c)

    def get(self, x, y):
        return self.im.getpixel((x, y))

    def rect(self, x0, y0, x1, y1, c):
        if x1 >= x0 and y1 >= y0:
            self.d.rectangle([x0, y0, x1, y1], fill=c)

    def raster(self, rows, legend, ox=0, oy=0, flip=False):
        for y, row in enumerate(rows):
            n = len(row)
            for x, ch in enumerate(row):
                if ch not in ". ":
                    self.px(ox + (n - 1 - x if flip else x), oy + y, legend[ch])

    def gradient(self, bands, y0, y1, x0=0, x1=None):
        x1 = self.w if x1 is None else x1
        for y in range(y0, y1):
            t = (y - y0) / max(1, (y1 - y0)) * (len(bands) - 1)
            i = min(int(t), len(bands) - 2)
            for x in range(x0, x1):
                self.im.putpixel((x, y), bands[i + 1] if t - i > bayer(x, y) else bands[i])

    def glow(self, cx, cy, radius, strength, warm=True):
        """Lichtschein als feines Punktraster: ersetzt Pixel durch wärmere (bzw. rote) Töne."""
        dot = WAMBER if warm else RED[2]
        for y in range(cy - radius, cy + radius):
            for x in range(cx - radius, cx + radius):
                if not (0 <= x < self.w and 0 <= y < self.h):
                    continue
                c = self.im.getpixel((x, y))
                if c[3] == 0 or c in WARM or c in (RED[2], RED[3], RED[4], GOLD, GOLD2):
                    continue
                dist = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                if dist >= radius:
                    continue
                inten = (1 - dist / radius) ** 1.3 * strength
                tone = (WEMBER if lum(c) < 90 else WGLUT) if warm else (RED[0] if lum(c) < 45 else RED[1])
                if inten > 0.5 and (x + y) % 2 == 0:
                    self.im.putpixel((x, y), tone)
                elif inten > 0.25 and x % 2 == 0 and y % 2 == 0:
                    self.im.putpixel((x, y), dot if inten > 0.4 else tone)
                elif inten > 0.08 and x % 4 == 0 and y % 4 == (x // 4) % 2 * 2:
                    self.im.putpixel((x, y), dot)

    def outline(self, c=BLACK):
        src = self.im.copy()
        for y in range(self.h):
            for x in range(self.w):
                if src.getpixel((x, y))[3] == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < self.w and 0 <= ny < self.h and src.getpixel((nx, ny))[3] and src.getpixel((nx, ny)) != c:
                            self.im.putpixel((x, y), c)
                            break

    def save(self, rel):
        out = ART / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        self.im.save(out)


def load_raster(name):
    rows = [r.rstrip("\n") for r in (RASTERS / f"{name}.txt").read_text().split("\n") if r.strip() and not r.startswith("#")]
    w = max(len(r) for r in rows)
    return [r.ljust(w, ".") for r in rows]


def rng(seed):
    return random.Random(seed)
