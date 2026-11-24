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
