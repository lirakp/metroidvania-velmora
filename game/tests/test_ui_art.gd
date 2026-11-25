extends TestCase

var tree: SceneTree = Engine.get_main_loop()


func test_portrait_for_speaker() -> void:
	assert_eq(DialogBox.portrait_sheet("Lira"), "elf_tunika")
	assert_eq(DialogBox.portrait_sheet("Warschick"), "elf_ruestung")
	assert_eq(DialogBox.portrait_sheet("Gildenmeisterin Hadra"), "zwerg_tunika")
	assert_eq(DialogBox.portrait_sheet("Hinweis"), "")


func test_portrait_frames() -> void:
	var sf := UiArt.portrait_frames("elf_tunika")
	assert_eq(sf.get_frame_count("spricht"), 2)
	assert_eq(sf.get_frame_texture("spricht", 0).get_size(), Vector2(40, 40))


func test_frame_is_nine_patch() -> void:
	var f := UiArt.frame("holz", Vector2(100, 40))
	assert_true(f is NinePatchRect)
	assert_eq(f.patch_margin_left, 8)
	assert_eq(f.size, Vector2(100, 40))
	f.free()


func test_damage_number_glyphs() -> void:
	assert_eq(UiArt.digit_rect("7"), Rect2(35, 0, 5, 7))
	assert_eq(UiArt.digit_rect("+"), Rect2(50, 0, 5, 7))
	var n := UiArt.number_node("12", "normal")
	assert_eq(n.get_child_count(), 2)
	n.free()


func test_dialog_box_shows_frame_and_portrait() -> void:
	GameState.reset()
	GameState.choose_hero("warschick")
	var box := DialogBox.show_dialog(tree.root, "boss_intro")
	await tree.process_frame
	assert_true(box.find_children("*", "NinePatchRect", true, false).size() >= 1, "Rahmen")
	assert_true(box.portrait != null and box.portrait.visible, "Porträt sichtbar")
	box._close()
	GameState.pause_reset()


func test_victory_banner() -> void:
	var scene: BattleScene = load("res://battle/battle_scene.tscn").instantiate()
	tree.root.add_child(scene)
	scene.setup(["warschick"], ["goblin"], "erstschlag", "kornfeld")
	scene.state.enemies[0].hp = 0
	scene.auto_play_for_test()
	for i in 10:
		await tree.process_frame
	assert_true(scene.find_child("Banner", true, false) != null)
	scene.queue_free()


func test_text_rendered_at_screen_resolution() -> void:
	# Schrift wird in Bildschirmauflösung gezeichnet (scharf), Pixelgrafik ganzzahlig hochskaliert.
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer")
	assert_eq(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 0, "Pixelgrafik ohne Weichzeichnen")
