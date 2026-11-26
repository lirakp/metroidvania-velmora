extends TestCase

const SINGLE_JUMP_TILES := 2
const DOUBLE_JUMP_TILES := 4


func test_all_rooms_parse() -> void:
	var defs := WorldMap.load_defs("res://data/rooms")
	assert_true(defs.size() >= 30, "Anzahl Räume: %d" % defs.size())
	for id in defs:
		assert_eq(defs[id].error, "", id)


func test_world_map_valid() -> void:
	assert_eq(WorldMap.validate_all("res://data/rooms"), [])


func test_entities_reference_known_data() -> void:
	var defs := WorldMap.load_defs("res://data/rooms")
	var dialogs: Dictionary = DialogBox.all_dialogs()
	for id in defs:
		for e in defs[id].entities:
			match e.type:
				"enemy", "boss":
					for eid in e.id.split("+"):
						assert_true(DB.enemies.has(eid), "%s: Gegner %s" % [id, eid])
				"dialog":
					assert_true(dialogs.has(e.id), "%s: Dialog %s" % [id, e.id])
				"npc":
					if e.props.has("dialog"):
						assert_true(dialogs.has(e.props.dialog), "%s: Dialog %s" % [id, e.props.dialog])
				"pickup":
					if e.id.begins_with("item:"):
						assert_true(DB.equip.has(e.id.substr(5)), "%s: %s" % [id, e.id])


func test_guild_has_start_and_save() -> void:
	var d := RoomDef.load_room("kornburg_gilde")
	assert_true(d.spawns.has("start"))
	assert_true(d.entities.any(func(e): return e.type == "save" and e.props.get("kind") == "gilde"))


func test_dungeon_rooms_are_one_way_and_have_boss() -> void:
	var defs := WorldMap.load_defs("res://data/rooms")
	var boss := 0
	for id in defs:
		if id.begins_with("blutdungeon"):
			assert_true(defs[id].one_way_dungeon, id)
			boss += defs[id].entities.filter(func(e): return e.type == "boss").size()
	assert_eq(boss, 1)


## Begehbare Kacheln: leer (oder Spawn/Marker) mit festem Boden oder Plattform darunter.
## Die Figur ist 36 px hoch und braucht 3 Kacheln Kopffreiheit.
func _standable(d: RoomDef, c: Vector2i) -> bool:
	var below := d.tile_at(c + Vector2i(0, 1))
	for dy in 3:
		if not d.tile_at(c - Vector2i(0, dy)) in [0, 3, 8, 11, 12]:
			return false
	return d.tile_at(c) != 3 and (below in RoomDef.SOLID or below == 3)


func _clear(d: RoomDef, c: Vector2i) -> bool:
	var t := d.tile_at(c)
	return c.x >= 0 and c.x < d.size.x and c.y >= 0 and (t == 0 or t == 3 or t == 8 or t == 11 or t == 12)


func _reachable(d: RoomDef, start: Vector2i, target: Vector2i, jump: int) -> bool:
	var seen := {start: true}
	var queue: Array = [start]
	while not queue.is_empty():
		var s: Vector2i = queue.pop_front()
		if s == target:
			return true
		for dx in range(-3, 4):
			for dy in range(-jump, d.size.y):
				var t := s + Vector2i(dx, dy)
				if seen.has(t) or not _standable(d, t):
					continue
				var top := mini(s.y, t.y) - 2
				var ok := true
				for y in range(top, s.y + 1):
					ok = ok and _clear(d, Vector2i(s.x, y))
				for x in range(mini(s.x, t.x), maxi(s.x, t.x) + 1):
					for y in range(top, top + 3):
						ok = ok and _clear(d, Vector2i(x, y))
				for y in range(top, t.y + 1):
					ok = ok and _clear(d, Vector2i(t.x, y))
				if ok:
					seen[t] = true
					queue.append(t)
	return false


func test_federfall_gate_reachable_kornfeld() -> void:
	var d := RoomDef.load_room("kornfeld_06")
	var start := d.arrival_cell("L1")
	var hammer: Dictionary = d.entities.filter(func(e): return e.id == "item:rostiger_kriegshammer")[0]
	assert_false(_reachable(d, start, hammer.pos, SINGLE_JUMP_TILES), "ohne Federfall unerreichbar")
	assert_true(_reachable(d, start, hammer.pos, DOUBLE_JUMP_TILES), "mit Federfall erreichbar")


func test_dungeon_needs_federfall() -> void:
	var d := RoomDef.load_room("blutdungeon_wand")
	var start := d.arrival_cell("L1")
	var goal: Vector2i = d.entities.filter(func(e): return e.type == "door" and e.props.get("richtung") == "hinten")[0].pos
	assert_false(_reachable(d, start, goal, SINGLE_JUMP_TILES))
	assert_true(_reachable(d, start, goal, DOUBLE_JUMP_TILES))


func test_federfall_reachable_without_federfall() -> void:
	var d := RoomDef.load_room("blutdungeon_federfall")
	var start := d.arrival_cell("L1")
	var f: Dictionary = d.entities.filter(func(e): return e.id == "federfall")[0]
	assert_true(_reachable(d, start, f.pos, SINGLE_JUMP_TILES))


func test_dialog_placeholders() -> void:
	GameState.reset()
	GameState.choose_hero("lira")
	var lines := DialogBox.lines_for("intro")
	assert_true(lines.size() >= 4)
	for l in lines:
		assert_false(l.text.contains("{"), l.text)
		assert_false(l.speaker.contains("{"), l.speaker)
	assert_true(lines.any(func(l): return l.speaker == "Warschick"), "Geschwister spricht")


## Alle Ausgänge eines Raums sind untereinander erreichbar. Ohne Federfall überall dort,
## wo man vor dem Fund von Federfall (blutdungeon_05) hinkommt.
func test_rooms_traversable() -> void:
	var defs := WorldMap.load_defs("res://data/rooms")
	for id in defs:
		var d: RoomDef = defs[id]
		var points := {}
		for e in d.exits:
			points["Ausgang " + e.id] = d.arrival_cell(e.id)
		for e in d.entities:
			if e.type in ["door", "save", "npc", "pickup"]:
				points["%s %s" % [e.type, e.id]] = e.pos
		if d.spawns.has("start"):
			points["Start"] = d.spawns.start
		var jump := DOUBLE_JUMP_TILES if id in ["blutdungeon_wand"] else SINGLE_JUMP_TILES
		var names := points.keys()
		for a in names:
			for b in names:
				if a == b or (b.begins_with("pickup") and id == "kornfeld_06"):
					continue
				assert_true(_reachable(d, points[a], points[b], jump), "%s: %s → %s" % [id, a, b])


func test_safe_rooms_have_warm_light() -> void:
	for id in ["kornburg_gilde", "kartograf_haus", "blutdungeon_rast", "stadt_01", "stadt_02"]:
		var d := RoomDef.load_room(id)
		assert_eq(d.error, "", id)
		assert_true(d.entities.any(func(e): return (e.type == "light" and e.id == "warm") or e.type == "lampe"), "%s ohne warmes Licht" % id)


func test_dungeon_rooms_have_no_warm_light_except_rast() -> void:
	var defs := WorldMap.load_defs("res://data/rooms")
	for id in defs:
		if id.begins_with("blutdungeon") and id != "blutdungeon_rast":
			assert_false(defs[id].entities.any(func(e): return (e.type == "light" and e.id == "warm") or e.type == "lampe"), id)


func test_interiors_reached_by_doors() -> void:
	for pair in [["stadt_01", "kornburg_gilde"], ["stadt_02", "kartograf_haus"], ["muehle_01", "muehle_innen"], ["blutdungeon_kreuzgang", "blutdungeon_rast"], ["blutdungeon_rundweg", "blutdungeon_wand"]]:
		var outer := RoomDef.load_room(pair[0])
		assert_true(outer.entities.any(func(e): return e.type == "door" and String(e.props.get("to", "")).begins_with(pair[1] + ":")), "%s → %s" % pair)



# ---------------------------------------------------------------- Labyrinth
## Verbindungen im Dungeon (Ausgänge + Türen) als Graph: Raum → [Nachbarn]
func _dungeon_graph(skip_edge := []) -> Dictionary:
	var defs := WorldMap.load_defs("res://data/rooms")
	var g := {}
	for id in defs:
		if not id.begins_with("blutdungeon"):
			continue
		g[id] = []
		for e in defs[id].exits:
			if e.target_room.begins_with("blutdungeon"):
				g[id].append(e.target_room)
		for e in defs[id].entities:
			if e.type == "door":
				var to: String = String(e.props.to).split(":")[0]
				if not to.begins_with("blutdungeon"):
					continue
				if [id, to] != skip_edge and [to, id] != skip_edge:
					g[id].append(to)
	return g


func _reach(g: Dictionary, start: String) -> Dictionary:
	var seen := {start: true}
	var q := [start]
	while not q.is_empty():
		var r: String = q.pop_front()
		for n in g[r]:
			if not seen.has(n):
				seen[n] = true
				q.append(n)
	return seen


func test_labyrinth_size_and_reachability() -> void:
	var g := _dungeon_graph()
	assert_true(g.size() >= 15, "mindestens 15 Räume: %d" % g.size())
	assert_eq(_reach(g, "blutdungeon_eingang").size(), g.size(), "alle Räume erreichbar")


func test_labyrinth_has_dead_ends_with_purpose() -> void:
	var g := _dungeon_graph()
	var dead := g.keys().filter(func(r): return g[r].size() == 1 and not r in ["blutdungeon_boss", "blutdungeon_rast", "blutdungeon_eingang"])
	assert_true(dead.size() >= 3, "Sackgassen: %s" % [dead])
	for r in dead:
		var d := RoomDef.load_room(r)
		assert_true(d.entities.any(func(e): return e.type == "pickup"), "%s: Sackgasse ohne Belohnung" % r)


func test_labyrinth_has_loop() -> void:
	var g := _dungeon_graph()
	var edges := 0
	for r in g:
		edges += g[r].size()
	assert_true(edges / 2 >= g.size(), "Rundweg vorhanden (Kanten %d, Räume %d)" % [edges / 2, g.size()])


func test_boss_only_through_federfall_wall() -> void:
	var g := _dungeon_graph(["blutdungeon_wand", "blutdungeon_bluthalle"])
	assert_false(_reach(g, "blutdungeon_eingang").has("blutdungeon_boss"), "ohne Federfall-Wand kein Weg zum Boss")


func test_path_alternates_straight_and_back() -> void:
	# Hauptweg nutzt mindestens drei Öffnungen nach hinten
	var defs := WorldMap.load_defs("res://data/rooms")
	var back := 0
	for id in defs:
		if id.begins_with("blutdungeon"):
			back += defs[id].entities.filter(func(e): return e.type == "door" and e.props.get("richtung") == "hinten").size()
	assert_true(back >= 4, "Öffnungen nach hinten: %d" % back)


# ---------------------------------------------------------------- Waldstück und Sammelstellen
const WALD := ["wald_01", "wald_02", "wald_03"]
const WALD_ARTEN := ["beeren_rot", "blaubeeren", "pilz", "heilkraut", "leuchtpilz", "manablume"]


func _harvest(id: String) -> Array:
	return RoomDef.load_room(id).entities.filter(func(e): return e.type == "sammeln")


func test_forest_right_of_portal() -> void:
	var k8 := RoomDef.load_room("kornfeld_08")
	var r := k8.exits.filter(func(e): return e.id == "R2")
	assert_eq(r.size(), 1, "kornfeld_08 ohne Ausgang rechts")
	if r.size() == 1:
		assert_eq(r[0].target_room, "wald_01")
	for id in WALD:
		var d := RoomDef.load_room(id)
		assert_eq(d.error, "", id)
		assert_eq(d.biome, "wald", id)
		assert_eq(d.area, "kornburg", id)
	assert_false(RoomDef.load_room("wald_03").exits.any(func(e): return e.edge == "R"), "Lichtung ist Sackgasse")


func test_forest_has_enemies_and_chest() -> void:
	var w3 := RoomDef.load_room("wald_03")
	assert_true(w3.entities.any(func(e): return e.type == "enemy" and e.id == "riesenspinne+riesenspinne"))
	assert_true(w3.entities.any(func(e): return e.type == "pickup" and String(e.id).begins_with("silber:")))
	assert_false(w3.entities.any(func(e): return e.type == "boss"))


func test_harvest_spots_placed() -> void:
	var weizen := 0
	for i in range(1, 8):
		weizen += _harvest("kornfeld_0%d" % i).filter(func(e): return e.id == "weizen").size()
	assert_true(weizen >= 7, "zu wenig Weizen: %d" % weizen)
	assert_true(_harvest("kornfeld_02").any(func(e): return e.id == "apfel"))
	var kinds := {}
	for id in WALD:
		var spots := _harvest(id)
		assert_true(spots.size() >= 2 and spots.size() <= 6, "%s: %d Sammelstellen" % [id, spots.size()])
		for e in spots:
			kinds[e.id] = true
	for k in WALD_ARTEN:
		assert_true(kinds.has(k), "Waldart fehlt: " + k)
	for k in ["leuchtpilz", "manablume"]:
		assert_false(_harvest("wald_01").any(func(e): return e.id == k) or _harvest("wald_02").any(func(e): return e.id == k), k + " nur auf der Lichtung")


func test_no_harvest_in_dungeons_and_known_kinds() -> void:
	var defs := WorldMap.load_defs("res://data/rooms")
	for id in defs:
		for e in defs[id].entities:
			if e.type == "sammeln":
				assert_false(defs[id].one_way_dungeon, id)
				assert_true(DB.items.has(e.id), "%s: unbekannt %s" % [id, e.id])
			if e.type == "prop":
				assert_true(ResourceLoader.exists(CosyArt.BASE + "props/%s_nacht.png" % e.id), "%s: Requisit %s" % [id, e.id])


func test_forest_mood() -> void:
	assert_true(Stimmung.has_tint("wald"))
	assert_true(Backdrop.cosy_layers("wald").size() > 0)
	assert_true(RoomBuilder.terrain_tiles("wald").size() > 0)
