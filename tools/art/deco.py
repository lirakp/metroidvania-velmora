"""Deko-Objekte (Häuser, Laternen, Bäume …) und Licht-Texturen.

Häuser werden als Zeichen-Raster aufgebaut (ein Zeichen = ein Pixel) und dann über eine Legende eingefärbt.
Alle Deko-Bilder stehen unten mittig auf dem Boden (Fußpunkt = unterer Rand, Mitte).
"""
from common import (BLACK, BROWN, GOLD, GOLD0, GOLD2, INK, MOSS, NIGHT, RED, SHADOW, SLATE, ST, WAMBER, WCANDLE,
                    WEMBER, WGLUT, WLIGHT, WSHADE, Canvas, bayer, rng)

DOOR_H = 46


def _grid(w, h):
    return [["." for _ in range(w)] for _ in range(h)]


def _box(g, x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            g[y][x] = ch


def baum():
    c = Canvas(64, 96)
    c.rect(28, 50, 34, 95, BROWN[0])
    c.rect(29, 50, 30, 95, BROWN[1])
    for (cx, cy, r) in ((32, 34, 24), (14, 46, 15), (50, 46, 16)):
        c.d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=MOSS[1])
    for (cx, cy, r) in ((26, 24, 11), (46, 38, 8)):
        c.d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=MOSS[2])
    r = rng(7)
    for _ in range(40):
        c.px(r.randint(6, 58), r.randint(10, 60), MOSS[3])
    return c


def zaun():
    c = Canvas(64, 20)
    for x in range(1, 64, 9):
        c.rect(x, 2, x + 1, 19, BROWN[1])
        c.px(x, 1, BROWN[2])
    c.d.line([(0, 6), (63, 6)], fill=BROWN[1])
    c.d.line([(0, 13), (63, 13)], fill=BROWN[1])
    return c


def wegweiser():
    c = Canvas(44, 34)
    c.rect(19, 6, 21, 33, BROWN[0])
    c.d.polygon([(2, 4), (36, 4), (41, 10), (36, 16), (2, 16)], fill=BROWN[1])
    c.d.line([(7, 10), (30, 10)], fill=BROWN[0])
    return c


def kristall():
    c = Canvas(16, 24)
    c.d.polygon([(8, 2), (13, 14), (8, 22), (3, 14)], fill=RED[3])
    c.d.polygon([(8, 2), (8, 22), (3, 14)], fill=RED[2])
    c.px(7, 7, RED[4])
    return c


def kette():
    c = Canvas(6, 80)
    for y in range(0, 80, 4):
        o = (y // 4) % 2
        c.d.rectangle([1 + o, y, 2 + o, y + 2], outline=ST[1])
    return c


def toter_abenteurer():
    c = Canvas(44, 14)
    c.rect(4, 8, 30, 12, SLATE[0])              # Körper liegend
    c.rect(8, 6, 26, 10, ST[1])                 # Rüstung
    c.d.ellipse([30, 5, 38, 13], fill=BROWN[3])
    c.rect(30, 5, 38, 7, ST[3])
    c.d.line([(2, 13), (16, 13)], fill=RED[0])  # getrocknetes Blut
    c.px(34, 9, BLACK)
    c.rect(18, 9, 20, 11, ST[0])               # schwarze Plakette
    return c


def bogen(warm):
    """Öffnung in einer Wand (Durchgang nach hinten). Warm = Licht aus einem sicheren Raum dringt heraus."""
    c = Canvas(44, 70)
    c.d.ellipse([4, 4, 40, 36], fill=ST[1])
    c.rect(4, 20, 40, 69, ST[1])
    c.d.ellipse([7, 7, 37, 33], fill=BLACK)
    c.rect(7, 20, 37, 69, BLACK)
    if warm:
        for y in range(30, 70):
            for x in range(8, 37):
                if (x + y) % 2 == 0 and y > 44 + abs(x - 22) // 2:
                    c.px(x, y, WSHADE)
        for y in range(56, 70):
            for x in range(10, 35):
                if x % 2 == 0 and y % 2 == 0:
                    c.px(x, y, WEMBER)
    return c


def tuer():
    c = Canvas(26, 50)
    c.rect(0, 0, 25, 49, BLACK)
    c.rect(2, 2, 23, 49, BROWN[1])
    for x in range(2, 24, 5):
        c.rect(x, 3, x, 49, BROWN[0])
    c.px(19, 26, GOLD)
    return c


def schrein():
    c = Canvas(28, 40)
    c.rect(4, 8, 23, 39, ST[3])
    c.rect(2, 4, 25, 8, ST[4])
    c.rect(9, 14, 18, 28, BLACK)
    c.rect(10, 15, 17, 27, GOLD0)
    c.rect(12, 18, 15, 23, GOLD)
    c.px(13, 2, WCANDLE)
    c.rect(12, 3, 14, 3, GOLD2)
    c.glow(13, 20, 14, 0.5)
    return c


def tresen():
    c = Canvas(76, 30)
    c.rect(2, 4, 73, 29, BROWN[1])
    c.rect(0, 0, 75, 4, BROWN[2])
    for x in range(6, 72, 12):
        c.rect(x, 7, x + 8, 26, BROWN[0])
    return c


def kiste():
    c = Canvas(20, 18)
    c.rect(0, 2, 19, 17, BROWN[1])
    c.rect(0, 2, 19, 3, BROWN[2])
    c.d.line([(0, 2), (19, 17)], fill=BROWN[0])
    c.d.line([(19, 2), (0, 17)], fill=BROWN[0])
    return c


def altar():
    c = Canvas(64, 50)
    c.rect(14, 24, 49, 49, ST[2])
    c.rect(10, 20, 53, 24, ST[3])
    c.d.line([(10, 20), (53, 20)], fill=ST[4])
    c.rect(26, 28, 37, 40, ST[1])
    c.rect(29, 31, 34, 37, GOLD0)
    for cx, ch in ((16, 8), (22, 5), (42, 7)):
        c.rect(cx, 20 - ch, cx + 2, 19, GOLD2)
        c.px(cx + 1, 19 - ch, WCANDLE)
        c.px(cx + 1, 18 - ch, WLIGHT)
    c.glow(32, 12, 30, 0.75)
    return c


def light_texture(radius, warm):
    """Feines Punktraster auf Transparenz (wird im Spiel über die Szene gelegt, flackert leicht)."""
    c = Canvas(radius * 2, radius * 2)
    bright, mid, faint = (WAMBER, WEMBER, WAMBER) if warm else (RED[2], RED[1], RED[1])
    for y in range(radius * 2):
        for x in range(radius * 2):
            dist = ((x - radius) ** 2 + (y - radius) ** 2) ** 0.5
            if dist >= radius:
                continue
            inten = (1 - dist / radius) ** 1.3
            if inten > 0.6 and x % 2 == 0 and y % 2 == 0:
                c.px(x, y, bright)
            elif inten > 0.3 and x % 2 == 0 and y % 2 == 0:
                c.px(x, y, mid)
            elif inten > 0.1 and x % 4 == 0 and y % 4 == (x // 4) % 2 * 2:
                c.px(x, y, faint)
    return c


def plakette():
    """Seelenplakette (Symbol für Pickup und Programm-Icon)."""
    c = Canvas(16, 16)
    c.rect(4, 2, 11, 13, ST[3])
    c.rect(5, 3, 10, 12, ST[4])
    c.rect(7, 5, 8, 10, BLACK)
    c.px(9, 6, BLACK)
    c.px(9, 9, BLACK)
    c.rect(7, 0, 8, 2, ST[2])
    c.outline()
    return c


def make_all():
    builders = {"baum": baum, "zaun": zaun, "wegweiser": wegweiser,
                "kristall": kristall, "kette": kette, "toter_abenteurer": toter_abenteurer,
                "tuer": tuer, "schrein": schrein, "tresen": tresen, "kiste": kiste, "altar": altar}
    for name, fn in builders.items():
        fn().save(f"deco/{name}.png")
    bogen(False).save("deco/bogen.png")
    bogen(True).save("deco/bogen_warm.png")
    for r in (16, 24, 32, 48):
        light_texture(r, False).save(f"light/kalt_{r}.png")
    plakette().save("ui/plakette.png")
