# Vertical Slice „Kornburg & Blut-Dungeon“ Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ein spielbarer, als Windows-ZIP exportierbarer Ausschnitt des Velmora-Metroidvania: Startgebiet bei Kornburg, ein Blut-Dungeon mit Boss, Rundenkampf auf eigenem Kampfplatz, Geschwister-Gefährte, Seelenplaketten-Speichern, Kartenkauf, eine Bewegungsfähigkeit.

**Architecture:** Godot 4.3 (GDScript). Reine Spiellogik (Kampf, Tribut, Mana, Speichern, Karte, Raumformat) liegt in `game/core/` als `RefCounted`-Klassen ohne Szenenbezug und wird headless getestet. Szenen in `game/world/`, `game/battle/`, `game/ui/` verdrahten diese Logik. Räume sind ASCII-Textdateien, die beim Betreten zur Laufzeit in eine TileMapLayer gebaut werden – es ist immer nur ein Raum geladen. Platzhalter-Pixelart erzeugt ein Python-Skript mit fester Palette.

**Tech Stack:** Godot 4.3-stable (Linux-Editor headless für Tests/Export, Windows-Exportvorlage), GDScript, Python 3 + Pillow für Grafik, eigener Mini-Testrunner (kein Addon).

**Spec:** `docs/superpowers/specs/2026-11-23-blutmond-spiel-design.md`

## Global Constraints

- Godot-Version exakt `4.3-stable`; Download `https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip` und `Godot_v4.3-stable_export_templates.tpz`. Binärdateien nie committen (`.gitignore`: `tools/bin/`, `build/`, `.godot/`).
- Interne Auflösung 480 × 270, Fenster 1920 × 1080, `stretch/mode="viewport"`, `scale_mode="integer"`, Texturfilter `Nearest`.
- Kacheln 16 × 16 px, Figuren 16 × 32 px.
- Nur Farben aus `game/art/palette.json` (32 Farben) in allen erzeugten Grafiken; Blutmond-Rot `#a3202b` ist die einzige gesättigte Akzentfarbe, Gold `#d9a441` nur für Licht/Kirche/Beute.
- Alle Spieltexte auf Deutsch. Code-Bezeichner auf Englisch.
- Ränge als Zahlen: D=1, C=2, B=3, A=4, S=5, SS=6 (`Ranks.from_letter`, `Ranks.to_letter`).
- Seelenplaketten: höchstens 5 gesetzt; Speichern nur an Gildenhalle oder Rastort.
- Tod: 10 % Blutsteuer, abgerundet (`gold -= floor(gold * 0.10)`).
- Inhalt ab 18; keine sexuellen Inhalte.
- Spieler wählt Warschick (m) oder Lira (w); die andere Figur ist Gefährte. Beide Halbelfen: Fluss C (Rang 2) und Fluss S (Rang 5).

## Review Focus

1. **Speicherstand fehlt oder ist kaputt** (erste Ausführung, abgebrochene Datei): Spiel startet ohne Absturz mit „Neues Spiel“; ein beschädigter Stand wird gemeldet, nicht geladen. → Test in Task 11.
2. **Tod ohne gesetzte Plakette / Plakette im Dungeon nach Sieg**: Wiedererwachen fällt auf die Gildenhalle Kornburg zurück; nie in einen nicht mehr existierenden Raum. → Test in Task 11.
3. **Kampf, in dem beide Seiten gleichzeitig fallen** (Tribut tötet den letzten Helden im selben Zug, in dem der letzte Gegner stirbt): Sieg zählt, der Held bleibt mit 1 LP stehen. → Test in Task 5.
4. **Mana reicht nicht für den gewählten Zauber**: Zauber ist im Menü ausgegraut und nicht auswählbar, kein negativer Manawert. → Test in Task 4.
5. **Raumübergang in einen Raum ohne passenden Gegenausgang** (Tippfehler in Raumdatei): Validierung schlägt beim Testlauf fehl, nicht erst im Spiel. → Test in Task 13.

---

### Task 1: Projektgerüst, Godot-Werkzeug, Testrunner

**Files:**
- Create: `tools/setup_godot.sh`, `tools/run_tests.sh`, `.gitignore`
- Create: `game/project.godot`, `game/main.tscn`, `game/main.gd`
- Create: `game/tests/test_runner.gd`, `game/tests/test_case.gd`, `game/tests/test_smoke.gd`

**Interfaces:**
- Produces: `TestCase` (`class_name TestCase extends RefCounted`) mit `assert_eq(a, b, msg := "")`, `assert_true(c, msg := "")`, `assert_false(c, msg := "")`, `assert_almost(a: float, b: float, eps := 0.001)`. Runner lädt jede `game/tests/test_*.gd`, ruft jede Methode `test_*` auf einer neuen Instanz, gibt `PASS name`/`FAIL name: msg` aus und beendet mit Code 1 bei Fehlern.
- Produces: `tools/run_tests.sh [filter]` → `tools/bin/godot --headless --path game -s res://tests/test_runner.gd -- <filter>`.

- [ ] **Step 1:** `tools/setup_godot.sh` lädt Editor und Exportvorlagen (URLs siehe Global Constraints) nach `tools/bin/`, entpackt, legt `tools/bin/godot` als Symlink an, installiert Vorlagen nach `~/.local/share/godot/export_templates/4.3.stable/`. Idempotent (überspringt Vorhandenes).
- [ ] **Step 2:** Run `bash tools/setup_godot.sh && tools/bin/godot --version` → Expected: `4.3.stable.official…`
- [ ] **Step 3:** Schreibe `test_smoke.gd` mit `test_math()` (`assert_eq(1 + 1, 2)`) und `test_fails_on_purpose()` (`assert_eq(1, 2)`); schreibe Runner + `TestCase`; `project.godot` mit Constraints (480×270, integer, Nearest, `run/main_scene="res://main.tscn"`, Name „Blutmond“).
- [ ] **Step 4:** Run `tools/run_tests.sh` → Expected: `FAIL test_fails_on_purpose`, Exit-Code 1. Dann den absichtlichen Fehltest löschen, erneut → `PASS test_math`, Exit 0.
- [ ] **Step 5:** Commit `chore: Godot-Projektgerüst und Testrunner`.

### Task 2: Palette und Platzhalter-Grafik

**Files:**
- Create: `game/art/palette.json`, `tools/gen_art.py`, `tools/test_gen_art.py`
- Generated (committed): `game/art/tiles.png`, `game/art/chars/warschick.png`, `game/art/chars/lira.png`, `game/art/enemies/<id>.png`, `game/art/ui/plakette.png`, `game/art/bg/<biome>.png`

**Interfaces:**
- Produces: `tiles.png` als Atlas 16×16, feste Reihenfolge der Kachel-IDs: 0 leer, 1 Erde/Fels, 2 Gras-Oberkante, 3 Holzplattform (one-way), 4 Dungeon-Stein, 5 Blutstein, 6 brüchiger Stein, 7 Stachel (Schaden), 8 Druckplatte, 9 Tor geschlossen, 10 Tor offen, 11 Rastort-Altar, 12 Gildenschild.
- Produces: Figuren-Spritesheets 16×32 pro Frame, Reihen: idle(2), lauf(4), sprung(1), schlag(3). Gegner 32×32 (Boss 64×64), Reihen idle(2), angriff(2).
- Produces: Hintergründe 480×270 für `kornfeld`, `stadt`, `dungeon_blut`.

- [ ] **Step 1:** `palette.json` mit 32 Hex-Farben (kalte Grau-/Moos-/Schieferblau-Töne, `#a3202b`, `#d9a441`). Test `test_all_pixels_in_palette`: jede erzeugte PNG enthält nur Palettenfarben oder volle Transparenz; `test_atlas_size`: `tiles.png` ist 16·13 × 16.
- [ ] **Step 2:** Run `python3 tools/test_gen_art.py` → FAIL (Dateien fehlen).
- [ ] **Step 3:** `gen_art.py` zeichnet mit Pillow prozedural (Formen, Dithering, 1-px-Kontur). Geschwister: gleicher dunkelroter Mantel, spitze Ohren; Warschick breiter mit Kurzschwert, Lira schmaler mit Stab. Blutmond als rote Scheibe in jedem Hintergrund.
- [ ] **Step 4:** Run `python3 tools/gen_art.py && python3 tools/test_gen_art.py` → PASS.
- [ ] **Step 5:** Commit `feat: Palette und Platzhalter-Pixelart`.

### Task 3: Spieldaten und Datenbank

**Files:**
- Create: `game/data/enemies.json`, `game/data/equipment.json`, `game/data/spells.json`, `game/data/heroes.json`
- Create: `game/core/ranks.gd`, `game/core/data_db.gd`, `game/tests/test_data_db.gd`

**Interfaces:**
- Produces: `Ranks` mit `static func from_letter(s: String) -> int`, `static func to_letter(r: int) -> String`.
- Produces: `DataDB` (Autoload `DB`) mit `enemy(id: String) -> Dictionary`, `equipment(id) -> Dictionary`, `spell(id) -> Dictionary`, `hero(id) -> Dictionary`, `validate() -> Array[String]` (Fehlermeldungen; leer = gültig).
- Datenschema Gegner: `{id, name, rank, hp, atk, def, tempo, weak: [String], resist: [String], dmg_type, xp, silver, art}`. Ausrüstung: `{id, name, slot: "waffe"|"ruestung"|"ring", rank, bonus: {atk?, def?, tempo?, mag?}, dmg_type?, tribute?: {type, amount, when: "turn"|"use"}}`. Zauber: `{id, name, elements: [String], tier: 1..4, flow: "C"|"S"|"beide", cost, power, target: "enemy"|"all_enemies"|"ally"}`. Held: `{id, name, hp, atk, def, tempo, mana_c, mana_s, rank_c: 2, rank_s: 5, spells: [ids], weapon, style}`.
- Elemente-Strings: `feuer, eis, wasser, erde, dendro, wind, elektro, schatten, licht`; physische Typen: `schnitt, stumpf, stich`.

Werte (exakt):

| Gegner-ID | Name | Rang | LP | Atk | Def | Tempo | Schwäche | Schadenstyp |
|---|---|---|---|---|---|---|---|---|
| goblin | Goblin | D | 22 | 6 | 2 | 7 | – | schnitt |
| gruenschleim | Grünschleim | D | 18 | 4 | 1 | 3 | feuer | stumpf |
| skelettkrieger | Skelettkrieger | D | 26 | 7 | 4 | 5 | licht, stumpf | schnitt |
| riesenspinne | Riesenspinne | C | 40 | 10 | 4 | 9 | feuer | stich |
| ghul | Ghul | C | 48 | 11 | 5 | 6 | licht | schnitt |
| skelett_bogner | Skelett-Bogenschütze | C | 34 | 12 | 3 | 8 | stumpf | stich |
| blutwolf_alpha | Blutwolf-Alpha (Boss) | B | 160 | 14 | 6 | 10 | feuer | schnitt |

Helden: Warschick `hp 60, atk 9, def 5, tempo 8, mana_c 20, mana_s 40, weapon "kurzschwert", style "glutpirscher"`; Lira `hp 48, atk 6, def 4, tempo 9, mana_c 20, mana_s 60, weapon "eichenstab", style "hydroforelle"`. Startzauber beider: `funke` (feuer, T1, flow C, cost 3, power 8), `frosthauch` (eis, T1, C, 3, 8), `lichtfunke` (licht, T1, C, 3, 8), `heilung` (licht+wasser, T2, beide, cost 6, power 18, ally), `dampfstoss` (feuer+wasser, T2, beide, cost 8, power 16, enemy).
Ausrüstung: `kurzschwert` (D, atk +3, schnitt), `eichenstab` (D, atk +1, mag +3, stumpf), `streitkolben` (C, atk +5, stumpf), `rostiger_kriegshammer` (A, atk +12, stumpf, tribute `{type:"blut", amount:4, when:"turn"}`), `lederharnisch` (D, def +2), `frostkettenhemd` (A, def +8, tribute `{type:"waerme", amount:1, when:"turn"}`), `siegelring_c` (C, mag +2).

- [ ] **Step 1:** Tests: `test_ranks_roundtrip` (alle 6 Buchstaben), `test_enemy_values` (`DB.enemy("ghul").hp == 48`), `test_validate_clean` (`DB.validate().is_empty()`), `test_validate_catches_unknown_element` (DataDB mit manipuliertem Zauber `elements:["lava"]` → genau 1 Fehler).
- [ ] **Step 2:** Run `tools/run_tests.sh data_db` → FAIL.
- [ ] **Step 3:** JSON-Dateien und Klassen anlegen; `validate()` prüft Elemente, Ränge 1–6, Tribut-Typen ∈ `blut, waerme, ausdauer, mana, haut, fleisch, sinne, gift`, Zauber-IDs der Helden existieren.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat: Spieldaten aus der Bibel und DataDB`.

### Task 4: Kampfkern – Kämpfer, Zugfolge, Schaden, Mana

**Files:**
- Create: `game/core/combat/combatant.gd`, `game/core/combat/battle_state.gd`, `game/core/combat/damage.gd`, `game/tests/test_combat_core.gd`

**Interfaces:**
- Consumes: `DB.enemy/hero/equipment/spell`.
- Produces: `Combatant` (`RefCounted`): Felder `id, name, is_hero: bool, hp, max_hp, atk, def, tempo, mag, mana_c, max_mana_c, mana_s, max_mana_s, rank_c, rank_s, weak, resist, dmg_type, statuses: Dictionary, equipment: Array[Dictionary], defending: bool`; `static func from_hero(id) -> Combatant`, `static func from_enemy(id) -> Combatant`, `is_alive() -> bool`, `effective_tempo() -> int`. Helden: `atk/def/tempo/mag` = Grundwert + Summe der `bonus`-Werte der Ausrüstung (Grund-`mag` = 0); Gegner: `mag = atk`.
- Produces: `Damage.compute(attacker: Combatant, target: Combatant, power: int, types: Array[String]) -> int`.
- Produces: `BattleState`: `heroes: Array[Combatant]`, `enemies: Array[Combatant]`, `round: int`, `start(opening: String)` mit `opening ∈ "neutral"|"erstschlag"|"ueberfall"`, `turn_order() -> Array[Combatant]`, `can_cast(c, spell_id) -> bool`, `cast(c, spell_id, target) -> int`, `attack(c, target) -> int`, `defend(c)`.

Regeln (exakt):
- Schaden = `max(1, power + attacker.atk - floor(target.def / 2))`, dann ×1.5 wenn ein Typ in `weak`, ×0.5 wenn in `resist` (beides: ×1.0), dann ×0.5 wenn `target.defending`; Endergebnis `floor`, mindestens 1. Normaler Angriff: `power = 0`, Typen `[attacker.dmg_type]`.
- Zauberschaden nutzt statt `atk` den Wert `mag + rank * 2`, wobei `rank` = Rang des genutzten Flusses (`flow "beide"` → `min(rank_c, rank_s)`). Heilung: `power + mag + rank*2`, gedeckelt bei `max_hp`.
- Kosten: Flow C → `mana_c`, Flow S → `mana_s`, „beide“ → Hälfte (aufgerundet) aus jedem Fluss. `can_cast` ist false, wenn ein betroffener Fluss nicht reicht oder `tier` > (Anzahl Elemente erlaubt durch Rang: Rang 2 → Tier 1 (Ausnahme: Heilung Tier 2), 3 → 2, 4 → 3, 5+ → 4) des genutzten Flusses (bei „beide“ des schwächeren).
- Halbelfen nutzen für Tier-1-Zauber standardmäßig Fluss C (Daten), nie automatisch S.
- Zugfolge pro Runde: nach `effective_tempo()` absteigend, Gleichstand Helden vor Gegnern, dann Listenreihenfolge. Runde 1 bei `erstschlag`: alle Gegner haben Status `betaeubt` (setzen Runde 1 aus). Bei `ueberfall`: in Runde 1 handeln alle Gegner vor allen Helden.

- [ ] **Step 1:** Tests: `test_damage_basic` (Atk 9, Def 4, power 0 → 7), `test_damage_weakness` (Feuer-Funke Lira auf Grünschleim: `power 8 + mag (3 Stab) + 2*2 = 15`, minus `floor(1/2)=0` → 15 ×1.5 = 22), `test_damage_min_one`, `test_defend_halves`, `test_turn_order_tempo_and_ties`, `test_erstschlag_enemies_skip_round1`, `test_ueberfall_enemies_first_round1`, `test_beide_cost_split` (cost 8 → 4/4; cost 5 → 3/3), `test_cannot_cast_without_mana` (mana_c 2, `funke` → false; Mana bleibt ≥ 0), `test_combined_rank_is_min` (Dampfstoß nutzt Rang 2).
- [ ] **Step 2:** Run `tools/run_tests.sh combat_core` → FAIL.
- [ ] **Step 3:** Implementieren nach den Regeln oben.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat: Kampfkern mit zwei Manaflüssen`.

### Task 5: Tribut, Kampfende, Gegner-KI, Belohnung

**Files:**
- Create: `game/core/combat/tribute.gd`, `game/core/combat/enemy_ai.gd`, `game/core/combat/battle_result.gd`
- Modify: `game/core/combat/battle_state.gd`
- Test: `game/tests/test_tribute.gd`, `game/tests/test_battle_flow.gd`

**Interfaces:**
- Produces: `Tribute.apply(c: Combatant, when: String) -> Array[String]` (Log-Zeilen, deutsch); `Tribute.distinct_types(c) -> int`.
- Produces: `EnemyAI.choose(state: BattleState, enemy: Combatant) -> Dictionary` (`{action:"attack", target: Combatant}`), `BattleState.step() -> Array[String]` (führt den nächsten Zug aus; Heldenzüge über `BattleState.submit(action: Dictionary)`), `BattleState.outcome() -> String` (`"laeuft"|"sieg"|"niederlage"`), `BattleResult` `{xp: int, silver: int, drops: Array[String]}`.

Regeln (exakt):
- Tribut „turn“ wird zu Beginn des Zuges des Trägers fällig, „use“ nach jedem Angriff mit der Waffe.
- `blut`: LP −amount. `waerme`: Status `unterkuehlt` +amount Stapel, `effective_tempo` −2 pro Stapel (min 1). `ausdauer`: Atk −amount bis Kampfende. `mana`: `mana_s` −amount (nicht unter 0). `haut`/`fleisch`: `max_hp` −amount bis zur nächsten Rast (Feld `max_hp_penalty`, im Speicherstand). `sinne`: Status `getruebt` (25 % Fehlschlag, deterministischer RNG mit Seed im BattleState). `gift`: Status `vergiftet`, LP −amount pro Zug.
- Zwei-Attribute-Regel: `distinct_types(c) >= 3` → alle Tribut-Beträge dieses Kämpfers ×2.
- Tribut kann einen Helden nicht unter 1 LP bringen, wenn im selben Zug der Kampf als `sieg` endet (Review Focus 3); sonst normal (0 LP = kampfunfähig).
- `sieg`, wenn alle Gegner tot; `niederlage`, wenn alle Helden tot. Belohnung = Summe `xp`/`silver` der Gegner; keine Level-Ups im Slice (XP wird nur gezählt).
- Gegner-KI: greift den Helden mit den niedrigsten aktuellen LP an; Boss `blutwolf_alpha` erhält nach jedem eigenen Treffer +1 Atk („stärker mit jedem Biss“).

- [ ] **Step 1:** Tests: `test_blood_tribute_per_turn` (Kriegshammer: −4 LP bei Zugbeginn), `test_warmth_stacks_reduce_tempo`, `test_three_types_double_cost` (Hammer blut + Kettenhemd waerme + Ausrüstung mit `ausdauer` → Hammer −8), `test_tribute_no_death_on_victory`, `test_victory_rewards`, `test_defeat`, `test_ai_targets_lowest_hp`, `test_boss_gains_attack_per_hit`.
- [ ] **Step 2:** Run `tools/run_tests.sh tribute` und `battle_flow` → FAIL.
- [ ] **Step 3:** Implementieren.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat: Tribut, Kampfablauf und Gegner-KI`.

### Task 6: Kampfplatz-Szene

**Files:**
- Create: `game/battle/battle_scene.tscn`, `game/battle/battle_scene.gd`, `game/battle/battle_menu.gd`, `game/battle/turn_bar.gd`
- Test: `game/tests/test_battle_scene.gd`

**Interfaces:**
- Consumes: `BattleState`, `BattleResult`.
- Produces: `BattleScene.setup(hero_ids: Array[String], enemy_ids: Array[String], opening: String, background: String)`; Signal `battle_finished(outcome: String, result: BattleResult)`; Methode `auto_play_for_test()` (Helden greifen automatisch an).

UI: Hintergrund des Raum-Bioms, Helden links, Gegner rechts (Sprites aus Task 2), oben Zugleiste (nächste 6 Züge als Porträt-Kacheln), unten Menü `Angriff · Technik · Zauber · Gegenstand · Verteidigen · Fliehen` (Fliehen ausgegraut in Dungeons/Boss; Technik im Slice: Stilangriff mit power 6, kostet 0), Zauber-Untermenü zeigt Kosten pro Fluss und graut unbezahlbare aus, LP-Balken + zwei Mana-Balken (C grau-blau, S hell) pro Held, Kampflog (letzte 3 Zeilen). Steuerung: Pfeiltasten/Enter/Esc und Gamepad (`ui_*`-Aktionen).

- [ ] **Step 1:** Test `test_battle_scene_autoplay`: Szene instanziieren, `setup(["warschick","lira"], ["goblin"], "erstschlag", "kornfeld")`, `auto_play_for_test()`, Frames bis Signal (max. 600) → `outcome == "sieg"`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Szene bauen.
- [ ] **Step 4:** Run → PASS. Zusätzlich manuell: `tools/bin/godot --path game res://battle/battle_scene.tscn` startet mit Testaufstellung (Debug-Default in `_ready`, wenn nicht `setup` aufgerufen).
- [ ] **Step 5:** Commit `feat: Kampfplatz mit Menü und Zugleiste`.

### Task 7: Raumformat und Raumbau

**Files:**
- Create: `game/core/world/room_def.gd`, `game/world/room_builder.gd`, `game/data/rooms/README.md`
- Test: `game/tests/test_room_def.gd`

**Interfaces:**
- Produces: `RoomDef.parse(text: String) -> RoomDef` mit Feldern `id, biome, area, size: Vector2i, tiles: PackedInt32Array, exits: Array[Dictionary]` (`{edge:"L"|"R"|"T"|"B", target_room, target_exit_id, id}`), `spawns: Dictionary` (Name → Vector2i), `entities: Array[Dictionary]` (`{type, pos: Vector2i, props: Dictionary}`), `one_way_dungeon: bool`.
- Produces: `RoomBuilder.build(def: RoomDef) -> Node2D` (TileMapLayer mit Kollision aus `tiles.png` + Entitäts-Knoten).

Format `.room` (Kopf `key: value`, dann `---`, dann Gitter, dann `---`, dann Entitäten je Zeile):
```
id: kornfeld_01
biome: kornfeld
area: kornburg
exits: L1=stadt_03:R1, R1=kornfeld_02:L1
---
(Gitter: '.' leer, '#' Erde, '=' Gras, '-' Plattform, 'S' Dungeonstein, 'B' Blutstein, 'x' brüchig, '^' Stachel, 'p' Druckplatte, 'T' Tor, 'A' Rastort, 'G' Gildenschild, '<' '>' '^'-Ausgänge werden über Kopf definiert; '@' Spawn „start“, Ziffer 1–9 = Ausgangsmarker)
---
enemy goblin 12,8 patrol=4
npc kartograf 20,9 area=kornburg price=40
pickup federfall 30,4
pickup plakette 5,3
pickup item:rostiger_kriegshammer 7,9
sibling_point a 10,12
plate a 10,12 opens=tor1
plate b 25,12 opens=tor1
gate tor1 18,10
```
Raumgröße mindestens 30 × 17 Kacheln (480 × 270 px).

- [ ] **Step 1:** Tests: `test_parse_header_and_grid`, `test_parse_exits`, `test_parse_entities_props`, `test_minimum_size_rejected` (Gitter 10×5 → `parse` liefert Fehler über `RoomDef.error != ""`).
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Parser und Builder.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat: Textformat für Räume und Laufzeit-Raumbau`.

### Task 8: Spielfigur und Feldschlag

**Files:**
- Create: `game/world/player.tscn`, `game/world/player.gd`
- Test: `game/tests/test_player.gd`

**Interfaces:**
- Consumes: `GameState.has_ability(name: String) -> bool` (Task 10; bis dahin Stub-Autoload mit Dictionary).
- Produces: `Player` (`CharacterBody2D`) mit Signal `field_strike(area: Area2D)`; Konstanten `SPEED = 90.0`, `JUMP_VELOCITY = -230.0`, `GRAVITY = 600.0`, `DOUBLE_JUMP_VELOCITY = -200.0`, Coyote-Zeit 0.1 s, Sprungpuffer 0.1 s; Feldschlag-Hitbox 18×14 px vor der Figur, 0.25 s aktiv, 0.4 s Abklingzeit.
- Eingaben (InputMap): `links`, `rechts`, `springen` (Leertaste/A), `schlagen` (J/X), `befehl` (K/Y, Geschwister schicken), `karte` (M/Select), `interagieren` (Pfeil hoch/W).

- [ ] **Step 1:** Tests (Figur in leerem Test-Raum mit Boden, simulierte Physik-Frames): `test_single_jump_without_federfall` (zweiter Sprung in der Luft wirkt nicht), `test_double_jump_with_federfall`, `test_strike_hitbox_active_window`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implementieren.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat: Spielfigur mit Federfall und Feldschlag`.

### Task 9: Feldgegner und Kampfstart

**Files:**
- Create: `game/world/field_enemy.tscn`, `game/world/field_enemy.gd`, `game/autoload/battle_launcher.gd`
- Test: `game/tests/test_battle_launch.gd`

**Interfaces:**
- Consumes: `Player.field_strike`, `BattleScene.setup/battle_finished`.
- Produces: `FieldEnemy` mit `enemy_ids: Array[String]` (Gruppe), `patrol: int` (Kacheln), Laufgeschwindigkeit 30 px/s, kehrt an Kanten/Wänden um. `BattleLauncher.start(enemy: FieldEnemy, opening: String)`: speichert Raum-ID + Spielerposition, blendet aus (0.3 s), wechselt zur Kampfszene, nach `sieg` zurück in denselben Raum, Gegner dauerhaft entfernt (Raum-Flag `defeated:<room>:<index>` in GameState); nach `niederlage` → `GameState.on_death()` (Task 11).
- Regel: Treffer durch `field_strike` → `"erstschlag"`; Körperkontakt des Gegners mit dem Spieler → `"ueberfall"`. Nach Rückkehr 1.0 s Unverwundbarkeit.

- [ ] **Step 1:** Tests: `test_strike_starts_erstschlag`, `test_touch_starts_ueberfall`, `test_defeated_enemy_not_respawned` (Raum neu bauen → Gegner fehlt).
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implementieren.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat: Feldgegner und Kampfstart mit Erstschlag`.

### Task 10: GameState, Raumwechsel, Einweg-Dungeon

**Files:**
- Create: `game/autoload/game_state.gd`, `game/autoload/room_manager.gd`
- Test: `game/tests/test_room_manager.gd`

**Interfaces:**
- Produces: `GameState` (Autoload): `hero_id, companion_id, gold: int, xp: int, abilities: Dictionary, flags: Dictionary, inventory: Array[String], equipped: Dictionary` (pro Held), `discovered_rooms: Dictionary`, `owned_maps: Dictionary`, `plaketten: Array[Dictionary]` (Task 11), `has_ability(n) -> bool`, `set_flag(k, v := true)`, `get_flag(k) -> Variant`, `to_dict() -> Dictionary`, `from_dict(d)`.
- Produces: `RoomManager.go_to(room_id: String, exit_id: String)`: altes Raum-Node freigeben, neue `.room`-Datei parsen + bauen, Spieler an Gegenausgang setzen, `discovered_rooms[room_id] = true`.
- Einweg-Schwelle: Räume mit `one_way_dungeon: true` – sobald man aus einem Nicht-Dungeon-Raum hineingeht, wird Flag `dungeon_locked:<area>` gesetzt; Ausgänge zurück in Nicht-Dungeon-Räume sind dann gesperrt (Tor-Kachel), bis Flag `dungeon_cleared:<area>` (Boss besiegt). Wiederbetreten gelöster Dungeons erst mit Fähigkeit `zeitsplitter` (nicht im Slice; Prüfung bereits eingebaut).

- [ ] **Step 1:** Tests: `test_go_to_places_player_at_counter_exit`, `test_discovered_marked`, `test_dungeon_locks_exit`, `test_dungeon_unlocks_after_clear`, `test_cleared_dungeon_closed_without_zeitsplitter`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implementieren.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat: Raumwechsel und Einweg-Schwelle`.

### Task 11: Seelenplaketten, Speichern, Tod

**Files:**
- Create: `game/core/save/plaketten.gd`, `game/core/save/save_system.gd`, `game/world/save_spot.gd`
- Test: `game/tests/test_plaketten.gd`, `game/tests/test_save_system.gd`

**Interfaces:**
- Produces: `Plaketten` (`RefCounted`): `placed: Array[Dictionary]` (`{room, spawn, order}`), `spare: int`, `last_used: int`; `place(room, spawn) -> bool` (braucht `spare > 0` **oder** Ort hat schon eine; bei 5 gesetzten ersetzt die neue die älteste, gibt deren `spare` nicht zurück), `use(room)` setzt `last_used`, `respawn_point() -> Dictionary`, `add_spare()` (max. `placed.size() + spare <= 5`).
- Produces: `SaveSystem.save(state: Dictionary, path := "user://save1.json") -> bool`, `load(path) -> Dictionary` (leer bei fehlend; `{"error": "beschaedigt"}` bei ungültigem JSON oder fehlendem `version`), Feld `version: 1`.
- Produces: `GameState.on_death()`: `gold -= floor(gold * 0.10)`, LP voll, Respawn bei `respawn_point()`; existiert keiner oder ist der Raum ein gelöster/gesperrter Dungeon → Gildenhalle `kornburg_gilde` Spawn `start`.
- Rastort/Gildenhalle (`save_spot.gd`): `interagieren` öffnet Auswahl „Plakette ablegen · Speichern · Rasten“; Rasten füllt LP/Mana, entfernt `max_hp_penalty`; Speichern nur hier möglich.
- Start: 1 Ersatzplakette (die zweite eigene Plakette); weitere nur durch `pickup plakette`.

- [ ] **Step 1:** Tests: `test_place_requires_spare`, `test_max_five_replaces_oldest`, `test_respawn_last_used`, `test_death_tax_floor` (gold 95 → 86), `test_respawn_fallback_guild`, `test_save_load_roundtrip`, `test_missing_save_empty`, `test_corrupt_save_reported`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implementieren.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat: Seelenplaketten, Speichern und Tod`.

### Task 12: Geschwister-Gefährte und Befehle

**Files:**
- Create: `game/world/sibling.tscn`, `game/world/sibling.gd`, `game/world/pressure_plate.gd`, `game/world/gate.gd`
- Test: `game/tests/test_sibling.gd`

**Interfaces:**
- Consumes: `Player`, Entitäten `sibling_point`, `plate`, `gate` aus `RoomDef`.
- Produces: `Sibling` folgt dem Spieler mit 24 px Abstand (springt mit, teleportiert bei > 160 px Abstand oder Raumwechsel neben den Spieler). Taste `befehl` nahe (≤ 48 px) einem `sibling_point` → Geschwister läuft hin und bleibt stehen, bis `befehl` erneut gedrückt wird. `PressurePlate` (aktiv, solange Spieler oder Geschwister darauf steht), `Gate.opens_when: Array[String]` – Tor offen, wenn alle zugehörigen Platten gleichzeitig aktiv sind.
- Flag `solo_mode` in GameState: Geschwister unsichtbar, Befehl ohne Wirkung, Kampf nur mit dem Helden.

- [ ] **Step 1:** Tests: `test_follows_player`, `test_command_sends_to_point`, `test_gate_needs_both_plates`, `test_solo_mode_no_sibling_in_battle`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implementieren.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat: Geschwister folgt und löst Doppel-Platten`.

### Task 13: Karte und Kartograf

**Files:**
- Create: `game/core/world/world_map.gd`, `game/ui/map_view.tscn`, `game/ui/map_view.gd`, `game/world/npc_kartograf.gd`
- Test: `game/tests/test_world_map.gd`

**Interfaces:**
- Produces: `WorldMap.layout(area: String) -> Dictionary` (Raum-ID → `Rect2i` in Karteneinheiten, berechnet per Breitensuche über Ausgänge ab dem ersten Raum der Area; Raumgröße / (30×17) = Karteneinheiten), `WorldMap.validate_all() -> Array[String]` (jeder Ausgang hat einen Gegenausgang, der zurückzeigt; Review Focus 5).
- Sichtbarkeit: ohne `owned_maps[area]` zeigt die Kartenansicht nichts außer „Keine Karte“; mit Karte alle Räume als Umriss, besuchte gefüllt, aktueller Raum mit Marker, gesetzte Plaketten als Symbol.
- Kartograf: Dialog „Karte von <Gebiet> – <price> Silber kaufen?“; Kauf setzt `owned_maps[area]`, zieht Gold ab, ablehnen bei zu wenig Gold. Dungeon-Karte nur zu finden (Pickup `map:<area>`).

- [ ] **Step 1:** Tests: `test_layout_positions`, `test_validate_catches_missing_counter_exit`, `test_validate_all_real_rooms` (alle Dateien in `game/data/rooms/` → leer), `test_buy_map_requires_gold`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implementieren.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat: Karte und Kartograf`.

### Task 14: Inhalt – Kornburg, Blut-Dungeon, Boss, Menüs

**Files:**
- Create: `game/data/rooms/*.room` (Kornburg: `kornburg_gilde`, `stadt_01..03`, `kornfeld_01..08`, `muehle_01`; Dungeon: `blutdungeon_01..09`), `game/data/dialog.json`, `game/ui/title_menu.tscn/.gd`, `game/ui/character_select.tscn/.gd`, `game/ui/dialog_box.tscn/.gd`, `game/ui/hud.tscn/.gd`, `game/world/pickup.gd`
- Modify: `game/main.gd`
- Test: `game/tests/test_slice_content.gd`

**Interfaces:**
- Consumes: alle vorherigen Tasks.
- Produces: Dialogformat `dialog.json`: `{id: [{speaker, text}]}`, Sprecher-Platzhalter `{held}`/`{geschwister}` werden durch die gewählten Namen ersetzt.

Inhalt (exakt):
- Titel: „Blutmond“ · Menü `Neues Spiel · Fortsetzen (ausgegraut ohne Stand) · Beenden`. Figurenwahl zeigt beide Sprites mit Namen; die andere Figur wird Gefährte.
- Intro (Gildenhalle Kornburg): 4–6 Dialogzeilen – der Blutmond endet nicht mehr, der Dämonenkönig wurde gesehen, die Gilde schickt Frischfleisch als Fristhalter; die Geschwister erhalten Eisenplaketten (Rang D).
- Tutorial auf `kornfeld_01–03`: Bewegung, Feldschlag/Erstschlag gegen Goblin, Geschwister-Befehl an einer Doppelplatte (`kornfeld_03`).
- Kartograf in `stadt_02` (Karte Kornburg 40 Silber); Startgold 25 Silber, Goblins/Schleime geben genug für den Kauf nach 3–4 Kämpfen.
- `muehle_01`: verfallene Mühle mit totem Abenteurer → `pickup plakette` + Dialogzeile.
- `kornfeld_06`: Hoher Vorsprung, nur mit Federfall erreichbar; Federfall liegt im Dungeon (`blutdungeon_05`), dahinter `pickup item:rostiger_kriegshammer`.
- Dungeon-Eingang `kornfeld_08` → `blutdungeon_01` (Einweg). Rastort in `blutdungeon_04`. Gegner: Riesenspinne, Ghul, Skelett-Bogenschütze, Skelettkrieger. Dungeon-Karte als Pickup in `blutdungeon_02`.
- Boss `blutdungeon_09`: Blutwolf-Alpha, Intro-Zeile, kein Fliehen; Sieg → `dungeon_cleared:blutdungeon`, Ausgang öffnet, Abschlussdialog „Ein Blut-Dungeon von hundert. Der Mond wird nicht blasser.“ und Hinweis „Ende des Prototyps – frei weiter erkunden.“
- HUD: LP beider Geschwister, Gold, Plaketten (gesetzt/übrig).

- [ ] **Step 1:** Tests: `test_all_rooms_parse` (jede `.room` ohne `error`), `test_world_map_valid` (`validate_all()` leer), `test_federfall_gate_reachable` (Kachel-Reichweitenprüfung: Ziel-Vorsprung in `kornfeld_06` ist mit Sprunghöhe 3 Kacheln nicht, mit 5 Kacheln erreichbar – einfache BFS über begehbare Kacheln mit maximaler Sprunghöhe), `test_dialog_placeholders`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Räume, Dialoge, Menüs, HUD bauen; `main.gd` startet Titelmenü.
- [ ] **Step 4:** Run alle Tests → PASS. Manuell: komplettes Durchspielen headful (Start → Karte kaufen → Plakette finden → Dungeon → Boss → Ende) und Bericht der Spielzeit.
- [ ] **Step 5:** Commit `feat: Inhalt des Vertical Slice`.

### Task 15: Windows-Export und Release-Paket

**Files:**
- Create: `game/export_presets.cfg`, `tools/build_windows.sh`, `README.md` (ersetzen: Beschreibung, Steuerung, Download, Bauen)

**Interfaces:**
- Produces: `tools/build_windows.sh` → `build/Blutmond-windows.zip` mit `Blutmond.exe` + `Blutmond.pck`.

- [ ] **Step 1:** Exportvorlage „Windows Desktop“, `binary_format/embed_pck=false`, Produktname „Blutmond“, Icon aus `game/art/ui/plakette.png`.
- [ ] **Step 2:** Run `tools/run_tests.sh && bash tools/build_windows.sh && unzip -l build/Blutmond-windows.zip` → Expected: Tests PASS, ZIP enthält `Blutmond.exe` und `Blutmond.pck`.
- [ ] **Step 3:** README mit Steuerung (Tastatur + Gamepad), Hinweis „ab 18“, Download-Link auf GitHub Releases, Bauanleitung.
- [ ] **Step 4:** Commit `build: Windows-Export und README`. Release auf GitHub anlegen erst nach Rückfrage beim Team.
