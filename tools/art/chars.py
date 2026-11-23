"""Figuren 24x40 aus Pixel-Textrastern, mit Animationsframes."""
from common import (BLACK, BROWN, GOLD, GOLD2, INK, RED, SHADOW, SLATE, ST, Canvas, load_raster)

FW, FH = 24, 40
ROWS = [("idle", 2), ("lauf", 4), ("sprung", 1), ("schlag", 3)]
LEG_TOP = 30
LEFT_LEG = range(5, 10)
RIGHT_LEG = range(10, 16)


def legend(hair, hair_light, cloak, cloak_light, cloak_dark, tunic=SLATE[0], pants=SLATE[0], pants_light=SLATE[1]):
    return {"k": BLACK, "h": hair, "H": hair_light, "s": BROWN[3], "S": BROWN[2], "e": BLACK,
            "r": cloak, "R": cloak_light, "q": cloak_dark, "g": GOLD, "G": GOLD2, "t": tunic,
            "b": pants, "B": pants_light, "l": BROWN[0], "w": ST[5], "W": ST[6]}


def _shift_legs(rows, dl, dr, lift_l=0, lift_r=0):
    """Verschiebt linkes/rechtes Bein horizontal (dl/dr) und hebt einen Fuß an."""
    out = [list(r) for r in rows]
    for y in range(LEG_TOP, FH):
        for x in list(LEFT_LEG) + list(RIGHT_LEG):
            out[y][x] = "."
    for side, cols, dx, lift in (("l", LEFT_LEG, dl, lift_l), ("r", RIGHT_LEG, dr, lift_r)):
        for y in range(LEG_TOP, FH):
            for x in cols:
                ch = rows[y][x]
                if ch != ".":
                    ny, nx = y - lift, x + dx
                    if 0 <= nx < FW and LEG_TOP - 1 <= ny < FH and out[ny][nx] == ".":
                        out[ny][nx] = ch
    return ["".join(r) for r in out]


def _bob(rows, dy):
    if dy == 0:
        return rows
    body = rows[:LEG_TOP]
    legs = rows[LEG_TOP:]
    return ["." * FW] * dy + body[:len(body) - dy] + legs if dy > 0 else rows


def _weapon(c, kind, frame, ox, oy):
    """Waffe in die Hand (Hand bei Spalte 18, Zeile 19)."""
    hx, hy = ox + 18, oy + 19
    if kind == "schwert":
        tips = {None: [(19, 18), (20, 17), (21, 16), (22, 15)], 0: [(19, 17), (19, 15), (19, 13), (20, 11), (20, 9)],
                1: [(20, 19), (21, 19), (22, 19), (23, 19)], 2: [(19, 21), (20, 23), (21, 25), (22, 27)]}[frame]
        for i, (x, y) in enumerate(tips):
            c.px(ox + x, oy + y, ST[6] if i == len(tips) - 1 else ST[5])
        c.px(hx, hy, GOLD)
    elif kind == "stab":
        line = {None: [(20, y) for y in range(4, 38)], 0: [(18 + i // 6, 2 + i) for i in range(30)],
                1: [(14 + i, 19 - i // 3) for i in range(10)], 2: [(19 + i // 5, 18 + i) for i in range(18)]}[frame]
        for (x, y) in line:
            c.px(ox + x, oy + y, BROWN[2] if frame is not None else BROWN[0])
        top = line[0] if frame is None or frame == 0 else line[-1]
        c.px(ox + top[0], oy + top[1], GOLD2)
        c.px(ox + top[0], oy + top[1] + 1, GOLD)


def sheet(rows, leg, weapon, overlay=None):
    c = Canvas(FW * 4, FH * 4)
    frames = {
        "idle": [(rows, 0), (rows, 1)],
        "lauf": [(_shift_legs(rows, 1, -1, 1, 0), 0), (rows, 1), (_shift_legs(rows, -1, 1, 0, 1), 0), (rows, 1)],
        "sprung": [(_shift_legs(rows, -1, 1, 2, 3), 0)],
        "schlag": [(rows, 0), (rows, 0), (rows, 0)],
    }
    for r, (anim, n) in enumerate(ROWS):
        for f in range(n):
            base, bob = frames[anim][f]
            ox, oy = f * FW, r * FH
            body = _bob(base, bob)
            c.raster(body, leg, ox, oy)
            if overlay:
                c.raster(overlay[0], overlay[1], ox, oy + bob)
            if weapon:
                _weapon(c, weapon, f if anim == "schlag" else None, ox, oy + bob)
    return c


def lira_rows(base):
    rows = [list(r) for r in base]
    for y in range(9, 16):  # Haar fällt bis auf die Schultern
        for x in range(2, 6):
            if rows[y][x] == "." and x >= 6 - (y - 8) // 2:
                rows[y][x] = "h"
    return ["".join(r) for r in rows]


def humanize(rows):
    """Menschen haben kein spitzes Ohr."""
    out = [list(r) for r in rows]
    for y in range(5, 10):
        for x in range(0, 5):
            out[y][x] = "."
    out[6][4] = out[7][4] = out[8][4] = "k"
    return ["".join(r) for r in out]


def make_all():
    base = load_raster("held_basis")
    sheet(base, legend(BROWN[0], BROWN[1], RED[1], RED[2], RED[0]), "schwert").save("chars/warschick.png")
    sheet(lira_rows(base), legend(ST[5], ST[6], RED[1], RED[2], RED[0]), "stab").save("chars/lira.png")
    hut = load_raster("hut")
    hut_leg = {"k": BLACK, "H": BROWN[1], "g": GOLD}
    sheet(humanize(base), legend(ST[4], ST[5], BROWN[1], BROWN[2], BROWN[0], tunic=BROWN[0]), None, (hut, hut_leg)).save("chars/kartograf.png")
    sheet(lira_rows(humanize(base)), legend(INK, SHADOW, SLATE[1], SLATE[2], SLATE[0], tunic=SLATE[0]), None).save("chars/gildenmeisterin.png")
