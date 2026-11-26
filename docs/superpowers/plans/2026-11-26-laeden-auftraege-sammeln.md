# Läden, Auftragsbrett, Waldstück und Sammeln – Umsetzungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kreislauf außerhalb der Dungeons: sammeln und kämpfen → Aufträge oder Verkauf → Silber → Vorräte und Ausrüstung.

**Architecture:** Reine Logik (Vorrat, Läden, Aufträge, Rasten) liegt in testbaren Klassen unter `game/core/economy/` und in
`GameState`; die Welt-Knoten (Sammelstelle, Auftragsbrett, Ladenfenster) rufen nur diese Logik auf. Daten in JSON unter
`game/data/`. Räume entstehen in `tools/gen_rooms.py`, Grafik über `tools/import_cosy.py`.

**Tech Stack:** Godot 4.3 / GDScript, eigener Testrunner (`tools/run_tests.sh [filter]`), Python-Generatoren.

**Spec:** `docs/superpowers/specs/2026-11-26-laeden-auftraege-sammeln-design.md`

## Global Constraints

- Direkt auf `main` committen und pushen; vor jedem Push `tools/run_tests.sh` grün.
- Spieltexte Deutsch, Code-Bezeichner Englisch (Daten-IDs dürfen deutsch sein wie bisher: `weizen`, `heil_klein`).
- Räume nur über `tools/gen_rooms.py` ändern, danach `python3 tools/gen_rooms.py`.
- Grafik aus `../aniamtion` unverändert über `tools/import_cosy.py`; Fehlendes selbst in `tools/art/` zeichnen.
- Währung Silber; nichts ab Rang A in Läden; kein Gegengift in diesem Schritt.
- Spielstand: neue Felder mit Vorgabe, alte Stände laden weiter (SaveSystem Version bleibt 1).

## Review Focus

1. Verkaufen der letzten Einheit / Kaufen ohne genug Silber: Bestand und Silber werden nie negativ, Meldung statt Fehler.
2. Ausrüstung, die gerade angelegt ist, darf nicht verkauft werden (sonst zeigt `equipped` ins Leere).
3. Rasten im Dungeon-Rastort darf Dungeon-Gegner und Bosse nicht zurückbringen.
4. Alter Spielstand ohne `items`/`quests`: lädt, Brett würfelt beim ersten Öffnen Angebote.
5. Ernten während ein Dialog/Menü offen ist (Pause) oder zweimal schnell [W]: genau eine Ernte.

---

### Task 1: Vorrat und Gegenstandsdaten

**Files:**
- Create: `game/data/items.json`, `game/tests/test_items.gd`
- Modify: `game/core/data_db.gd`, `game/autoload/game_state.gd`

**Interfaces:**
- Produces: `DB.item(id: String) -> Dictionary` mit Feldern `id, name, icon, sell, buy (0 = nicht käuflich), effect ({} oder {"hp": n} / {"mana": n}), battle_only: bool`.
  `DB.items: Dictionary`.
  `GameState.items: Dictionary` (id → int), `GameState.add_item(id: String, n := 1) -> void`,
  `GameState.remove_item(id: String, n := 1) -> bool` (false und unverändert, wenn zu wenig),
  `GameState.item_count(id: String) -> int`. `icon` ist `"sammeln:<name>"` oder `"icons:<gruppe>:<name>"`.

- [ ] **Step 1: Failing tests** in `test_items.gd`:
  `test_items_from_spec` (alle 15 IDs der Spec-Tabelle inkl. `monsterkern_D` sell 15, `monsterkern_C` sell 35, `brot` buy 12 effect hp 30, `pilz` battle_only true);
  `test_add_remove_count` (remove 3 von 2 → false, Bestand bleibt 2; remove auf 0 löscht den Schlüssel);
  `test_items_saved_and_old_save_loads` (to_dict/from_dict rund; `from_dict({})` → items leer).
- [ ] **Step 2:** `tools/run_tests.sh test_items` → FAIL (DB.item fehlt).
- [ ] **Step 3:** `items.json` mit den Werten der Spec-Tabelle (Gegengift weglassen); DB lädt es wie `equipment.json`; GameState-Felder, reset, to_dict/from_dict.
- [ ] **Step 4:** `tools/run_tests.sh` → alles PASS.
- [ ] **Step 5:** Commit `feat: Vorrat und Gegenstandsdaten`.

### Task 2: Gegenstands-Icons

**Files:**
- Modify: `tools/import_cosy.py` (+ `welt/sammeln/*` komplett, `icons/icons.json`, `icons/essen_kraeuter.png`, `icons/traenke.png`, `icons/beute.png`, `icons/waffen.png`, `icons/ruestung.png`), `game/world/cosy_art.gd`
- Test: `game/tests/test_items.gd`

**Interfaces:**
- Produces: `CosyArt.item_icon(id: String) -> Texture2D` (16×16 AtlasTexture; für Gegenstände aus `DB.items` über deren `icon`, für Ausrüstung über ein neues Feld `icon` in `equipment.json`, z. B. `"icons:waffen:schwert_D"`).
  Atlas-Lage: `icons_sammeln.png` Index `icon_index` waagrecht à 16 px; `icons/<gruppe>.png` Index = Position in `icons.json.gruppen[gruppe]` (Lage im Bild beim Import prüfen und im Test festnageln).

- [ ] **Step 1: Failing test** `test_every_item_and_equipment_has_icon` (jede ID aus DB.items und DB.equip → Textur 16×16, nicht null).
- [ ] **Step 2:** Run → FAIL. **Step 3:** Import erweitern, `python3 tools/import_cosy.py ../aniamtion`, `item_icon` implementieren, `icon` in `equipment.json` ergänzen. **Step 4:** Run → PASS. **Step 5:** Commit.

### Task 3: Sammelstellen

**Files:**
- Create: `game/world/harvest_spot.gd`, `game/tests/test_harvest.gd`
- Modify: `game/world/entity_factory.gd`, `game/world/cosy_art.gd`

**Interfaces:**
- Consumes: `GameState.add_item`, `CosyArt.meta("welt/sammeln/sammeln.json")`.
- Produces: Entität `sammeln <art> x,y [anzahl=n]` (Vorgabe anzahl 1; weizen 3, Beeren 2).
  `class_name HarvestSpot extends Area2D`: Felder `kind, amount, flag`; `harvest() -> bool` (false, wenn schon geerntet).
  Merker `geerntet:<raum>:<index>`. `CosyArt.harvest_frames(kind) -> SpriteFrames` mit Animationen `idle` (Schleife), `ernten`, `leer`, `nachwachsen`.
  Wurde die Stelle beim letzten Besuch leer gesehen und ist der Merker jetzt weg, spielt sie einmal `nachwachsen` (Merker `gesehen_leer:<raum>:<index>`).

- [ ] **Step 1: Failing tests:** `test_harvest_adds_items_once` (harvest → +amount, Merker gesetzt, zweites harvest → false, Bestand gleich);
  `test_harvested_spot_spawns_empty` (Merker gesetzt → Animation `leer`); `test_regrow_after_flag_cleared` (gesehen_leer + kein Merker → `nachwachsen`);
  `test_no_harvest_while_paused` (GameState.pause_push → Eingabe ignoriert).
- [ ] **Step 2–4:** FAIL → [W]-Bedienung wie `Npc` (Hinweis „[W]“, Abklingzeit 0.35 s), Toast „+2 Waldbeeren“; leuchtende Arten bekommen `Stimmung.light("lampe")` klein → PASS.
- [ ] **Step 5:** Commit.

### Task 4: Rasten setzt die Welt zurück

**Files:**
- Modify: `game/autoload/game_state.gd`, `game/world/save_spot.gd`
- Test: `game/tests/test_rest.gd` (neu)

**Interfaces:**
- Produces: `GameState.rest() -> void`: leert `hp`, löscht alle `geerntet:*`, löscht `defeated:<raum>:<i>`, wenn der Raum kein Dungeon ist (`RoomManager.def_of(raum).one_way_dungeon == false` und Gebiet nicht in `dungeon_*`-Räumen) **und** die Entität `enemy` (nicht `boss`) ist; sendet danach `signal rested` (Task 7 hängt das Neuwürfeln der Aufträge in `rest()` ein). SaveSpot „Rasten“ ruft `GameState.rest()`.

- [ ] **Step 1: Failing tests:** `test_rest_revives_field_enemies` (defeated:kornfeld_01:2 weg); `test_rest_keeps_dungeon_and_boss` (defeated:blutdungeon_ketten:… und Boss-Merker bleiben); `test_rest_regrows` (geerntet:* weg); `test_rest_heals`.
- [ ] **Step 2–4:** FAIL → implementieren → PASS. **Step 5:** Commit.

### Task 5: Monsterkerne als Beute

**Files:**
- Modify: `game/core/combat/battle_state.gd` (`result()`), `game/autoload/battle_launcher.gd` (`finish`), `game/battle/battle_scene.gd` (`_finish` Meldung)
- Test: `game/tests/test_combat_core.gd`

**Interfaces:**
- Produces: `BattleResult.drops` enthält `"monsterkern_<rang>"` je Gegner mit Rang D oder C bei `rng.randf() < 0.5`, Bosse immer (Rang B → `monsterkern_C`, da es keinen B-Kern gibt). Launcher fügt drops per `GameState.add_item` hinzu.
  `BattleLauncher.signal enemies_defeated(ids: Array)` (für Jagd-Aufträge, Task 7).
  Siegmeldung: „Sieg! 12 Silber erbeutet. Monsterkern (D) ×1.“

- [ ] **Step 1: Failing tests:** `test_boss_always_drops_core`; `test_drop_rate_seeded` (rng.seed fest, 2 Goblins → erwartete Kernzahl); `test_launcher_adds_drops_to_items`.
- [ ] **Step 2–4:** FAIL → implementieren → PASS. **Step 5:** Commit.

### Task 6: Vorräte benutzen (Kampf und Pause)

**Files:**
- Create: `game/core/economy/consumables.gd`, `game/ui/supplies_menu.gd`, `game/tests/test_consumables.gd`
- Modify: `game/core/combat/battle_state.gd` (`submit` Aktion `"item"`), `game/battle/battle_scene.gd` (Modus `items`), `game/world/world.gd` (Pausenmenü „Vorräte“)

**Interfaces:**
- Produces: `Consumables.usable(in_battle: bool) -> Array[String]` (IDs mit Bestand > 0 und `effect` nicht leer; ohne `battle_only`, wenn nicht im Kampf).
  `Consumables.apply_battle(item_id: String, target: Combatant) -> int` (heilt hp bis max_hp oder füllt mana_c und mana_s je um den Wert bis max; zieht 1 ab; gibt Menge zurück).
  `Consumables.apply_field(item_id: String, hero_id: String) -> int` (heilt `GameState.hp[hero_id]` bis Max-LP aus `DB.hero`; fehlender Eintrag = volle LP → 0 und kein Verbrauch).
  `submit({"action": "item", "item": id, "target": Combatant})` mit Log „Lira isst Brot: +30 LP.“
  `SuppliesMenu.open(parent: Node) -> SuppliesMenu` (Liste mit Icon, Name, Anzahl; dann Zielwahl Held/Geschwister).

- [ ] **Step 1: Failing tests:** `test_battle_item_heals_and_consumes`; `test_mana_item_only_in_battle`; `test_field_item_full_hp_not_consumed`; `test_menu_item_enabled_only_with_supplies` (BattleScene `_menu_enabled("Gegenstand")`).
- [ ] **Step 2–4:** FAIL → implementieren (BattleScene: Modus `items` analog `spells`, dann `target` mit `target_kind = "ally"`) → PASS. **Step 5:** Commit.

### Task 7: Auftragsbrett

**Files:**
- Create: `game/data/quests.json`, `game/core/economy/quests.gd`, `game/world/quest_board.gd`, `game/ui/quest_menu.gd`, `game/tests/test_quests.gd`
- Modify: `game/autoload/game_state.gd` (Feld `quests`), `game/world/entity_factory.gd` (Entität `auftragsbrett`), `tools/import_cosy.py` (`welt/dorf/gildenbrett.png`, `welt/welt.json`, `ui/banner_auftrag_erledigt.png` ist schon da)

**Interfaces:**
- Consumes: `GameState.rested`, `BattleLauncher.enemies_defeated`, `GameState.remove_item`.
- Produces: `GameState.quests := {"offers": [], "active": [], "roll": 0}`; Auftrag = `{id, kind: "liefern"|"jagen"|"kerne", giver, text, item?, enemy?, need, progress, reward}`.
  `Quests.reroll() -> void` (3 Angebote aus Vorlagen in `quests.json`, RNG-Seed = `quests.roll`, danach `roll += 1`; aktive bleiben),
  `Quests.accept(index: int) -> bool` (max 3 aktiv), `Quests.can_turn_in(q: Dictionary) -> bool`, `Quests.turn_in(index: int) -> int` (Silber; bei Gilden-Aufträgen −10 % Blutsteuer, gerundet ab),
  `Quests.on_defeated(ids: Array)` (zählt `jagen` ab Annahme). Kern-Aufträge nehmen zuerst D-, dann C-Kerne.
  Vorlagen: die fünf Liefer- und drei Jagd-Aufträge der Spec + „3 Monsterkerne“; Lohn: liefern 3 × sell × need, jagen 10 × need, kerne 20 × need.
  Brett-Entität `auftragsbrett x,y` in `kornburg_gilde`; [W] öffnet `QuestMenu` (Angebote annehmen, aktive abgeben, Banner bei Abgabe).
  Öffnen ohne Angebote und ohne je gewürfelt → `reroll()` (alter Spielstand).

- [ ] **Step 1: Failing tests:** `test_reroll_deterministic_and_keeps_active`; `test_accept_max_three`; `test_deliver_turn_in_removes_items_and_pays`; `test_guild_quest_blood_tax`; `test_hunt_counts_only_after_accept`; `test_cores_accept_c_for_d`; `test_old_save_board_rolls_on_open`.
- [ ] **Step 2–4:** FAIL → implementieren, `GameState.rest()` ruft `Quests.reroll()` → PASS. **Step 5:** Commit.

### Task 8: Läden – Logik und Fenster

**Files:**
- Create: `game/data/shops.json`, `game/core/economy/shop.gd`, `game/ui/shop_menu.gd`, `game/tests/test_shop.gd`
- Modify: `game/world/npc.gd` (Eigenschaft `laden=<id>` öffnet ShopMenu statt Dialog; erst Begrüßungsdialog `laden_<id>`, dann Fenster)

**Interfaces:**
- Produces: `shops.json`: `{"baeckerei": {"owner", "sells": [...], "buys": [...], "rate": 1.0, "bake": true}, "alchemie": {...}, "waffen": {"sells": ["kurzschwert", ...], "buys_equipment": true}, "markt": {"buys": "alle_sammelbar", "rate": 0.7}, "gilde": {"buys": ["monsterkern_D", "monsterkern_C"]}}`.
  `Shop.price_buy(item: String) -> int` (Gegenstand `buy`; Ausrüstung D 40 / C 90), `Shop.price_sell(shop_id: String, item: String) -> int` (Gegenstand `sell` × rate abgerundet, min 1; Ausrüstung halber Kaufpreis),
  `Shop.buy(shop_id, item) -> String` (Meldung; „Zu wenig Silber.“), `Shop.sell(shop_id, item) -> String` („Angelegte Ausrüstung kann nicht verkauft werden.“),
  `Shop.bake() -> String` (3 Weizen + 2 Silber → 1 Brot).
  `ShopMenu.open(parent: Node, shop_id: String) -> ShopMenu`: Kopf Kaufen/Verkaufen/(Backen lassen)/Zurück, Liste Icon·Name·Preis·Bestand, Silber oben; bleibt nach Kauf offen; Holzrahmen `UiArt.frame("holz", …)`.

- [ ] **Step 1: Failing tests:** `test_buy_reduces_silver_adds_item`; `test_buy_without_silver_refused`; `test_sell_only_shop_goods`; `test_market_pays_70_percent`; `test_cannot_sell_equipped`; `test_bake_bread`; `test_guild_buys_cores_full_price`.
- [ ] **Step 2–4:** FAIL → implementieren → PASS. **Step 5:** Commit.

### Task 9: Ladeninnenräume, Türen und Händler im Dorf

**Files:**
- Modify: `tools/art/backgrounds.py` (`innen_baeckerei`, `innen_alchemie`, `innen_schmiede` im Stil von `innen_haus`), `tools/gen_rooms.py`, `game/data/dialog.json`
- Test: `game/tests/test_dorf.gd`

**Interfaces:**
- Consumes: `npc … laden=<id>` aus Task 8.
- Produces: Innenräume `laden_baeckerei`, `laden_alchemie`, `laden_waffen` (Biom = Hintergrundname, Gebiet kornburg) mit Inhaber hinter `deco tresen`, Lampe, `door aussen` zurück.
  Im Dorf: `door baeckerei 22,14 to=laden_baeckerei:aussen` usw. an den Gebäudetüren; Borin steht drinnen (`art=zwerg_tunika laden=waffen`), draußen arbeitet „Geselle Tamm“ (`arbeit=schmied dialog=dorf_geselle`).
  Händlerin Szissa `laden=markt`, Gildenmeisterin Hadra bekommt Option „Monsterkerne verkaufen“ (`laden=gilde`, Dialog `gilde_rat` bleibt als Begrüßung). Alchemistin Veska neu (Grafik: `mensch_tunika` oder `elf_tunika`).

- [ ] **Step 1: Failing tests:** `test_shops_enterable` (je Laden: Dorf-Tür ↔ Innenraum-Tür passen, Innenraum hat npc mit `laden`); `test_safe_rooms_have_warm_light` um die drei Läden erweitern.
- [ ] **Step 2–4:** FAIL → Hintergründe zeichnen (`python3 tools/gen_art.py`), Räume, Dialoge → PASS; Screenshot je Laden über `tools/shot.sh res://debug/preview.tscn … "room laden_baeckerei"` prüfen. **Step 5:** Commit.

### Task 10: Waldstück und Sammelstellen in der Welt

**Files:**
- Modify: `tools/gen_rooms.py`, `game/data/stimmung.json` (`"wald": "#8c9cb0"`), `game/world/room_builder.gd` (`BIOME_TERRAIN["wald"] = "wiese"`), `game/world/backdrop.gd` (`COSY["wald"] = "dorf_nacht"`), `tools/import_cosy.py` (`props/baum_nacht.png`, `tanne_nacht.png`, `busch_nacht.png`), `game/world/entity_factory.gd` (Entität `prop <name> x,y` → Sprite `props/<name>_nacht.png`, Unterkante am Boden, z 0)
- Test: `game/tests/test_slice_content.gd`

**Interfaces:**
- Produces: kornfeld_08 bekommt `R2=wald_01:L1`; Räume `wald_01..wald_03` (Biom wald, Gebiet kornburg), Ast-Plattformen (`-`), Bäume/Tannen/Büsche als `prop`.
  Gegner: wald_01 `gruenschleim+gruenschleim`, wald_02 `riesenspinne` und `goblin+goblin`, wald_03 Lichtung mit `riesenspinne+riesenspinne`; Truhe `pickup silber:40` auf der Lichtung.
  Sammelstellen: kornfeld_01..07 je 1–2 `sammeln weizen`, ein `sammeln apfel` in kornfeld_02; Wald je 2–4 aus beeren_rot, blaubeeren, pilz, heilkraut; leuchtpilz und manablume nur auf der Lichtung.

- [ ] **Step 1: Failing tests:** `test_forest_right_of_portal` (kornfeld_08 R2 → wald_01, wald_03 ohne R-Ausgang); `test_harvest_spots_placed` (Weizen in Kornfeldern, alle fünf Waldarten vorhanden, keine Sammelstelle in Dungeon-Räumen); `test_rooms_traversable` deckt die neuen Räume automatisch ab.
- [ ] **Step 2–4:** FAIL → Räume erzeugen → PASS; Screenshots wald_01..03 prüfen. **Step 5:** Commit, `tools/run_tests.sh` grün, `git push origin main`.
