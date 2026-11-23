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


def house(roof_dark, roof_light, wall, wall_dot, width=112, roof=46, walls=74, windows=True, sign=None):
    g = _grid(width, roof + walls)
    mid = width // 2
    for y in range(roof):
        half = 8 + int(y * 1.15)
        for x in range(width):
            if abs(x - mid) <= half:
                ch = "t" if (y % 5 == 0 or (x + (y // 5) * 4) % 8 == 0) else "T"
                if abs(x - mid) >= half - 1 or y == roof - 1:
                    ch = "k"
                g[y][x] = ch
    for y in range(roof, roof + walls):
        for x in range(5, width - 5):
            ch = "p"
            if (x - 5) % 34 in (0, 1) or y - roof in (0, 1, 28, walls - 1):
                ch = "f"
            elif (x * 7 + y * 3) % 23 == 0:
                ch = "P"
            g[y][x] = ch
    dy0 = roof + walls - DOOR_H
    _box(g, mid - 10, dy0, mid + 9, roof + walls - 1, "k")
    _box(g, mid - 9, dy0 + 2, mid + 8, roof + walls - 1, "D")
    _box(g, mid - 9, dy0 + 1, mid + 8, dy0 + 2, "f")
    for x in range(mid - 9, mid + 9, 4):
        _box(g, x, dy0 + 3, x, roof + walls - 1, "d")
    g[dy0 + 24][mid + 5] = "g"
    if windows:
        for wx in (14, width - 34):
            _box(g, wx, roof + 10, wx + 19, roof + 26, "k")
            _box(g, wx + 1, roof + 11, wx + 18, roof + 25, "L")
            _box(g, wx + 1, roof + 18, wx + 18, roof + 18, "f")
            _box(g, wx + 9, roof + 11, wx + 10, roof + 25, "f")
            _box(g, wx + 1, roof + 11, wx + 6, roof + 14, "C")
            _box(g, wx - 1, roof + 26, wx + 20, roof + 27, "f")
    _box(g, width - 30, 2, width - 22, 24, "c")
    _box(g, width - 31, 0, width - 21, 2, "k")
    legend = {"k": BLACK, "t": roof_dark, "T": roof_light, "p": wall, "P": wall_dot, "f": BROWN[0], "d": BROWN[0],
              "D": BROWN[1], "g": GOLD, "L": WAMBER, "C": WCANDLE, "c": ST[1]}
    pad_top = 60  # Platz für Rauch
    c = Canvas(width + 40, roof + walls + pad_top)
    c.raster(["".join(r) for r in g], legend, 20, pad_top)
    # Rauch aus dem Schornstein
    for i, (dx, dy, r) in enumerate(((0, 0, 4), (4, -11, 5), (-1, -23, 6), (6, -36, 6), (2, -50, 7))):
        cx, cy = 20 + width - 26 + dx, pad_top - 4 + dy
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r and bayer(x, y) < 0.75 - i * 0.12:
                    c.px(x, y, ST[3] if i < 2 else ST[2])
    if windows:
        for wx in (14, width - 34):
            c.glow(20 + wx + 10, pad_top + roof + 18, 30, 0.7)
    if sign:
        sx, sy = 6, pad_top + roof + 8
        c.rect(sx + 14, sy - 2, sx + 15, sy + 30, BROWN[0])
        c.rect(sx, sy, sx + 22, sy + 13, BROWN[1])
        c.rect(sx + 2, sy + 2, sx + 20, sy + 11, sign)
        c.rect(sx + 7, sy + 5, sx + 15, sy + 8, GOLD if sign == GOLD0 else ST[6])
    return c


def muehle():
    c = Canvas(100, 150)
    c.d.polygon([(30, 149), (38, 50), (62, 50), (70, 149)], fill=ST[1])
    for y in range(52, 149, 9):
        c.d.line([(36, y), (66, y)], fill=ST[0])
    c.d.polygon([(32, 52), (50, 30), (68, 52)], fill=BROWN[0])
    c.rect(44, 118, 56, 149, BLACK)          # Tür (dunkel, keine Wärme)
    c.rect(45, 120, 55, 149, BROWN[0])
    c.rect(46, 80, 53, 90, BLACK)
    for (x1, y1) in ((10, 8), (92, 14), (8, 78), (92, 84)):  # gebrochene Flügel
        c.d.line([(50, 46), (x1, y1)], fill=BROWN[0], width=3)
        c.d.line([(50, 46), (x1, y1)], fill=BROWN[1], width=1)
    c.d.ellipse([46, 42, 54, 50], fill=BLACK)
    return c


def laterne():
    c = Canvas(24, 56)
    c.rect(11, 14, 12, 55, BLACK)
    c.rect(7, 4, 16, 14, BLACK)
    c.rect(8, 5, 15, 13, WCANDLE)
    c.rect(10, 7, 13, 11, WLIGHT)
    c.rect(6, 3, 17, 3, BLACK)
    c.rect(9, 53, 14, 55, BLACK)
    return c


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
    """Punktraster-Lichtschein auf Transparenz (wird im Spiel über die Szene gelegt)."""
    c = Canvas(radius * 2, radius * 2)
    tone_in, tone_out = (WGLUT, WAMBER) if warm else (RED[1], RED[2])
    for y in range(radius * 2):
        for x in range(radius * 2):
            dist = ((x - radius) ** 2 + (y - radius) ** 2) ** 0.5
            if dist >= radius:
                continue
            inten = (1 - dist / radius) ** 1.3
            if inten > 0.55 and (x + y) % 2 == 0:
                c.px(x, y, tone_in if warm else RED[0])
            elif inten > 0.28 and x % 2 == 0 and y % 2 == 0:
                c.px(x, y, tone_out)
            elif inten > 0.1 and x % 4 == 0 and y % 4 == (x // 4) % 2 * 2:
                c.px(x, y, tone_out)
    return c


def make_all():
    house(RED[0], RED[1], ST[3], ST[2], sign=GOLD0).save("deco/gildenhaus.png")
    house(SLATE[0], SLATE[1], ST[2], ST[1], width=96, roof=40, walls=66, sign=ST[5]).save("deco/kartografhaus.png")
    builders = {"muehle": muehle, "laterne": laterne, "baum": baum, "zaun": zaun, "wegweiser": wegweiser,
                "kristall": kristall, "kette": kette, "toter_abenteurer": toter_abenteurer,
                "tuer": tuer, "schrein": schrein, "tresen": tresen, "kiste": kiste, "altar": altar}
    for name, fn in builders.items():
        fn().save(f"deco/{name}.png")
    bogen(False).save("deco/bogen.png")
    bogen(True).save("deco/bogen_warm.png")
    for r in (16, 24, 32, 48):
        light_texture(r, True).save(f"light/warm_{r}.png")
        light_texture(r, False).save(f"light/kalt_{r}.png")
