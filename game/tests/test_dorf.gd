extends TestCase
## Dorf links vom Gildenhaus: Läden, Schmieden, arbeitende Dorfbewohner.

const DORF := ["dorf_01", "dorf_02", "dorf_03"]

var tree: SceneTree = Engine.get_main_loop()


func test_work_frames_from_metadata() -> void:
	var sf := CosyArt.work_frames("schmied")
	assert_true(sf.has_animation("arbeit"))
	assert_eq(sf.get_frame_count("arbeit"), 8)
	assert_eq(sf.get_frame_texture("arbeit", 0).get_size(), Vector2(48, 34))
	assert_true(sf.get_animation_loop("arbeit"))


func test_villager_npc_plays_work_loop() -> void:
	var n := Npc.new()
	n.npc_id = "schmied_test"
	n.props = {"arbeit": "schmied", "dialog": "dorf_schmied"}
	tree.root.add_child(n)
	var sp: AnimatedSprite2D = null
	for c in n.get_children():
		if c is AnimatedSprite2D:
			sp = c
	assert_true(sp != null, "Arbeits-Sprite fehlt")
	assert_true(sp.is_playing())
	# Doppelt groß wie die Gebäude; Füße stehen auf dem Boden: Unterkante des Bildes am Ursprung
	assert_eq(sp.scale, Vector2(2, 2))
	assert_almost(sp.position.y + 34.0 * sp.scale.y, 0.0)
	n.free()


func test_building_without_door_stands_on_ground() -> void:
	for kind in ["marktstand", "brunnen", "schmiede"]:
		var b := Building.create(kind)
		assert_true(b.door.is_empty(), kind)
		assert_true(b.door_anim == null, kind)
		var size := b.sprite.texture.get_size()
		assert_almost(b.sprite.position.y + size.y, 0.0)
		assert_almost(b.sprite.position.x + size.x / 2.0, 0.0)
		b.free()


func test_village_left_of_guild() -> void:
	var s := RoomDef.load_room("stadt_01")
	assert_eq(s.error, "")
	var left := s.exits.filter(func(e): return e.id == "L1")
	assert_eq(left.size(), 1, "stadt_01 ohne Ausgang links")
	if left.size() == 1:
		assert_eq(left[0].target_room, "dorf_01")
		assert_eq(left[0].target_exit_id, "R2")
	for id in DORF:
		var d := RoomDef.load_room(id)
		assert_eq(d.error, "", id)
		assert_eq(d.area, "kornburg", id)


func test_village_has_shops_smithies_and_villagers() -> void:
	var kinds := []
	var jobs := []
	for id in DORF:
		for e in RoomDef.load_room(id).entities:
			if e.type == "gebaeude":
				kinds.append(e.id)
			if e.type == "npc" and e.props.has("arbeit"):
				jobs.append(e.props.arbeit)
				assert_true(e.props.has("dialog"), "%s: %s ohne Dialog" % [id, e.id])
	for k in ["schmiede", "schmiede_waffen", "baeckerei", "taverne", "marktstand", "laden_alchemie"]:
		assert_true(k in kinds, "Gebäude fehlt: " + k)
	assert_true(jobs.size() >= 6, "zu wenige Dorfbewohner: %d" % jobs.size())
	assert_true("schmied" in jobs)


func test_village_rooms_are_warm() -> void:
	for id in DORF:
		var d := RoomDef.load_room(id)
		assert_true(d.entities.any(func(e): return e.type == "lampe"), id + " ohne Laterne")


const SHOPS := [["dorf_02", "laden_baeckerei", "baeckerei"], ["dorf_03", "laden_alchemie", "alchemie"], ["dorf_01", "laden_waffen", "waffen"]]


func test_shops_enterable() -> void:
	for s in SHOPS:
		var outer := RoomDef.load_room(s[0])
		var inner := RoomDef.load_room(s[1])
		assert_eq(inner.error, "", s[1])
		var door_out := outer.entities.filter(func(e): return e.type == "door" and String(e.props.get("to", "")).begins_with(s[1] + ":"))
		assert_eq(door_out.size(), 1, "%s → %s" % [s[0], s[1]])
		if door_out.size() != 1:
			continue
		var inner_door_id: String = String(door_out[0].props.to).split(":")[1]
		var back := inner.entities.filter(func(e): return e.type == "door" and e.id == inner_door_id)
		assert_eq(back.size(), 1, s[1] + " ohne Rücktür")
		if back.size() == 1:
			assert_eq(back[0].props.to, "%s:%s" % [s[0], door_out[0].id])
		# Die Dorf-Tür steht genau an der Gebäudetür
		var bld := outer.entities.filter(func(e): return e.type == "gebaeude" and e.pos == door_out[0].pos)
		assert_eq(bld.size(), 1, s[0] + ": Tür nicht am Gebäude")
		assert_true(inner.entities.any(func(e): return e.type == "npc" and e.props.get("laden", "") == s[2]), s[1] + " ohne Händler")
		assert_true(inner.entities.any(func(e): return e.type == "lampe"), s[1] + " ohne warmes Licht")


func test_traders_outside() -> void:
	var markt := RoomDef.load_room("dorf_02").entities.filter(func(e): return e.type == "npc" and e.id == "haendler")
	assert_eq(markt[0].props.get("laden", ""), "markt")
	var hadra := RoomDef.load_room("kornburg_gilde").entities.filter(func(e): return e.type == "npc" and e.id == "gildenmeisterin")
	assert_eq(hadra[0].props.get("laden", ""), "gilde")
	var smith := RoomDef.load_room("dorf_01").entities.filter(func(e): return e.type == "npc" and e.props.get("arbeit", "") == "schmied")
	assert_eq(smith[0].id, "geselle")


func test_shop_owner_sprites_exist() -> void:
	for key in ["borin", "veska"]:
		var sheet: String = CosyArt.NPC_SHEETS.get(key, "")
		assert_true(sheet != "", key)
		assert_true(ResourceLoader.exists(CosyArt.BASE + "characters/held/%s.png" % sheet), sheet)
