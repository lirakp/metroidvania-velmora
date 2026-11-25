# Grafik-Umbau und Innenräume – Design (kurz)

Stand: 2026-11-23 · Ergänzt `2026-11-23-blutmond-spiel-design.md`. Vom Team freigegeben nach drei Probeszenen.

## Absicht
Die Welt bleibt düster, wirkt aber detaillierter und an **sicheren Orten** wärmer. Nach gruseligen Szenen
sollen warme, kleine Innenräume (Gildenhalle, Häuser, Rast-Kammern) Erholung bieten. **[Team]**

## Entscheidungen
- **Farben:** Grundpalette bleibt (32 Farben, düster). Neu: 6 warme Lichttöne (#3d2a22, #6b3b24, #b5622b,
  #e39b3c, #f6cf6b, #fff0c2) – **nur** an sicheren Orten (Innenräume, Laternen, Fenster, Kerzen am Rastort).
  Dungeons dunkler als bisher, nur kaltes Rot. **[Team]**
- **Weg B:** Landschaft, Himmel, Böden, Licht per Skript; Figuren, Häuser und Gegenstände als Pixel-Textraster. **[Team]**
- **Maßstab:** Figuren 24 × 40 Pixel, knapp kleiner als Haustüren (46 px). Häuser rund doppelt so groß wie bisher. **[Team]**
- **Mond:** klare Scheibe mit Schattenseite und Kratern, kein Rauschen. **[Team]**
- **Türen in den Hintergrund (wie Hollow Knight):** An Öffnungen in Wänden oder Haustüren drückt man [W]/↑ und betritt
  einen eigenen Raum dahinter. Genutzt für Häuser, sichere Orte und Nebenkammern in Dungeons (macht Dungeons
  verwinkelter). **[Team]**
- **Sichere Orte als eigene kleine Räume:** Gildenhalle Kornburg, Haus des Kartografen, Rast-Kammer im Dungeon. **[Team]**

## Meine Entscheidungen (korrigierbar)
- Lichtschein als feines Punktraster in warmen Tönen, leicht flackernd; Dungeon-Kristalle mit kaltem rotem Schein.
- Hintergründe als Ebenen (Parallax), damit breitere Räume später mitscrollen.
- Spielfigur-Kollision 12 × 36 px; Durchgänge brauchen 3 Kacheln Kopffreiheit.
- Gegner behalten vorerst ihre Größe (32 px, Boss 64 px) und werden nur nachgezeichnet, wo es nötig ist.
- Innenräume erscheinen nicht als eigene Felder auf der Karte; die Karte zeigt die Außenräume.
- Die verfallene Mühle bekommt einen kalten Innenraum (toter Abenteurer) – kein sicherer Ort, daher ohne warmes Licht.

## Approaches
A: alles per Skript (schnell, gröber) · **B: Mischung Skript + Pixel-Textraster (gewählt)** · Bild-KI verworfen
(unsauberes Raster, uneinheitlich, Lizenz unklar).
