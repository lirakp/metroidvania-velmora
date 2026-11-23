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
    r.ent(f"deco laterne {x},14").ent(f"light warm {x},12 radius=24")


def kornburg():
    rooms = []
    # Gildenhalle Kornburg (Innenraum): Start, Schrein, Gildenmeisterin hinter dem Tresen, Kamin
    r = interior("kornburg_gilde", "innen_gilde", "kornburg")
    r.g[14][8] = "@"
    r.ent("deco schrein 5,14").ent("save schrein 5,14 kind=gilde")
    r.ent("npc gildenmeisterin 14,14 dialog=gilde_rat").ent("deco tresen 14,14 front=true")
    r.ent("deco tuer 24,14").ent("door aussen 24,14 to=stadt_01:gilde")
    r.ent("light warm 21,13 radius=32")
    rooms.append(r)
    # Stadt
    r = Room("stadt_01", "stadt", "kornburg", ground="S", fill="S")
    r.box(0, 0, 0, 14, "S")
    r.box(20, 24, 12, 12, "-")
    r.exit("R2", "stadt_02", "L1")
    r.ent("deco gildenhaus 8,14").ent("door gilde 8,14 to=kornburg_gilde:aussen")
    lamp(r, 16)
    r.ent("dialog tut_bewegung 13,14")
    rooms.append(r)
    r = Room("stadt_02", "stadt", "kornburg", ground="S", fill="S")
    r.box(3, 7, 11, 11, "-")
    r.exit("L1", "stadt_01", "R2").exit("R2", "stadt_03", "L1")
    r.ent("deco kartografhaus 16,14").ent("door karto 16,14 to=kartograf_haus:aussen")
    lamp(r, 25)
    r.ent("dialog tut_karte 10,14")
    rooms.append(r)
    r = interior("kartograf_haus", "innen_haus", "kornburg")
    r.ent("npc kartograf 14,14 area=kornburg price=40")
    r.ent("deco tuer 25,14").ent("door aussen 25,14 to=stadt_02:karto")
    r.ent("light warm 17,9 radius=16")
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
    rooms.append(r)
    r = Room("kornfeld_02", "kornfeld", "kornburg")
    r.box(10, 13, 14, 14, "#").box(10, 13, 13, 13, "=")
    r.box(20, 24, 11, 11, "-")
    r.exit("L1", "kornfeld_01", "R2").exit("R2", "kornfeld_03", "L1")
    r.ent("deco baum 4,14").ent("enemy gruenschleim 6,14 patrol=2").ent("enemy goblin+gruenschleim 25,14 patrol=2")
    rooms.append(r)
    # Doppelplatten-Rätsel: Tor nur offen, wenn beide Platten belegt sind
    r = Room("kornfeld_03", "kornfeld", "kornburg")
    r.box(22, 23, 0, 10, "#")
    r.g[14][8] = "p"
    r.g[14][16] = "p"
    r.exit("L1", "kornfeld_02", "R2").exit("R2", "kornfeld_04", "L1")
    r.ent("plate a 8,14 opens=tor1").ent("plate b 16,14 opens=tor1").ent("gate tor1 22,14").ent("gate tor1 23,14")
    r.ent("sibling_point b 16,14").ent("dialog tut_befehl 12,14")
    rooms.append(r)
    r = Room("kornfeld_04", "kornfeld", "kornburg")
    r.box(8, 11, 12, 12, "-").box(15, 18, 10, 10, "-").box(22, 25, 12, 12, "-")
    r.exit("L1", "kornfeld_03", "R2").exit("R2", "kornfeld_05", "L1")
    r.ent("deco zaun 4,14").ent("enemy skelettkrieger 20,14 patrol=3")
    rooms.append(r)
    r = Room("kornfeld_05", "kornfeld", "kornburg")
    r.box(6, 7, 14, 14, "#").box(6, 7, 13, 13, "=").box(18, 19, 14, 14, "#").box(18, 19, 13, 13, "=")
    r.exit("L1", "kornfeld_04", "R2").exit("R2", "muehle_01", "L1")
    r.ent("deco baum 25,14").ent("enemy goblin+goblin 12,14 patrol=3")
    rooms.append(r)
    # Die verfallene Mühle (außen) – drinnen liegt der tote Abenteurer
    r = Room("muehle_01", "kornfeld", "kornburg")
    r.exit("L1", "kornfeld_05", "R2").exit("R2", "kornfeld_06", "L1")
    r.ent("deco muehle 15,14").ent("door muehle 15,14 to=muehle_innen:aussen").ent("dialog muehle_aussen 9,14")
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
    rooms.append(r)
    r = Room("kornfeld_07", "kornfeld", "kornburg")
    r.box(12, 16, 12, 12, "-")
    r.exit("L1", "kornfeld_06", "R2").exit("R2", "kornfeld_08", "L1")
    r.ent("deco baum 4,14").ent("enemy goblin+goblin+gruenschleim 20,14 patrol=3").ent("enemy skelettkrieger 8,14 patrol=2")
    rooms.append(r)
    r = Room("kornfeld_08", "kornfeld", "kornburg")
    r.box(25, 29, 0, 11, "B")
    r.exit("L1", "kornfeld_07", "R2").exit("R2", "blutdungeon_01", "L1")
    r.ent("dialog dungeon_tor 20,14").ent("deco kristall 26,11").ent("light kalt 26,10 radius=24")
    rooms.append(r)
    return rooms


def dungeon():
    rooms = []

    def d(n):
        r = Room(f"blutdungeon_0{n}", "dungeon_blut", "blutdungeon", dungeon=True, ground="S", fill="B")
        r.box(0, W - 1, 0, 1, "B")
        return r

    r = d(1)
    r.exit("L1", "kornfeld_08", "R2").exit("R2", "blutdungeon_02", "L1")
    r.ent("dialog dungeon_eingang 3,14").ent("enemy riesenspinne 20,14 patrol=3").ent("deco kette 12,2")
    rooms.append(r)
    r = d(2)
    r.box(9, 13, 12, 12, "-").box(17, 20, 10, 10, "-")
    r.exit("L1", "blutdungeon_01", "R2").exit("R2", "blutdungeon_03", "L1")
    r.ent("enemy ghul 24,14 patrol=2").ent("deco kristall 15,8").ent("light kalt 15,7 radius=24")
    rooms.append(r)
    r = d(3)
    r.box(12, 13, 14, 14, "S")
    r.exit("L1", "blutdungeon_02", "R2").exit("R2", "blutdungeon_04", "L1")
    r.ent("enemy skelett_bogner+skelettkrieger 20,14 patrol=2").ent("enemy skelettkrieger 7,14 patrol=2")
    rooms.append(r)
    # Öffnung in der Wand: dahinter die Rast-Kammer (einziger warmer Ort im Dungeon)
    r = d(4)
    r.exit("L1", "blutdungeon_03", "R2").exit("R2", "blutdungeon_05", "L1")
    r.ent("deco bogen_warm 15,14").ent("door rast 15,14 to=blutdungeon_rast:gang").ent("dialog rastort 10,14")
    rooms.append(r)
    r = interior("blutdungeon_rast", "innen_kammer", "blutdungeon", floor="S", wall="S", dungeon=True)
    r.ent("deco bogen 8,14").ent("door gang 8,14 to=blutdungeon_04:rast")
    r.ent("deco altar 17,14").ent("save altar 17,14 kind=rastort").ent("light warm 17,13 radius=48")
    rooms.append(r)
    r = d(5)
    r.box(14, 18, 13, 13, "-")
    r.exit("L1", "blutdungeon_04", "R2").exit("R2", "blutdungeon_06", "L1")
    r.ent("pickup federfall 16,12").ent("enemy riesenspinne 24,14 patrol=2")
    rooms.append(r)
    # Wand von 4 Kacheln: nur mit Federfall weiter
    r = d(6)
    r.box(14, 29, 11, 14, "S")
    r.exit("L1", "blutdungeon_05", "R2").exit("R2", "blutdungeon_07", "L1", y=10)
    r.ent("dialog federfall_wand 8,14")
    rooms.append(r)
    r = d(7)
    r.box(0, 3, 11, 14, "S").box(10, 14, 12, 12, "-")
    r.exit("L1", "blutdungeon_06", "R2", y=10).exit("R2", "blutdungeon_08", "L1")
    r.ent("enemy ghul+riesenspinne 18,14 patrol=2").ent("deco bogen 25,14").ent("door kammer 25,14 to=blutdungeon_kammer:gang")
    rooms.append(r)
    # Geheime Nebenkammer mit der Dungeon-Karte (kalt)
    r = interior("blutdungeon_kammer", "dungeon_blut", "blutdungeon", floor="S", wall="B", dungeon=True)
    r.box(14, 17, 11, 11, "-")
    r.ent("deco bogen 6,14").ent("door gang 6,14 to=blutdungeon_07:kammer")
    r.ent("deco kiste 16,10").ent("pickup map:blutdungeon 16,10").ent("deco kristall 24,10").ent("light kalt 24,9 radius=24")
    rooms.append(r)
    r = d(8)
    r.box(10, 11, 15, 15, "^").box(20, 21, 15, 15, "^").box(14, 17, 12, 12, "-")
    r.exit("L1", "blutdungeon_07", "R2").exit("R2", "blutdungeon_09", "L1")
    r.ent("enemy skelett_bogner+skelett_bogner 26,14 patrol=1").ent("deco kette 16,2")
    rooms.append(r)
    r = d(9)
    r.exit("L1", "blutdungeon_08", "R2")
    r.ent("dialog boss_intro 8,14").ent("boss blutwolf_alpha 21,14").ent("deco kristall 4,10").ent("light kalt 4,9 radius=32")
    rooms.append(r)
    return rooms


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for r in kornburg() + dungeon():
        r.write()
    print("Räume erzeugt:", len(kornburg()) + len(dungeon()))


if __name__ == "__main__":
    main()
