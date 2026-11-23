# Grafik-Umbau und Innenräume – Implementation Plan

> Ausführung: superpowers:executing-plans (inline). Checkbox-Schritte.

**Goal:** Neuer Grafikstil (Weg B) mit warmen sicheren Orten, 24×40-Figuren, Türen in den Hintergrund und Innenräumen.
**Spec:** `docs/superpowers/specs/2026-11-23-grafik-umbau-design.md`

## Global Constraints
- Palette: 32 Grundfarben + 6 warme Töne in `game/art/palette.json` (`colors`, `warm`). Warme Töne verboten in
  `art/enemies/*`, `art/tiles.png`, `art/bg/dungeon_*`.
- Figuren-Frames 24×40, Reihen idle(2) lauf(4) sprung(1) schlag(3); Sheets 96×160.
- Tür-Entität: `door <id> x,y to=<raum>:<tür-id>`; jede Tür braucht eine Gegentür, die zurückzeigt.

## Review Focus
1. Tür ohne Gegentür → Test schlägt fehl, nicht das Spiel.
2. [W] an einer Tür während Dialog/Kampf → nichts passiert.
3. Neue Figurengröße bleibt in alten Räumen hängen → Traversal-Test mit 3 Kacheln Kopffreiheit.
4. Speichern im Innenraum, Fortsetzen → Spieler erscheint am Schrein im Innenraum.
5. Geschwister folgt durch die Tür.

### Task G1: Palette + Generator-Grundlagen + Figuren 24×40
- Files: `game/art/palette.json`, `tools/art/*.py` (Generator aufgeteilt), `tools/art/rasters/*.txt`, `tools/test_gen_art.py`,
  `game/world/player.gd`, `game/world/sibling.gd`, `game/world/npc.gd`, `game/battle/battle_scene.gd`
- Tests: `test_warm_colors_only_in_safe_art`, `test_sprite_sizes` (96×160), bestehende Spieler-/Kampftests grün.

### Task G2: Kacheln, Himmel/Mond, Hintergründe (Ebenen), dunklerer Dungeon, Innenraum-Hintergründe
- Files: `tools/art/tiles.py`, `tools/art/backgrounds.py`, `game/world/room_builder.gd` (Ebenen aus `art/bg/<biome>/layer_N.png`)
- Tests: Ebenen-Dateien existieren je Biom (`kornfeld`, `stadt`, `dungeon_blut`, `innen_gilde`, `innen_haus`, `innen_kammer`, `innen_muehle`).

### Task G3: Deko und Licht
- Entitäten `deco <name> x,y` (Sprite aus `art/deco/<name>.png`, Fuß unten mittig) und `light <name> x,y radius=N warm=true|false`
  (Punktraster-Sprite, flackert). Häuser: `gildenhaus`, `kartografhaus`, `muehle`, `laterne`, `baum`, `zaun`, `wegweiser`, `kristall`, `kette`.
- Tests: `test_deco_and_light_entities_build`.

### Task G4: Türen in den Hintergrund
- `game/world/door.gd` (Area2D, [W]-Hinweis), `RoomManager.enter_door(room, door_id)`, Spawn an der Gegentür,
  Geschwister kommt mit; `WorldMap.validate_defs` prüft Türpaare; Karte ignoriert Innenräume.
- Tests: `test_door_pairs_valid`, `test_validate_catches_missing_counter_door`, `test_enter_door_places_player`, `test_door_ignored_while_paused`.

### Task G5: Inhalt umbauen
- Gildenhalle als Innenraum (`kornburg_gilde`, Tür nach `stadt_01`), Kartografen-Haus (`kartograf_haus` aus `stadt_02`),
  Mühle innen (`muehle_innen` aus `muehle_01`), Rast-Kammer (`blutdungeon_rast` aus `blutdungeon_04`),
  geheime Nebenkammer mit Dungeon-Karte (`blutdungeon_kammer` aus `blutdungeon_07`).
- Traversal-Test: 3 Kacheln Kopffreiheit; Räume anpassen.
- Tests: `test_slice_content` grün, `test_safe_rooms_have_warm_light`, Bot-Lauf, Screenshots.

### Task G6: Export prüfen, README-Abschnitt Grafik
