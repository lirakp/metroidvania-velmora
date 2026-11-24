extends TestCase


func test_monster_frames_from_metadata() -> void:
	var sf := CosyArt.monster_frames("goblin")
	for anim in ["idle", "move", "attack", "hurt", "death"]:
		assert_true(sf.has_animation(anim), anim)
	assert_eq(sf.get_frame_count("idle"), 4)
	assert_eq(sf.get_frame_count("attack"), 6)
	assert_eq(sf.get_frame_texture("idle", 0).get_size(), Vector2(31, 40))
	assert_false(sf.get_animation_loop("death"))


func test_monster_ground_offset() -> void:
	# Bodenpunkt (14, 35) im 31x40-Bild: Bild so verschieben, dass dieser Punkt am Ursprung liegt
	assert_eq(CosyArt.monster_offset("goblin"), Vector2(31 / 2.0 - 14, 40 / 2.0 - 35))


func test_every_enemy_has_cosy_sprite() -> void:
	for id in DB.enemies:
		var sf := CosyArt.monster_frames(id)
		assert_true(sf.has_animation("idle"), id)


func test_hero_frames_from_metadata() -> void:
	var sf := CosyArt.hero_frames("elf_tunika")
	assert_eq(sf.get_frame_count("rennen"), 8)
	assert_eq(sf.get_frame_count("angriff_vorne"), 5)
	assert_eq(sf.get_frame_texture("stehen", 0).get_size(), Vector2(48, 48))
	assert_true(sf.get_animation_loop("stehen"))
	assert_false(sf.get_animation_loop("angriff_vorne"))


func test_lamp_entity_builds_animated_light() -> void:
	var text := "id: a\nbiome: stadt\narea: k\n---\n"
	for y in 17:
		text += ("#" if y >= 15 else ".").repeat(30) + "\n"
	text += "---\nlampe strassenlaterne 10,14\nlampe standfackel 20,14\n"
	var d := RoomDef.parse(text)
	var room := RoomBuilder.build(d)
	EntityFactory.populate(room, d)
	var lamps := room.get_children().filter(func(n): return n is Lamp)
	assert_eq(lamps.size(), 2)
	var l: Lamp = lamps[0]
	assert_eq(l.body.sprite_frames.get_frame_count("an"), 8)
	assert_true(l.glow.material is CanvasItemMaterial)
	assert_eq(l.glow.material.blend_mode, CanvasItemMaterial.BLEND_MODE_ADD)
	# Lichtpunkt (7, 9) im 14x40-Bild, Füße unten mittig: Lichtkreis 31 px über dem Boden
	assert_eq(l.glow.position, Vector2(0, -31))
	room.free()


func test_building_scaled_with_door_at_origin() -> void:
	var b := Building.create("gilde_abenteuer")
	assert_eq(b.scale, Vector2(2, 2))
	# Tür in tueren.json: x 46, y 87, w 18, h 24 → Unterkante Türmitte liegt am Ursprung
	assert_eq(b.sprite.position, Vector2(-(46 + 9), -(87 + 24)))
	assert_true(b.door_height_px() >= 46, "Tür höher als die Figur (42 px)")
	b.free()


func test_rooms_use_cosy_buildings_with_doors() -> void:
	for pair in [["stadt_01", "gilde_abenteuer", "gilde"], ["stadt_02", "cottage", "karto"], ["muehle_01", "windmuehle", "muehle"]]:
		var d := RoomDef.load_room(pair[0])
		var b := d.entities.filter(func(e): return e.type == "gebaeude" and e.id == pair[1])
		var door := d.entities.filter(func(e): return e.type == "door" and e.id == pair[2])
		assert_eq(b.size(), 1, pair[0])
		assert_eq(door.size(), 1, pair[0])
		if b.size() == 1 and door.size() == 1:
			assert_eq(b[0].pos, door[0].pos, "Gebäudetür liegt auf der Tür-Stelle")
