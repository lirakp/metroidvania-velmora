"""Erzeugt die Platzhalter-Pixelart des Prototyps aus der festen Palette.

Aufruf: python3 tools/gen_art.py
Alle Grafiken nutzen ausschließlich Farben aus game/art/palette.json.
"""
import json
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent.parent
ART = ROOT / "game" / "art"
PAL = [tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)) + (255,)
       for c in json.loads((ART / "palette.json").read_text())["colors"]]

# Benannte Palettenfarben
BLACK, INK, NIGHT, SHADOW = PAL[0], PAL[1], PAL[2], PAL[3]
STONE1, STONE2, STONE3, STONE4, STONE5, STONE6, BONE = PAL[4], PAL[5], PAL[6], PAL[7], PAL[8], PAL[9], PAL[10]
MOSS0, MOSS1, MOSS2, MOSS3, MOSS4 = PAL[11], PAL[12], PAL[13], PAL[14], PAL[15]
SLATE0, SLATE1, SLATE2, SLATE3 = PAL[16], PAL[17], PAL[18], PAL[19]
BROWN0, BROWN1, BROWN2, BROWN3 = PAL[20], PAL[21], PAL[22], PAL[23]
RED0, RED1, RED2, BLOOD, RED4 = PAL[24], PAL[25], PAL[26], PAL[27], PAL[28]
GOLD0, GOLD, GOLD2 = PAL[29], PAL[30], PAL[31]
CLEAR = (0, 0, 0, 0)

random.seed(7)


def new(w, h, fill=CLEAR):
    return Image.new("RGBA", (w, h), fill)


def px(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def rect(im, x0, y0, x1, y1, c):
    ImageDraw.Draw(im).rectangle([x0, y0, x1, y1], fill=c)


def outline(im, c=BLACK):
    """1-px-Kontur um alle undurchsichtigen Pixel."""
    src = im.copy()
    for y in range(im.height):
        for x in range(im.width):
            if src.getpixel((x, y))[3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < im.width and 0 <= ny < im.height and src.getpixel((nx, ny))[3] and src.getpixel((nx, ny)) != c:
                        im.putpixel((x, y), c)
                        break


def dither(im, x0, y0, x1, y1, a, b, density=0.5):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px(im, x, y, a if ((x + y) % 2 == 0) == (random.random() < density + 0.25) else b)


# ---------------------------------------------------------------- Kacheln
def tile(kind):
    t = new(16, 16)
    if kind == "erde":
        dither(t, 0, 0, 15, 15, BROWN0, SHADOW, 0.4)
        for _ in range(5):
            px(t, random.randrange(16), random.randrange(16), STONE2)
    elif kind == "gras":
        dither(t, 0, 4, 15, 15, BROWN0, SHADOW, 0.4)
        rect(t, 0, 2, 15, 4, MOSS2)
        for x in range(0, 16, 2):
            px(t, x, 1 + (x % 3 == 0), MOSS3)
            px(t, x + 1, 2, MOSS1)
    elif kind == "plattform":
        rect(t, 0, 0, 15, 4, BROWN2)
        rect(t, 0, 4, 15, 4, BROWN0)
        for x in (3, 12):
            rect(t, x, 5, x, 8, BROWN1)
        px(t, 7, 1, BROWN3)
    elif kind in ("dungeon", "blut"):
        base, light = (STONE1, STONE2) if kind == "dungeon" else (RED0, RED1)
        rect(t, 0, 0, 15, 15, base)
        for y in (0, 8):
            rect(t, 0, y, 15, y, SHADOW if kind == "dungeon" else BLACK)
        for x, y in ((4, 1), (12, 9)):
            rect(t, x, y, x, y + 6, SHADOW if kind == "dungeon" else BLACK)
        for _ in range(6):
            px(t, random.randrange(16), random.randrange(16), light)
        if kind == "blut":
            for y in range(10, 16):
                px(t, 6, y, BLOOD)
    elif kind == "bruechig":
        rect(t, 0, 0, 15, 15, STONE2)
        for a, b in (((2, 2), (7, 8)), ((7, 8), (5, 14)), ((7, 8), (13, 6)), ((13, 6), (14, 12))):
            ImageDraw.Draw(t).line([a, b], fill=BLACK)
    elif kind == "stachel":
        for i in range(4):
            x = i * 4
            ImageDraw.Draw(t).polygon([(x, 15), (x + 2, 6), (x + 3, 15)], fill=STONE5)
            px(t, x + 2, 6, BONE)
            px(t, x + 2, 9, BLOOD)
    elif kind == "platte":
        rect(t, 1, 12, 14, 15, STONE3)
        rect(t, 3, 11, 12, 12, GOLD0)
    elif kind == "tor_zu":
        rect(t, 1, 0, 14, 15, SHADOW)
        for x in (3, 7, 11):
            rect(t, x, 0, x + 1, 15, STONE4)
        rect(t, 1, 6, 14, 7, STONE3)
    elif kind == "tor_auf":
        rect(t, 1, 0, 14, 2, SHADOW)
        for x in (3, 7, 11):
            rect(t, x, 0, x + 1, 2, STONE4)
    elif kind == "rastort":
        rect(t, 4, 9, 11, 15, STONE3)
        rect(t, 3, 8, 12, 9, STONE4)
        rect(t, 7, 3, 8, 7, GOLD)
        px(t, 7, 2, GOLD2)
    elif kind == "gilde":
        rect(t, 7, 0, 8, 15, BROWN1)
        rect(t, 2, 2, 13, 9, BROWN2)
        rect(t, 4, 4, 11, 7, GOLD0)
        rect(t, 6, 5, 9, 6, GOLD)
    return t


TILE_ORDER = ["leer", "erde", "gras", "plattform", "dungeon", "blut", "bruechig", "stachel",
              "platte", "tor_zu", "tor_auf", "rastort", "gilde"]


def make_tiles():
    atlas = new(16 * len(TILE_ORDER), 16)
    for i, k in enumerate(TILE_ORDER):
        if k != "leer":
            atlas.paste(tile(k), (i * 16, 0))
    atlas.save(ART / "tiles.png")


# ---------------------------------------------------------------- Figuren
def hero_frame(hair, hair_light, weapon, pose, f, cloak=None):
    """16x32 Halbelf im dunkelroten Mantel. pose: idle/lauf/sprung/schlag."""
    im = new(16, 32)
    bob = 1 if (pose == "idle" and f == 1) else 0
    # Beine
    leg = [(0, 0), (2, -1), (0, 0), (-2, 1)][f % 4] if pose == "lauf" else (0, 0)
    if pose == "sprung":
        rect(im, 5, 24, 6, 28, SLATE0)
        rect(im, 9, 23, 10, 27, SLATE0)
    else:
        rect(im, 5 + leg[0], 24, 6 + leg[0], 30, SLATE0)
        rect(im, 9 + leg[1], 24, 10 + leg[1], 30, SLATE0)
        rect(im, 4 + leg[0], 30, 6 + leg[0], 31, BROWN0)
        rect(im, 9 + leg[1], 30, 11 + leg[1], 31, BROWN0)
    # Mantel (gleiches Geschwister-Merkmal)
    y0 = 12 + bob
    c_mid, c_light, c_dark = cloak or (RED1, RED2, RED0)
    ImageDraw.Draw(im).polygon([(4, y0), (11, y0), (12, 25), (3, 25)], fill=c_mid)
    rect(im, 5, y0 + 1, 10, y0 + 2, c_light)
    rect(im, 7, y0 + 3, 8, 24, c_dark)
    # Kopf
    hy = 4 + bob
    rect(im, 5, hy, 10, hy + 7, BROWN3)
    rect(im, 4, hy - 1, 11, hy + 1, hair)
    rect(im, 4, hy, 4, hy + 4, hair)
    px(im, 6, hy - 1, hair_light)
    px(im, 9, hy - 1, hair_light)
    if cloak is None:  # spitzes Halbelfenohr nur bei den Geschwistern
        px(im, 11, hy + 3, BROWN3)
        px(im, 12, hy + 2, BROWN3)
        px(im, 13, hy + 1, BROWN2)
    px(im, 9, hy + 4, BLACK)  # Auge
    # Waffe
    if pose == "schlag":
        arc = [(12, 10), (14, 14), (13, 20)][f]
        ImageDraw.Draw(im).line([(10, 16 + bob), arc], fill=weapon[0], width=1)
        px(im, arc[0], arc[1], weapon[1])
    else:
        rect(im, 12, 14 + bob, 12, 23 + bob, weapon[0])
        px(im, 12, 14 + bob, weapon[1])
    outline(im)
    return im


def make_hero(name, hair, hair_light, weapon, cloak=None):
    sheet = new(16 * 4, 32 * 4)
    rows = [("idle", 2), ("lauf", 4), ("sprung", 1), ("schlag", 3)]
    for r, (pose, n) in enumerate(rows):
        for f in range(n):
            sheet.paste(hero_frame(hair, hair_light, weapon, pose, f, cloak), (f * 16, r * 32))
    (ART / "chars").mkdir(parents=True, exist_ok=True)
    sheet.save(ART / "chars" / f"{name}.png")


# ---------------------------------------------------------------- Gegner
def enemy_frame(kind, f, attack):
    s = 64 if kind == "blutwolf_alpha" else 32
    im = new(s, s)
    d = ImageDraw.Draw(im)
    lunge = 2 if attack and f == 1 else 0
    if kind == "goblin":
        rect(im, 11, 14, 20, 26, MOSS2)
        rect(im, 12, 6, 19, 14, MOSS3)
        px(im, 10, 8, MOSS3); px(im, 9, 7, MOSS3); px(im, 21, 8, MOSS3); px(im, 22, 7, MOSS3)
        px(im, 14, 9, RED4); px(im, 17, 9, RED4)
        rect(im, 12, 27, 13, 30, MOSS1); rect(im, 18, 27, 19, 30, MOSS1)
        d.line([(21, 18), (26 + lunge * 2, 12 - lunge)], fill=STONE5)
    elif kind == "gruenschleim":
        h = 10 + f
        d.ellipse([4, 30 - h, 27, 30], fill=MOSS3)
        d.ellipse([8, 31 - h, 18, 26 - h // 2], fill=MOSS4)
        px(im, 12, 24 - h // 2, BLACK); px(im, 18, 24 - h // 2, BLACK)
        if attack:
            rect(im, 26, 22 - f * 3, 29, 25 - f * 3, MOSS4)
    elif kind in ("skelettkrieger", "skelett_bogner"):
        rect(im, 13, 4, 18, 10, BONE)
        px(im, 14, 7, BLACK); px(im, 17, 7, BLACK)
        rect(im, 15, 11, 16, 20, STONE6)
        for y in (12, 14, 16):
            rect(im, 12, y, 19, y, STONE6)
        rect(im, 13, 21, 14, 30, STONE6); rect(im, 17, 21, 18, 30, STONE6)
        if kind == "skelettkrieger":
            d.line([(20, 14), (25 + lunge * 2, 6)], fill=BROWN3)
        else:
            d.arc([18, 6, 28, 24], 270, 90, fill=BROWN2)
            if attack:
                d.line([(16, 15), (30, 15 - f)], fill=STONE5)
    elif kind == "riesenspinne":
        d.ellipse([9, 14, 24, 24], fill=INK)
        d.ellipse([18, 12, 26, 19], fill=SHADOW)
        for i in range(4):
            x = 11 + i * 4
            d.line([(x, 19), (x - 4 + (f * 2 if i % 2 else 0), 29)], fill=INK)
            d.line([(x, 19), (x - 2, 12 - f)], fill=INK)
        px(im, 23, 14, RED4); px(im, 24, 15, RED4)
    elif kind == "ghul":
        rect(im, 10, 10, 20, 24, STONE3)
        rect(im, 11, 3, 19, 10, STONE4)
        px(im, 13, 6, GOLD); px(im, 17, 6, GOLD)
        rect(im, 13, 8, 17, 9, BLACK)
        d.line([(20, 13), (27 + lunge * 2, 18)], fill=STONE4)
        d.line([(27 + lunge * 2, 18), (29 + lunge * 2, 16)], fill=BONE)
        rect(im, 11, 25, 12, 30, STONE3); rect(im, 18, 25, 19, 30, STONE3)
    elif kind == "blutwolf_alpha":
        y = 2 * f
        d.ellipse([8, 24 + y, 46, 46], fill=RED0)
        d.ellipse([12, 26 + y, 40, 40], fill=RED1)
        d.polygon([(38 + lunge * 2, 20 + y), (58 + lunge * 3, 30 + y), (40 + lunge * 2, 38)], fill=RED1)
        d.polygon([(40, 14 + y), (44, 22 + y), (38, 22 + y)], fill=RED0)
        px(im, 48 + lunge * 2, 27 + y, RED4); px(im, 49 + lunge * 2, 27 + y, RED4)
        for x in (12, 20, 32, 40):
            rect(im, x, 44, x + 3, 58, RED0)
        d.line([(52 + lunge * 3, 31 + y), (57 + lunge * 3, 33 + y)], fill=BONE)
    outline(im)
    return im


def make_enemy(kind):
    s = 64 if kind == "blutwolf_alpha" else 32
    sheet = new(s * 2, s * 2)
    for row, attack in enumerate((False, True)):
        for f in range(2):
            sheet.paste(enemy_frame(kind, f, attack), (f * s, row * s))
    (ART / "enemies").mkdir(parents=True, exist_ok=True)
    sheet.save(ART / "enemies" / f"{kind}.png")


# ---------------------------------------------------------------- Hintergründe
def sky(im):
    bands = [BLACK, INK, NIGHT, SHADOW]
    for y in range(270):
        i = min(3, y * 4 // 200)
        for x in range(480):
            c = bands[i]
            if i < 3 and (y * 4 % 200) > 150 and (x + y) % 2 == 0:
                c = bands[i + 1]
            im.putpixel((x, y), c)
    d = ImageDraw.Draw(im)
    d.ellipse([360, 30, 410, 80], fill=RED2)  # Blutmond
    d.ellipse([364, 34, 404, 74], fill=BLOOD)
    for _ in range(6):
        x, y = random.randrange(370, 400), random.randrange(40, 70)
        px(im, x, y, RED2)
    for _ in range(60):
        px(im, random.randrange(480), random.randrange(150), STONE3)


def make_bg(kind):
    im = new(480, 270)
    d = ImageDraw.Draw(im)
    if kind == "dungeon_blut":
        rect(im, 0, 0, 479, 269, BLACK)
        for y in range(0, 270, 12):
            off = 12 if (y // 12) % 2 else 0
            for x in range(-12 + off, 480, 24):
                rect(im, x + 1, y + 1, x + 22, y + 10, NIGHT if random.random() > 0.15 else RED0)
        for x in (60, 200, 340, 450):
            for y in range(0, 270, 3):
                px(im, x + (y // 20) % 2, y, RED1)
    else:
        sky(im)
        if kind == "kornfeld":
            for i, (col, top) in enumerate(((SLATE0, 170), (MOSS0, 195))):
                pts = [(0, 270)] + [(x, top + int(8 * ((x * (i + 3)) % 37) / 37)) for x in range(0, 481, 20)] + [(480, 270)]
                d.polygon(pts, fill=col)
            for x in range(0, 480, 3):
                h = 6 + (x * 7) % 9
                d.line([(x, 230), (x, 230 - h)], fill=GOLD0 if x % 2 else BROWN1)
            rect(im, 0, 231, 479, 269, BROWN0)
            # Mühle als Silhouette
            rect(im, 90, 150, 104, 200, INK)
            for a, b in (((97, 152), (75, 128)), ((97, 152), (120, 130)), ((97, 152), (78, 172)), ((97, 152), (118, 175))):
                d.line([a, b], fill=INK, width=2)
        else:  # stadt
            x = 0
            while x < 480:
                w = random.randrange(30, 60)
                h = random.randrange(60, 120)
                rect(im, x, 270 - h, x + w - 2, 269, INK)
                d.polygon([(x - 2, 270 - h), (x + w // 2, 270 - h - 20), (x + w, 270 - h)], fill=INK)
                for wy in range(270 - h + 10, 260, 14):
                    if random.random() < 0.3:
                        rect(im, x + 6, wy, x + 9, wy + 5, GOLD0)
                x += w
            rect(im, 230, 90, 244, 200, INK)  # Kirchturm
            d.polygon([(226, 90), (237, 60), (248, 90)], fill=INK)
            px(im, 237, 56, GOLD)
    (ART / "bg").mkdir(parents=True, exist_ok=True)
    im.save(ART / "bg" / f"{kind}.png")


def make_plakette():
    im = new(16, 16)
    rect(im, 4, 2, 11, 13, STONE4)
    rect(im, 5, 3, 10, 12, STONE5)
    rect(im, 7, 5, 8, 10, BLACK)  # Rang-Buchstabe D angedeutet
    px(im, 9, 6, BLACK); px(im, 9, 9, BLACK)
    rect(im, 7, 0, 8, 2, STONE3)
    outline(im)
    (ART / "ui").mkdir(parents=True, exist_ok=True)
    im.save(ART / "ui" / "plakette.png")


def make_all():
    make_tiles()
    for k in ("goblin", "gruenschleim", "skelettkrieger", "riesenspinne", "ghul", "skelett_bogner", "blutwolf_alpha"):
        make_enemy(k)
    for k in ("kornfeld", "stadt", "dungeon_blut"):
        make_bg(k)
    make_plakette()
