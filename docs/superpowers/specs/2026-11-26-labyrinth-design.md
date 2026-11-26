# Blut-Dungeon als Labyrinth – Design

Stand: 2026-11-26 · vom Team freigegeben („B, Karte aus der Vogelperspektive, kannst starten“).

## Absicht
Der Blut-Dungeon war ein gerader Gang mit 9 Räumen. Er soll ein **Labyrinth** werden: Der Weg wechselt zwischen
„geradeaus“ (seitliche Ausgänge) und „nach hinten/vorne“ (Öffnungen in der Wand, Türen in den Hintergrund).
Es gibt **Irrwege mit Belohnungen oder Fallen**, einen **Rundweg** und die **Dungeon-Karte** wird wertvoll. **[Team]**

## Entscheidungen
- **Labyrinth mit Irrwegen (B).** **[Team]**
- **Karte aus der Vogelperspektive:** links/rechts = Westen/Osten, „nach hinten durch die Wand“ = oben (Norden). **[Team]**
- **Bauweise: Grundriss als Textraster** im Raumgenerator; daraus entstehen Räume, Ausgänge, Türen samt Gegentüren
  und die Kartenposition. **[mein Vorschlag, vom Team angenommen]**
- Stachel-Fix (PR #5) wird mit diesem Release zusammen veröffentlicht. **[Team]**

## Grundriss (Vogelperspektive, Norden = hinten)

```
          x0       x1       x2       x3       x4       x5
 y3                                           [VK]═════[BOSS]
                                               ║
 y2                [RAST]   [KARTE]══[BLUT]══[SCHÄD]═══[IRRWEG]
                     ║                 ║
 y1      [STACH]══[KREUZ]══[FEDER]══[WAND]
                     ║                 ║
 y0  →  [EING]═══[KETTEN]══[HINTER]══[RUND]
```
`═` seitlicher Ausgang · `║` Öffnung in der Wand (nach hinten/vorne) · `→` Eingang von kornfeld_08

| Raum | Rolle |
|---|---|
| EING (Eingang) | Einweg-Schwelle, Spinne |
| KETTEN | Ghul; Öffnung nach hinten zum Kreuzgang |
| HINTER (Hinterhalt) | Truhe mit 40 Silber, bewacht von Skeletten |
| RUND (Rundweg) | Abkürzung: Öffnung nach hinten unten in die Federfall-Wand |
| STACH (Stachelgang) | Irrweg: Stachelgruben, am Ende eine Seelenplakette |
| KREUZ (Kreuzgang) | Knotenpunkt; Öffnung nach hinten zur Rast-Kammer (warmes Licht) |
| RAST | Rast-Kammer (sicherer Ort, Speichern) |
| FEDER | Federfall liegt hier |
| WAND (Federfall-Wand) | 4 Kacheln hohe Wand; die Öffnung nach hinten liegt oben – nur mit Federfall |
| KARTE | Sackgasse: Dungeon-Karte in einer Truhe |
| BLUT (Bluthalle) | Ghul + Spinne |
| SCHÄD (Schädelgang) | Skelett-Bogenschützen; Öffnung nach hinten zur Vorkammer |
| IRRWEG | Sackgasse: Stacheln + Bogenschützen, Truhe mit 60 Silber |
| VK (Vorkammer) | letzte Ruhe vor dem Boss |
| BOSS | Blutwolf-Alpha |

**Wege:** EING → KETTEN → (hinten) KREUZ → FEDER → WAND → (oben, hinten) BLUT → SCHÄD → (hinten) VK → BOSS.
Rundweg: KETTEN → HINTER → RUND → (hinten) WAND unten. Ohne Federfall kommt man in WAND nicht nach hinten.

## Meine Entscheidungen (korrigierbar)
- Türen nach hinten und vorne sehen gleich aus (Öffnung in der Wand); die Karte zeigt die Richtung.
- Neue Belohnung „Silber in einer Truhe“ (Pickup `silber:<menge>`).
- Haus-Innenräume in Kornburg bleiben von der Karte ausgenommen (Türen ohne Richtung); nur Dungeon-Türen mit
  Richtung werden auf der Karte gezeichnet.
- Raum-IDs sprechend: `blutdungeon_eingang`, `blutdungeon_ketten`, … (Rast-Kammer behält `blutdungeon_rast`).
- Jeder Raum bleibt ein Bildschirm (30 × 17 Kacheln).
