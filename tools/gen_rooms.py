"""Erzeugt die .room-Dateien des Vertical Slice (Kornburg + Blut-Dungeon).

Aufruf: python3 tools/gen_rooms.py
Die erzeugten Dateien in game/data/rooms/ sind die Quelle für das Spiel; dieses Skript
hält die Räume nur einheitlich. Änderungen an Räumen am besten hier vornehmen.
"""
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "game" / "data" / "rooms"
W, H = 30, 17


class Room:
    def __init__(self, rid, biome, area, dungeon=False, ground="=", fill="#"):
        self.id, self.biome, self.area, self.dungeon = rid, biome, area, dungeon
        self.g = [["."] * W for _ in range(H)]
        self.exits = []
        self.ents = []
        self.box(0, W - 1, 15, 15, ground)
        self.box(0, W - 1, 16, 16, fill)

    def box(self, x0, x1, y0, y1, ch):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.g[y][x] = ch
        return self

    def exit(self, eid, target, target_exit, y=14):
        x = 0 if eid[0] == "L" else W - 1
        self.g[y][x] = eid[1]
        self.g[y - 1][x] = "."
        self.exits.append(f"{eid}={target}:{target_exit}")
        return self

    def ent(self, line):
        self.ents.append(line)
        return self

    def write(self):
        head = [f"id: {self.id}", f"biome: {self.biome}", f"area: {self.area}"]
        if self.dungeon:
            head.append("dungeon: true")
        head.append("exits: " + ", ".join(self.exits))  # leer bei Innenräumen
        text = "\n".join(head) + "\n---\n" + "\n".join("".join(r) for r in self.g) + "\n---\n" + "\n".join(self.ents) + "\n"
        (OUT / f"{self.id}.room").write_text(text)


def interior(rid, biome, area, floor="h", wall="w", dungeon=False):
    """Kleiner Innenraum: Wände links/rechts, Decke, Boden."""
    r = Room(rid, biome, area, dungeon=dungeon, ground=floor, fill=floor)
    r.box(0, 1, 0, 16, wall).box(28, 29, 0, 16, wall).box(0, W - 1, 0, 1, wall)
    return r


def lamp(r, x):
    """Straßenlaterne mit warmem Schein (nur an sicheren Orten)."""
    r.ent(f"lampe strassenlaterne {x},14")


def weizen(r, x):
    """Weizenbündel auf dem Kornfeld (3 Halme je Ernte)."""
    r.ent(f"sammeln weizen {x},14 anzahl=3")


def villager(r, name, job, x):
    """Dorfbewohner bei der Arbeit, ansprechbar mit [W]."""
    r.ent(f"npc {name} {x},14 arbeit={job} dialog=dorf_{name}")


def dorf():
    """Unterdorf links vom Gildenhaus: Schmieden, Markt, Taverne. Läden noch ohne Betreten."""
    rooms = []
    # Schmiedegasse (grenzt ans Gildenhaus)
    r = Room("dorf_01", "stadt", "kornburg", ground="S", fill="S")
    r.exit("L1", "dorf_02", "R2").exit("R2", "stadt_01", "L1")
    r.ent("gebaeude schmiede 6,14").ent("gebaeude schmiede_waffen 20,14")
    r.ent("door waffen 20,14 to=laden_waffen:aussen")
    villager(r, "geselle", "schmied", 15)
    villager(r, "wache", "wache", 28)
    lamp(r, 12)
    r.ent("dialog dorf_ankunft 26,14")
    rooms.append(r)
    # Marktplatz mit Brunnen
    r = Room("dorf_02", "stadt", "kornburg", ground="S", fill="S")
    r.exit("L1", "dorf_03", "R2").exit("R2", "dorf_01", "L1")
    r.ent("gebaeude brunnen 4,14").ent("gebaeude marktstand 11,14").ent("gebaeude baeckerei 22,14")
    r.ent("door baeckerei 22,14 to=laden_baeckerei:aussen")
    r.ent("npc haendler 8,14 arbeit=haendler dialog=dorf_haendler laden=markt")
    villager(r, "kehrer", "kehrer", 14)
    lamp(r, 1)
    rooms.append(r)
    # Westende: Alchemie und Taverne, dahinter die Stadtmauer
    r = Room("dorf_03", "stadt", "kornburg", ground="S", fill="S")
    r.box(0, 0, 0, 14, "S")
    r.exit("R2", "dorf_02", "L1")
    r.ent("gebaeude laden_alchemie 7,14").ent("gebaeude taverne 19,14")
    r.ent("door alchemie 7,14 to=laden_alchemie:aussen")
    villager(r, "gaertner", "gaertner", 10)
    villager(r, "wirt", "wirt", 23)
    villager(r, "holzfaeller", "holzfaeller", 27)
    lamp(r, 13)
    rooms.append(r)
    rooms += laeden()
    return rooms


def laeden():
    """Betretbare Läden im Unterdorf: Händler hinter dem Tresen oder bei der Arbeit, Tür zurück ins Dorf."""
    rooms = []
    r = interior("laden_baeckerei", "innen_baeckerei", "kornburg")
    r.ent("npc baecker 12,14 arbeit=baecker dialog=dorf_baecker laden=baeckerei")
    r.ent("deco tuer 25,14").ent("door aussen 25,14 to=dorf_02:baeckerei")
    r.ent("lampe haengelaterne 8,5")
    rooms.append(r)
    r = interior("laden_alchemie", "innen_alchemie", "kornburg")
    r.ent("npc veska 19,14 art=veska dialog=laden_veska laden=alchemie")
    r.ent("deco tuer 4,14").ent("door aussen 4,14 to=dorf_03:alchemie")
    r.ent("lampe haengelaterne 12,5").ent("lampe haengelaterne 24,5")
    rooms.append(r)
    r = interior("laden_waffen", "innen_schmiede", "kornburg")
    r.ent("npc borin 13,14 art=borin dialog=dorf_schmied laden=waffen")
    r.ent("deco tuer 4,14").ent("door aussen 4,14 to=dorf_01:waffen")
    r.ent("lampe wandfackel 8,8").ent("lampe wandfackel 18,8")
    rooms.append(r)
    return rooms


def kornburg():
    rooms = []
    # Gildenhalle Kornburg (Innenraum): Start, Schrein, Gildenmeisterin hinter dem Tresen, Kamin
    r = interior("kornburg_gilde", "innen_gilde", "kornburg")
    r.g[14][8] = "@"
    r.ent("deco schrein 5,14").ent("save schrein 5,14 kind=gilde")
    r.ent("auftragsbrett brett 9,14")
    r.ent("npc gildenmeisterin 14,14 dialog=gilde_rat laden=gilde").ent("deco tresen 14,14 front=true")
    r.ent("deco tuer 24,14").ent("door aussen 24,14 to=stadt_01:gilde")
    r.ent("lampe lagerfeuer 21,13").ent("lampe haengelaterne 4,4").ent("lampe haengelaterne 26,4")
    rooms.append(r)
    # Stadt
    r = Room("stadt_01", "stadt", "kornburg", ground="S", fill="S")
    r.box(20, 24, 12, 12, "-")
    r.exit("L1", "dorf_01", "R2").exit("R2", "stadt_02", "L1")
    r.ent("gebaeude gilde_abenteuer 8,14").ent("door gilde 8,14 to=kornburg_gilde:aussen")
    lamp(r, 16)
    r.ent("dialog tut_bewegung 13,14")
    rooms.append(r)
    rooms += dorf()
    r = Room("stadt_02", "stadt", "kornburg", ground="S", fill="S")
    r.box(3, 7, 11, 11, "-")
    r.exit("L1", "stadt_01", "R2").exit("R2", "stadt_03", "L1")
    r.ent("gebaeude cottage 16,14").ent("door karto 16,14 to=kartograf_haus:aussen")
    lamp(r, 25)
    r.ent("dialog tut_karte 10,14")
    rooms.append(r)
    r = interior("kartograf_haus", "innen_haus", "kornburg")
    r.ent("npc kartograf 14,14 area=kornburg price=40")
    r.ent("deco tuer 25,14").ent("door aussen 25,14 to=stadt_02:karto")
    r.ent("lampe haengelaterne 17,5")
    rooms.append(r)
    r = Room("stadt_03", "stadt", "kornburg", ground="S", fill="S")
    r.box(14, 15, 14, 14, "S")
    r.exit("L1", "stadt_02", "R2").exit("R2", "kornfeld_01", "L1")
    lamp(r, 6)
    r.ent("deco zaun 22,14").ent("dialog stadttor 24,14")
    rooms.append(r)
    # Kornfelder (draußen, kalt)
    r = Room("kornfeld_01", "kornfeld", "kornburg")
    r.exit("L1", "stadt_03", "R2").exit("R2", "kornfeld_02", "L1")
    r.ent("deco wegweiser 6,14").ent("dialog tut_schlag 4,14").ent("enemy goblin 18,14 patrol=3")
    weizen(r, 11)
    rooms.append(r)
    r = Room("kornfeld_02", "kornfeld", "kornburg")
    r.box(10, 13, 14, 14, "#").box(10, 13, 13, 13, "=")
    r.box(20, 24, 11, 11, "-")
    r.exit("L1", "kornfeld_01", "R2").exit("R2", "kornfeld_03", "L1")
    r.ent("deco baum 4,14").ent("enemy gruenschleim 6,14 patrol=2").ent("enemy goblin+gruenschleim 25,14 patrol=2")
    weizen(r, 16)
    r.ent("sammeln apfel 20,14 anzahl=2")
    rooms.append(r)
    # Doppelplatten-Rätsel: Tor nur offen, wenn beide Platten belegt sind
    r = Room("kornfeld_03", "kornfeld", "kornburg")
    r.box(22, 23, 0, 10, "#")
    r.g[14][8] = "p"
    r.g[14][16] = "p"
    r.exit("L1", "kornfeld_02", "R2").exit("R2", "kornfeld_04", "L1")
    r.ent("plate a 8,14 opens=tor1").ent("plate b 16,14 opens=tor1").ent("gate tor1 22,14").ent("gate tor1 23,14")
    r.ent("sibling_point b 16,14").ent("dialog tut_befehl 12,14")
    weizen(r, 4)
    rooms.append(r)
    r = Room("kornfeld_04", "kornfeld", "kornburg")
    r.box(8, 11, 12, 12, "-").box(15, 18, 10, 10, "-").box(22, 25, 12, 12, "-")
    r.exit("L1", "kornfeld_03", "R2").exit("R2", "kornfeld_05", "L1")
    r.ent("deco zaun 4,14").ent("enemy skelettkrieger 20,14 patrol=3")
    weizen(r, 12)
    rooms.append(r)
    r = Room("kornfeld_05", "kornfeld", "kornburg")
    r.box(6, 7, 14, 14, "#").box(6, 7, 13, 13, "=").box(18, 19, 14, 14, "#").box(18, 19, 13, 13, "=")
    r.exit("L1", "kornfeld_04", "R2").exit("R2", "muehle_01", "L1")
    r.ent("deco baum 25,14").ent("enemy goblin+goblin 12,14 patrol=3")
    weizen(r, 3)
    weizen(r, 22)
    rooms.append(r)
    # Die verfallene Mühle (außen) – drinnen liegt der tote Abenteurer
    r = Room("muehle_01", "kornfeld", "kornburg")
    r.exit("L1", "kornfeld_05", "R2").exit("R2", "kornfeld_06", "L1")
    r.ent("gebaeude windmuehle 15,14").ent("door muehle 15,14 to=muehle_innen:aussen").ent("dialog muehle_aussen 9,14")
    rooms.append(r)
    r = interior("muehle_innen", "innen_muehle", "kornburg", floor="#", wall="S")
    r.ent("deco tuer 5,14").ent("door aussen 5,14 to=muehle_01:muehle")
    r.ent("deco toter_abenteurer 16,14").ent("npc toter_abenteurer 16,14 dialog=toter_abenteurer art=keine")
    r.ent("pickup plakette 19,14").ent("deco kiste 23,14")
    rooms.append(r)
    # Vorsprung mit dem Kriegshammer: nur mit Federfall erreichbar (4 Kacheln hoch)
    r = Room("kornfeld_06", "kornfeld", "kornburg")
    r.box(20, 25, 11, 11, "=")
    r.exit("L1", "muehle_01", "R2").exit("R2", "kornfeld_07", "L1")
    r.ent("pickup item:rostiger_kriegshammer 23,10").ent("enemy skelettkrieger 10,14 patrol=3")
    weizen(r, 5)
    rooms.append(r)
    r = Room("kornfeld_07", "kornfeld", "kornburg")
    r.box(12, 16, 12, 12, "-")
    r.exit("L1", "kornfeld_06", "R2").exit("R2", "kornfeld_08", "L1")
    r.ent("deco baum 4,14").ent("enemy goblin+goblin+gruenschleim 20,14 patrol=3").ent("enemy skelettkrieger 8,14 patrol=2")
    weizen(r, 25)
    rooms.append(r)
    r = Room("kornfeld_08", "kornfeld", "kornburg")
    # Dungeon-Eingang als Portal: davorstellen und [W] drücken; man kann auch daran vorbeilaufen
    r.exit("L1", "kornfeld_07", "R2").exit("R2", "wald_01", "L1")
    r.ent("dialog dungeon_tor 14,14").ent("door portal 20,14 to=blutdungeon_eingang:portal art=portal farbe=rot")
    r.ent("deco wegweiser 26,14").ent("deco baum 8,14")
    weizen(r, 11)
    rooms.append(r)
    rooms += wald()
    return rooms


def wald():
    """Waldstück rechts vom Portal: Beeren, Pilze, Kräuter; endet an einer Lichtung."""
    rooms = []
    r = Room("wald_01", "wald", "kornburg")
    r.box(8, 11, 11, 11, "-").box(19, 22, 11, 11, "-")
    r.exit("L1", "kornfeld_08", "R2").exit("R2", "wald_02", "L1")
    r.ent("prop tanne 3,14").ent("prop baum 14,14").ent("prop busch 24,14").ent("prop tanne 27,14")
    r.ent("dialog wald_ankunft 4,14")
    r.ent("enemy gruenschleim+gruenschleim 16,14 patrol=3")
    r.ent("sammeln beeren_rot 6,14 anzahl=2").ent("sammeln heilkraut 12,14").ent("sammeln pilz 21,14")
    rooms.append(r)
    r = Room("wald_02", "wald", "kornburg")
    r.box(12, 17, 14, 14, "#").box(12, 17, 13, 13, "=")
    r.box(21, 24, 10, 10, "-")
    r.exit("L1", "wald_01", "R2").exit("R2", "wald_03", "L1")
    r.ent("prop baum 2,14").ent("prop tanne 9,14").ent("prop busch 19,14").ent("prop baum 27,14")
    r.ent("enemy riesenspinne 7,14 patrol=2").ent("enemy goblin+goblin 21,14 patrol=3")
    r.ent("sammeln blaubeeren 4,14 anzahl=2").ent("sammeln heilkraut 14,12").ent("sammeln pilz 25,14")
    rooms.append(r)
    r = Room("wald_03", "wald", "kornburg")
    r.box(29, 29, 0, 14, "#")
    r.exit("L1", "wald_02", "R2")
    r.ent("prop tanne 2,14").ent("prop tanne 6,14").ent("prop busch 16,14").ent("prop baum 27,14")
    r.ent("dialog wald_lichtung 8,14")
    r.ent("enemy riesenspinne+riesenspinne 11,14 patrol=2")
    r.ent("sammeln beeren_rot 14,14 anzahl=2").ent("sammeln leuchtpilz 18,14").ent("sammeln manablume 21,14")
    r.ent("sammeln heilkraut 24,14").ent("pickup silber:40 26,14")
    rooms.append(r)
    return rooms


# ---------------------------------------------------------------- Blut-Dungeon als Labyrinth
# Grundriss aus der Vogelperspektive (x = Osten, y = hinten/Norden). Siehe
# docs/superpowers/specs/2026-11-26-labyrinth-design.md
LAB = {
    "eingang": (0, 0), "ketten": (1, 0), "hinterhalt": (2, 0), "rundweg": (3, 0),
    "stacheln": (0, 1), "kreuzgang": (1, 1), "federfall": (2, 1), "wand": (3, 1),
    "rast": (1, 2), "karte": (2, 2), "bluthalle": (3, 2), "schaedel": (4, 2), "irrweg": (5, 2),
    "vorkammer": (4, 3), "boss": (5, 3),
}
# Seitliche Ausgänge (West → Ost)
LAB_SEITE = [("eingang", "ketten"), ("ketten", "hinterhalt"), ("hinterhalt", "rundweg"),
             ("stacheln", "kreuzgang"), ("kreuzgang", "federfall"), ("federfall", "wand"),
             ("karte", "bluthalle"), ("bluthalle", "schaedel"), ("schaedel", "irrweg"), ("vorkammer", "boss")]
# Öffnungen in der Wand (vorderer Raum, hinterer Raum)
LAB_HINTEN = [("ketten", "kreuzgang"), ("kreuzgang", "rast"), ("rundweg", "wand"),
              ("wand", "bluthalle"), ("schaedel", "vorkammer")]
# Lage der Öffnungen (Spalte, Zeile) je Raum und Richtung
LAB_TUER = {("ketten", "hinten"): (15, 14), ("kreuzgang", "vorne"): (8, 14), ("kreuzgang", "hinten"): (22, 14),
            ("rast", "vorne"): (8, 14), ("rundweg", "hinten"): (20, 14), ("wand", "vorne"): (8, 14),
            ("wand", "hinten"): (24, 10), ("bluthalle", "vorne"): (6, 14), ("schaedel", "hinten"): (15, 14),
            ("vorkammer", "vorne"): (6, 14)}


def lab_id(name):
    return f"blutdungeon_{name}"


def dungeon_room(name):
    if name == "rast":
        return interior(lab_id(name), "innen_kammer", "blutdungeon", floor="S", wall="S", dungeon=True)
    r = Room(lab_id(name), "dungeon_blut", "blutdungeon", dungeon=True, ground="S", fill="B")
    r.box(0, W - 1, 0, 1, "B")
    return r


def lab_features(name, r):
    """Inhalt jedes Raums (Gegner, Belohnungen, Fallen, Deko)."""
    if name == "eingang":
        r.ent("dialog dungeon_eingang 7,14").ent("enemy riesenspinne 20,14 patrol=3").ent("deco kette 12,2")
    elif name == "ketten":
        r.box(9, 12, 12, 12, "-")
        r.ent("enemy ghul 24,14 patrol=2").ent("deco kette 6,2").ent("deco kette 22,2").ent("dialog labyrinth 11,14")
    elif name == "hinterhalt":
        r.ent("deco kiste 15,14").ent("pickup silber:40 15,14")
        r.ent("enemy skelettkrieger+skelett_bogner 21,14 patrol=2").ent("enemy skelettkrieger 9,14 patrol=2")
    elif name == "rundweg":
        r.box(12, 13, 14, 14, "S")
        r.ent("enemy ghul+riesenspinne 6,14 patrol=2")
    elif name == "stacheln":
        for x in (7, 13, 19):
            r.box(x, x + 1, 15, 15, "^")
        r.ent("deco kiste 3,14").ent("pickup plakette 3,14").ent("deco kristall 25,10").ent("light kalt 25,10 radius=24")
    elif name == "kreuzgang":
        r.ent("dialog rastort 17,14").ent("deco kette 14,2")
    elif name == "rast":
        r.ent("deco altar 17,14").ent("save altar 17,14 kind=rastort")
        r.ent("lampe standfackel 12,14").ent("lampe standfackel 22,14")
    elif name == "federfall":
        r.box(14, 18, 13, 13, "-")
        r.ent("pickup federfall 16,12").ent("enemy riesenspinne 24,14 patrol=2")
    elif name == "wand":
        r.box(14, 29, 11, 14, "S")
        r.ent("dialog federfall_wand 11,14")
    elif name == "karte":
        r.box(14, 17, 13, 13, "-")
        r.ent("deco kiste 16,12").ent("pickup map:blutdungeon 16,12")
        r.ent("deco kristall 24,10").ent("light kalt 24,10 radius=24")
    elif name == "bluthalle":
        r.ent("enemy ghul+riesenspinne 18,14 patrol=2").ent("deco kristall 26,10").ent("light kalt 26,10 radius=24")
    elif name == "schaedel":
        r.box(8, 9, 15, 15, "^")
        r.ent("enemy skelett_bogner+skelett_bogner 22,14 patrol=1")
    elif name == "irrweg":
        r.box(10, 11, 15, 15, "^").box(18, 19, 15, 15, "^")
        r.ent("enemy skelett_bogner+skelettkrieger 14,14 patrol=1")
        r.ent("deco kiste 26,14").ent("pickup silber:60 26,14")
    elif name == "vorkammer":
        r.ent("deco kette 12,2").ent("deco kette 20,2").ent("deco kristall 14,10").ent("light kalt 14,10 radius=24")
    elif name == "boss":
        r.ent("dialog boss_intro 8,14").ent("boss blutwolf_alpha 21,14").ent("deco kristall 4,10").ent("light kalt 4,10 radius=32")


def dungeon():
    rooms = {name: dungeon_room(name) for name in LAB}
    rooms["eingang"].ent("door portal 3,14 to=kornfeld_08:portal art=portal farbe=rot")
    for west, east in LAB_SEITE:
        assert LAB[east][0] == LAB[west][0] + 1 and LAB[east][1] == LAB[west][1], (west, east)
        rooms[west].exit("R2", lab_id(east), "L1")
        rooms[east].exit("L1", lab_id(west), "R2")
    for front, back in LAB_HINTEN:
        assert LAB[back] == (LAB[front][0], LAB[front][1] + 1), (front, back)
        for name, here, there, other in ((front, "hinten", back, "vorne"), (back, "vorne", front, "hinten")):
            x, y = LAB_TUER[(name, here)]
            arch = "bogen_warm" if there == "rast" else "bogen"
            rooms[name].ent(f"deco {arch} {x},{y}")
            rooms[name].ent(f"door {here} {x},{y} to={lab_id(there)}:{other} richtung={here}")
    for name, r in rooms.items():
        lab_features(name, r)
    return list(rooms.values())


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for r in kornburg() + dungeon():
        r.write()
    print("Räume erzeugt:", len(kornburg()) + len(dungeon()))


if __name__ == "__main__":
    main()
