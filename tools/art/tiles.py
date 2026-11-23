"""Kachel-Atlas 16x16 (15 Kacheln). Reihenfolge = Kachel-IDs in game/core/world/room_def.gd."""
from common import (BLACK, BROWN, GOLD, GOLD0, GOLD2, INK, MOSS, NIGHT, RED, SHADOW, ST, Canvas, bayer, rng)

ORDER = ["leer", "erde", "gras", "plattform", "dungeon", "blut", "bruechig", "stachel",
         "platte", "tor_zu", "tor_auf", "rastort", "gilde", "dielen", "balken"]


def tile(kind):
    c = Canvas(16, 16)
    r = rng(hash(kind) % 1000)
    if kind == "erde":
        for y in range(16):
            for x in range(16):
                c.px(x, y, BROWN[0] if bayer(x, y) < 0.55 else SHADOW)
        for _ in range(4):
            x, y = r.randrange(1, 14), r.randrange(1, 14)
            c.rect(x, y, x + 1, y, ST[1])
            c.px(x, y - 1, ST[2])
    elif kind == "gras":
        for y in range(16):
            for x in range(16):
                c.px(x, y, BROWN[0] if bayer(x, y) < 0.55 else SHADOW)
        c.rect(0, 0, 15, 3, MOSS[2])
        for x in range(16):
            c.px(x, 4 if x % 3 else 5, MOSS[1])
            if x % 2 == 0:
                c.px(x, 0, MOSS[3])
        for x in (2, 7, 12):
            c.px(x, 1, MOSS[4])
    elif kind == "plattform":
        c.rect(0, 0, 15, 4, BROWN[1])
        c.rect(0, 0, 15, 0, BROWN[2])
        c.rect(0, 4, 15, 4, BLACK)
        for x in (5, 11):
            c.px(x, 2, BROWN[0])
        for x in (2, 13):
            c.rect(x, 5, x, 9, BROWN[0])
    elif kind == "dungeon":
        c.rect(0, 0, 15, 15, INK)
        c.rect(0, 0, 15, 0, NIGHT)
        c.rect(0, 0, 0, 15, NIGHT)
        c.rect(0, 8, 15, 8, BLACK)
        c.rect(8, 0, 8, 7, BLACK)
        c.rect(3, 9, 3, 15, BLACK)
        for _ in range(3):
            c.px(r.randrange(16), r.randrange(16), SHADOW)
    elif kind == "blut":
        c.rect(0, 0, 15, 15, BLACK)
        c.rect(0, 0, 15, 0, RED[0])
        for x0, y0, x1, y1 in ((2, 3, 6, 9), (6, 9, 5, 15), (11, 1, 13, 7)):
            c.d.line([(x0, y0), (x1, y1)], fill=RED[0])
        c.px(6, 9, RED[1])
    elif kind == "bruechig":
        c.rect(0, 0, 15, 15, ST[1])
        c.rect(0, 0, 15, 0, ST[2])
        for a, b in (((2, 2), (7, 8)), ((7, 8), (5, 15)), ((7, 8), (13, 6)), ((13, 6), (15, 11))):
            c.d.line([a, b], fill=BLACK)
    elif kind == "stachel":
        for i in range(4):
            x = i * 4
            c.d.polygon([(x, 15), (x + 2, 5), (x + 3, 15)], fill=ST[3])
            c.px(x + 2, 5, ST[5])
            c.px(x + 2, 9, RED[1])
        c.rect(0, 15, 15, 15, BLACK)
    elif kind == "platte":
        c.rect(1, 12, 14, 15, ST[2])
        c.rect(3, 11, 12, 12, GOLD0)
        c.px(7, 11, GOLD)
    elif kind == "tor_zu":
        c.rect(1, 0, 14, 15, BLACK)
        for x in (3, 7, 11):
            c.rect(x, 0, x + 1, 15, ST[3])
            c.px(x, 0, ST[4])
        c.rect(1, 6, 14, 7, ST[2])
    elif kind == "tor_auf":
        c.rect(1, 0, 14, 2, BLACK)
        for x in (3, 7, 11):
            c.rect(x, 0, x + 1, 2, ST[3])
    elif kind == "rastort":
        c.rect(3, 9, 12, 15, ST[2])
        c.rect(2, 7, 13, 8, ST[3])
        c.rect(6, 10, 9, 13, GOLD0)
    elif kind == "gilde":
        c.rect(7, 0, 8, 15, BROWN[0])
        c.rect(2, 2, 13, 9, BROWN[1])
        c.rect(4, 4, 11, 7, GOLD0)
        c.rect(6, 5, 9, 6, GOLD)
    elif kind == "dielen":
        for y in range(16):
            for x in range(16):
                c.px(x, y, BROWN[1] if (x + (y // 4) * 6) % 16 else BROWN[0])
        c.rect(0, 0, 15, 0, BROWN[2])
        for y in (3, 7, 11, 15):
            c.rect(0, y, 15, y, BROWN[0])
    elif kind == "balken":
        c.rect(0, 0, 15, 15, BROWN[0])
        c.rect(0, 0, 1, 15, BROWN[1])
        c.rect(14, 0, 15, 15, BLACK)
        for y in (4, 11):
            c.px(7, y, GOLD2)
            c.px(8, y, BROWN[2])
    return c.im


def make_all():
    atlas = Canvas(16 * len(ORDER), 16)
    for i, k in enumerate(ORDER):
        if k != "leer":
            atlas.im.paste(tile(k), (i * 16, 0))
    atlas.save("tiles.png")
