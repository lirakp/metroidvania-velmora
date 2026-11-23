# Raumformat (`.room`)

Jeder Raum ist eine Textdatei. Beim Betreten wird nur dieser Raum geladen.

```
id: kornfeld_01          # muss dem Dateinamen entsprechen
biome: kornfeld           # Hintergrund: kornfeld | stadt | dungeon_blut
area: kornburg            # Gebiet für die Karte
dungeon: true             # optional: Einweg-Dungeon
exits: L1=stadt_03:R2, R2=kornfeld_02:L1
---
(Gitter, mindestens 30 × 17 Zeichen, alle Zeilen gleich lang)
---
(Entitäten, eine pro Zeile: typ id x,y schluessel=wert ...)
```

Gitterzeichen: `.` leer · `#` Erde · `=` Gras · `-` Holzplattform (von unten durchspringbar) · `S` Dungeonstein ·
`B` Blutstein · `x` brüchiger Stein · `^` Stacheln · `p` Druckplatte · `T` Tor · `A` Rastort · `G` Gildenschild ·
`@` Startpunkt · `1`–`9` Ausgangsmarker.

Ausgänge: `<Kante><Ziffer>=<Zielraum>:<Zielausgang>`. Kante `L`/`R`/`T`/`B`, die Ziffer steht im Gitter an der Stelle des
Durchgangs und muss pro Raum eindeutig sein. Jeder Ausgang braucht im Zielraum einen Gegenausgang, der zurückzeigt.

Entitäten: `enemy <gegner-id[+gegner-id]> x,y patrol=4` · `npc kartograf x,y area=kornburg price=40` ·
`pickup federfall|plakette|item:<id>|map:<area> x,y` · `sibling_point <name> x,y` · `plate <name> x,y opens=<tor>` ·
`gate <name> x,y` · `save x,y kind=gilde|rastort` · `boss <gegner-id> x,y` · `dialog <dialog-id> x,y` · `npc <id> x,y dialog=<id>`.
