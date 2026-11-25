"""Hintergründe in drei Ebenen je Biom: layer_0 (fern, deckend), layer_1 (mittel), layer_2 (nah)."""
from common import (BLACK, BROWN, GOLD, GOLD0, GOLD2, INK, MOSS, NIGHT, RED, SHADOW, SLATE, ST, WAMBER, WCANDLE,
                    WEMBER, WGLUT, WLIGHT, WSHADE, Canvas, bayer, rng)

W, H = 480, 270


def save_layers(biome, layers):
    for i, c in enumerate(layers):
        c.save(f"bg/{biome}/layer_{i}.png")


# ------------------------------------------------------------ Himmel mit Blutmond
def night_sky(seed, moon=(300, 46)):
    r = rng(seed)
    c = Canvas(W, H, BLACK)
    c.gradient([BLACK, INK, NIGHT, SHADOW, SLATE[0]], 0, H)
    for _ in range(90):
        c.px(r.randrange(W), r.randrange(160), ST[4] if r.random() < 0.7 else ST[6])
    for x, y in ((60, 40), (210, 22), (420, 90), (150, 70)):
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            c.px(x + dx, y + dy, ST[6] if (dx, dy) == (0, 0) else ST[4])
    mx, my, mr = moon[0], moon[1], 18
    for y in range(my - mr - 4, my + mr + 5):
        for x in range(mx - mr - 4, mx + mr + 5):
            dist = ((x - mx) ** 2 + (y - my) ** 2) ** 0.5
            if dist <= mr:
                col = RED[3]
                if ((x - mx - 7) ** 2 + (y - my + 3) ** 2) ** 0.5 > mr + 2:
                    col = RED[2]
                for cx, cy, cr in ((-6, -5, 4), (5, 6, 3), (-2, 8, 2)):
                    if (x - mx - cx) ** 2 + (y - my - cy) ** 2 <= cr * cr:
                        col = RED[2]
                if dist > mr - 1:
                    col = RED[1]
                c.im.putpixel((x, y), col)
            elif mr + 2 <= dist < mr + 3 and (x + y) % 2 == 0:
                c.im.putpixel((x, y), RED[0])
    for (cx, cy, w, col, top) in ((40, 80, 80, SLATE[0], SLATE[1]), (180, 46, 60, NIGHT, SHADOW), (380, 108, 70, SLATE[0], SLATE[1])):
        for i in range(w // 8):
            x = cx + i * 8
            rr = 5 + (i * 7) % 4
            c.d.ellipse([x - rr, cy - rr, x + rr, cy + rr // 2 + 2], fill=col)
            c.d.ellipse([x - rr + 2, cy - rr, x + rr - 2, cy - rr + 3], fill=top)
        c.rect(cx - 4, cy, cx + w - 4, cy + 4, col)
    return c


def mountains(seed):
    c = Canvas(W, H)
    for base, amp, col, light, s in ((140, 7, SLATE[0], SLATE[1], seed), (168, 5, NIGHT, SHADOW, seed + 1)):
        r = rng(s)
        y, pts = base, []
        for x in range(0, W + 7, 7):
            y += r.randint(-amp, amp)
            y = max(base - 45, min(base + 8, y))
            pts.append((x, y))
        c.d.polygon([(0, H)] + pts + [(W, H)], fill=col)
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            if y1 < y0:
                c.d.line([(x0, y0), (x1, y1)], fill=light)
    return c


def pines(seed, base=200):
    r = rng(seed)
    c = Canvas(W, H)
    for x in range(-4, W + 10, 10):
        x += r.randint(-2, 2)
        hgt = r.randint(22, 34)
        for i in range(hgt):
            w = max(1, (i * 6) // hgt + (i % 4 == 3))
            c.d.line([(x - w, base - hgt + i), (x + w, base - hgt + i)], fill=MOSS[0])
            if i % 4 == 1:
                c.px(x - w, base - hgt + i, MOSS[1])
    c.rect(0, base, W - 1, H - 1, MOSS[0])
    return c


def _wood_wall(c, x0, x1, y0, y1):
    for x in range(x0, x1):
        for y in range(y0, y1):
            c.im.putpixel((x, y), BROWN[0] if (x // 12) % 2 == 0 else WSHADE)
    for x in range(x0, x1, 12):
        c.d.line([(x, y0), (x, y1 - 1)], fill=BLACK)
    for y in (y0, y0 + 1, y0 + 80):
        c.d.line([(x0, y), (x1 - 1, y)], fill=BROWN[1])


def innen_gilde():
    far = Canvas(W, H, BLACK)
    _wood_wall(far, 0, W, 0, H)
    mid = Canvas(W, H)
    # Schwarzes Brett mit Aufträgen
    mid.rect(80, 70, 150, 112, BROWN[1])
    mid.rect(82, 72, 148, 110, BROWN[2])
    for (x, y) in ((86, 76), (108, 74), (124, 90), (92, 94), (132, 78)):
        mid.rect(x, y, x + 12, y + 14, ST[6])
        mid.d.line([(x + 2, y + 4), (x + 10, y + 4)], fill=ST[3])
        mid.d.line([(x + 2, y + 7), (x + 8, y + 7)], fill=ST[3])
        mid.px(x + 6, y, RED[2])
    # Kamin mit Feuer
    fx, fy = 340, 222
    mid.rect(fx - 30, 70, fx + 30, fy, ST[1])
    for y in range(72, fy, 8):
        mid.d.line([(fx - 30, y), (fx + 30, y)], fill=ST[0])
    mid.rect(fx - 34, 66, fx + 34, 72, ST[2])
    mid.rect(fx - 18, fy - 34, fx + 18, fy, BLACK)
    mid.d.polygon([(fx - 12, fy), (fx - 4, fy - 22), (fx, fy - 12), (fx + 5, fy - 26), (fx + 12, fy)], fill=WGLUT)
    mid.d.polygon([(fx - 7, fy), (fx - 2, fy - 13), (fx + 4, fy - 16), (fx + 7, fy)], fill=WAMBER)
    mid.d.polygon([(fx - 3, fy), (fx, fy - 7), (fx + 3, fy)], fill=WCANDLE)
    # Fenster mit Blick auf den Blutmond
    mid.rect(196, 60, 244, 110, BLACK)
    mid.rect(198, 62, 242, 108, NIGHT)
    mid.d.ellipse([226, 68, 238, 80], fill=RED[2])
    mid.rect(219, 62, 220, 108, BROWN[0])
    mid.rect(198, 84, 242, 85, BROWN[0])
    near = Canvas(W, H)
    for x in (40, 440):  # Deckenlaternen
        near.d.line([(x, 0), (x, 30)], fill=BLACK)
        near.rect(x - 4, 30, x + 4, 40, BLACK)
        near.rect(x - 3, 31, x + 3, 39, WCANDLE)
    far.glow(fx, fy - 14, 64, 0.6)
    far.glow(40, 35, 26, 0.5)
    far.glow(440, 35, 26, 0.5)
    save_layers("innen_gilde", [far, mid, near])


def innen_haus():
    far = Canvas(W, H, BLACK)
    _wood_wall(far, 0, W, 0, H)
    mid = Canvas(W, H)
    # Regale voller Karten und Schriftrollen
    for sx in (60, 330):
        mid.rect(sx, 60, sx + 90, 200, BROWN[1])
        for y in range(70, 200, 30):
            mid.rect(sx, y + 22, sx + 90, y + 24, BROWN[0])
            for i in range(9):
                col = (ST[6], BROWN[3], GOLD0, ST[5])[(i + y) % 4]
                mid.rect(sx + 4 + i * 9, y + 6, sx + 9 + i * 9, y + 21, col)
    # Kartentisch mit ausgerollter Karte, Kerze
    mid.rect(190, 150, 290, 156, BROWN[2])
    mid.rect(196, 156, 200, 222, BROWN[0])
    mid.rect(280, 156, 284, 222, BROWN[0])
    mid.rect(200, 144, 270, 150, ST[6])
    mid.d.line([(206, 146), (230, 148), (262, 145)], fill=RED[1])
    mid.rect(276, 138, 278, 149, GOLD2)
    mid.px(277, 137, WCANDLE)
    mid.px(277, 136, WLIGHT)
    far.glow(277, 140, 40, 0.55)
    save_layers("innen_haus", [far, mid, Canvas(W, H)])


def innen_kammer():
    far = Canvas(W, H, BLACK)
    for row, y in enumerate(range(0, H, 11)):
        off = 12 if row % 2 else 0
        for x in range(-24 + off, W, 24):
            far.rect(max(0, x + 1), y + 1, x + 22, y + 9, INK)
    mid = Canvas(W, H)
    for cx, ch in ((90, 10), (130, 7), (360, 12), (400, 8)):  # Kerzen in Nischen
        mid.rect(cx - 8, 150, cx + 8, 180, BLACK)
        mid.d.ellipse([cx - 8, 142, cx + 8, 158], fill=BLACK)
        mid.rect(cx - 1, 180 - ch, cx + 1, 179, GOLD2)
        mid.px(cx, 179 - ch, WCANDLE)
        mid.px(cx, 178 - ch, WLIGHT)
        far.glow(cx, 175 - ch, 26, 0.5)
    save_layers("innen_kammer", [far, mid, Canvas(W, H)])


def innen_muehle():
    far = Canvas(W, H, BLACK)
    for x in range(W):
        for y in range(H):
            far.im.putpixel((x, y), BLACK if (x // 14) % 2 else INK)
    for x in range(0, W, 14):
        far.d.line([(x, 0), (x, H - 1)], fill=BLACK)
    mid = Canvas(W, H)
    # Zerbrochene Bretter, Mondlicht fällt durch ein Loch im Dach
    for i in range(0, 60):
        for j in range(0, 230):
            x, y = 250 + i + j // 4, j
            if (x + y) % 3 == 0 and 0 <= x < W:
                mid.px(x, y, SLATE[0])
    mid.d.line([(140, 30), (210, 90)], fill=BROWN[0])
    mid.d.line([(300, 20), (330, 110)], fill=BROWN[0])
    mid.d.ellipse([90, 160, 150, 200], fill=ST[1])  # Mühlstein
    mid.d.ellipse([112, 172, 128, 188], fill=BLACK)
    save_layers("innen_muehle", [far, mid, Canvas(W, H)])


def blutmond():
    """Roter Mond (29x29) – wird im Spiel über den gelben Mond des Grafik-Repos gelegt."""
    c = Canvas(29, 29)
    mx = my = 14
    mr = 13
    for y in range(29):
        for x in range(29):
            dist = ((x - mx) ** 2 + (y - my) ** 2) ** 0.5
            if dist <= mr:
                col = RED[3]
                if ((x - mx - 5) ** 2 + (y - my + 2) ** 2) ** 0.5 > mr + 1:
                    col = RED[2]
                for cx, cy, cr in ((-4, -4, 3), (4, 4, 2), (-1, 6, 1)):
                    if (x - mx - cx) ** 2 + (y - my - cy) ** 2 <= cr * cr:
                        col = RED[2]
                if dist > mr - 1:
                    col = RED[1]
                c.px(x, y, col)
    c.save("bg/blutmond.png")


def make_all():
    blutmond()
    innen_gilde()
    innen_haus()
    innen_kammer()
    innen_muehle()
