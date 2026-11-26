"""Übernimmt die benötigten Grafiken unverändert aus dem Grafik-Repo lirakp/aniamtion.

Aufruf: python3 tools/import_cosy.py [Pfad zum Grafik-Repo]   (Standard: ../aniamtion)
Ziel: game/art/cosy/<gleicher relativer Pfad>. Gegner werden nur kopiert, wenn game/data/enemies.json sie nutzt.
"""
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "aniamtion"
DST = ROOT / "game" / "art" / "cosy"

DORF_TUEREN = ["baeckerei", "taverne", "schmiede_waffen", "schmiede_ruestung", "laden_alchemie",
               "laden_ruestung_waffen", "laden_dungeon", "kirche"]
DORF_GEBAEUDE = DORF_TUEREN + ["schmiede", "marktstand", "brunnen", "scheune"]
DORF_ARBEIT = ["schmied", "baecker", "holzfaeller", "bauer", "kehrer", "wirt", "fischer", "haendler", "wache", "gaertner"]

SAMMELN = ["weizen", "apfel", "beeren_rot", "blaubeeren", "pilz", "leuchtpilz", "heilkraut", "manablume"]

FILES = [
    # Spielfigur und Figuren (48er Zellen, 17 Animationen)
    "characters/held/held.json", "characters/held/elf_tunika.png", "characters/held/elf_ruestung.png",
    "characters/held/mensch_tunika.png", "characters/held/mensch_ruestung.png", "characters/held/zwerg_tunika.png",
    "characters/held/zwerg_ruestung.png", "characters/held/eule_tunika.png",
    # Gegner-Metadaten (Bilder siehe unten)
    "monster/sprites/monster.json",
    # Gebäude bei Nacht + Türen
    "buildings/gilde_abenteuer_nacht.png", "buildings/cottage_nacht.png", "buildings/windmuehle_nacht.png",
    "buildings/doors/tueren.json", "buildings/doors/gilde_abenteuer_nacht_tuer_overlay.png",
    "buildings/doors/cottage_nacht_tuer_overlay.png", "buildings/doors/windmuehle_nacht_tuer_overlay.png",
    # Dorf: Läden, Schmieden, Taverne, Markt (Nacht) + Türen, arbeitende Dorfbewohner
    *[f"buildings/{b}_nacht.png" for b in DORF_GEBAEUDE],
    *[f"buildings/doors/{b}_nacht_tuer_overlay.png" for b in DORF_TUEREN],
    "characters/arbeit/arbeit.json", *[f"characters/arbeit/{j}.png" for j in DORF_ARBEIT],
    # Gegenstands-Icons und Sammelstellen (Ernte-/Nachwachs-Animation)
    "icons/icons.json", *[f"icons/{g}.png" for g in ("essen_kraeuter", "traenke", "beute", "waffen", "ruestung")],
    "welt/welt.json", "welt/dorf/gildenbrett.png",
    "props/baum_nacht.png", "props/tanne_nacht.png", "props/busch_nacht.png",
    "welt/sammeln/sammeln.json", "welt/sammeln/icons_sammeln.png",
    *[f"welt/sammeln/{a}.png" for a in SAMMELN],
    # Licht
    "objects/licht/licht.json", "objects/licht/strassenlaterne_anim.png", "objects/licht/strassenlaterne_lichtkreis.png",
    "objects/licht/wandfackel_anim.png", "objects/licht/wandfackel_lichtkreis.png",
    "objects/licht/standfackel_anim.png", "objects/licht/standfackel_lichtkreis.png",
    "objects/licht/lagerfeuer_anim.png", "objects/licht/lagerfeuer_lichtkreis.png",
    "objects/licht/haengelaterne_anim.png", "objects/licht/haengelaterne_lichtkreis.png",
    # Portal (Dungeon-Eingänge)
    "objects/portal/portal.json", "objects/portal/portal_rot.png", "objects/portal/portal_violett.png",
    "objects/portal/portal_blau.png", "objects/portal/portal_gruen.png",
    # Level
    "level/level.json", "level/terrain_wiese.png", "level/terrain_dungeon_blut.png", "level/terrain_fels.png",
    "level/rueckwand_dungeon_blut.png", "level/plattformen.png", "level/stacheln.png", "level/leiter.png",
    "level/parallax/dorf_nacht_0_himmel.png", "level/parallax/dorf_nacht_1_berge.png",
    "level/parallax/dorf_nacht_2_huegel.png", "level/parallax/dorf_nacht_3_wald.png",
    "level/parallax/dungeon_blut_0_hintergrund.png", "level/parallax/dungeon_blut_1_boegen.png",
    "level/parallax/dungeon_blut_2_saeulen.png",
    # Oberfläche und Porträts
    "ui/ui.json", "ui/rahmen_holz.png", "ui/rahmen_dungeon.png", "ui/rahmen_pergament.png", "ui/dialog_weiter.png",
    "ui/auswahlrahmen.png", "ui/zeiger.png", "ui/knopf.png", "ui/schrift_3x5.png",
    "ui/banner_besiegt.png", "ui/banner_dungeon_geloest.png", "ui/banner_auftrag_erledigt.png",
    "ui/zahlen_normal.png", "ui/zahlen_kritisch.png", "ui/zahlen_heilung.png", "ui/zahlen_mana.png",
    "portraits/portraits.json", "portraits/elf_tunika.png", "portraits/elf_ruestung.png",
    "portraits/mensch_tunika.png", "portraits/zwerg_tunika.png",
]


def copy(rel):
    src, dst = SRC / rel, DST / rel
    if not src.exists():
        raise SystemExit(f"Fehlt im Grafik-Repo: {rel}")
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def main():
    if not SRC.exists():
        raise SystemExit(f"Grafik-Repo nicht gefunden: {SRC}")
    for rel in FILES:
        copy(rel)
    monsters = json.loads((SRC / "monster/sprites/monster.json").read_text())
    enemies = json.loads((ROOT / "game/data/enemies.json").read_text())
    for e in enemies:
        m = monsters[e["cosy"]]
        copy("monster/sprites/" + m["datei"])
    print(f"{len(FILES)} Dateien + {len(enemies)} Gegner übernommen nach {DST.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
