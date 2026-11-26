extends TestCase

var tree: SceneTree = Engine.get_main_loop()


func _world() -> Dictionary:
	GameState.reset()
	var world := Node2D.new()
	var floor := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(3000, 20)
	shape.shape = rect
	floor.position = Vector2(0, 210)
	floor.add_child(shape)
	world.add_child(floor)
	var p: Player = load("res://world/player.tscn").instantiate()
	p.test_control = true
	p.position = Vector2(200, 199)
	world.add_child(p)
	var s := Sibling.new()
	s.player = p
	s.position = Vector2(100, 199)
	world.add_child(s)
	tree.root.add_child(world)
	return {"world": world, "player": p, "sibling": s}


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


func test_follows_player() -> void:
	var w := _world()
	await _frames(90)
	assert_true(absf(w.sibling.position.x - w.player.position.x) <= 40, "Abstand %s" % absf(w.sibling.position.x - w.player.position.x))
	w.world.queue_free()


func test_teleports_when_far() -> void:
	var w := _world()
	w.sibling.position = Vector2(900, 199)
	await _frames(2)
	assert_true(absf(w.sibling.position.x - w.player.position.x) <= 40)
	w.world.queue_free()


func test_command_sends_to_point() -> void:
	var w := _world()
	var pt := SiblingPoint.new()
	pt.position = Vector2(230, 199)
	w.world.add_child(pt)
	await _frames(2)
	assert_true(w.sibling.command())
	w.player.position = Vector2(40, 199)
	await _frames(120)
	assert_true(absf(w.sibling.position.x - 230) <= 4, "steht am Punkt: %s" % w.sibling.position.x)
	assert_true(w.sibling.command(), "zurückrufen")
	assert_eq(w.sibling.mode, "follow")
	w.world.queue_free()


func test_command_needs_point_nearby() -> void:
	var w := _world()
	var pt := SiblingPoint.new()
	pt.position = Vector2(600, 199)
	w.world.add_child(pt)
	await _frames(2)
	assert_false(w.sibling.command())
	w.world.queue_free()


func test_gate_needs_both_plates() -> void:
	var w := _world()
	var a := PressurePlate.new()
	a.plate_name = "a"
	a.opens = "tor1"
	a.position = Vector2(200, 208)
	var b := PressurePlate.new()
	b.plate_name = "b"
	b.opens = "tor1"
	b.position = Vector2(400, 208)
	var g := Gate.new()
	g.gate_name = "tor1"
	g.position = Vector2(600, 200)
	for n in [a, b, g]:
		w.world.add_child(n)
	w.sibling.position = Vector2(700, 199)
	w.sibling.mode = "stay"
	w.sibling.stay_x = 700.0
	await _frames(6)
	assert_true(a.active)
	assert_false(g.is_open)
	w.sibling.position = Vector2(400, 199)
	w.sibling.stay_x = 400.0
	await _frames(6)
	assert_true(g.is_open)
	w.world.queue_free()


func test_solo_mode_no_sibling_in_battle() -> void:
	var w := _world()
	GameState.set_flag("solo_mode")
	await _frames(2)
	assert_false(w.sibling.visible)
	assert_false(w.sibling.command())
	assert_eq(GameState.party(), [GameState.hero_id])
	GameState.reset()
	w.world.queue_free()


func test_gate_stays_open_once_both_plates_pressed() -> void:
	var w := _world()
	var a := PressurePlate.new()
	a.plate_name = "a"
	a.opens = "tor1"
	a.position = Vector2(200, 208)
	var b := PressurePlate.new()
	b.plate_name = "b"
	b.opens = "tor1"
	b.position = Vector2(400, 208)
	var g := Gate.new()
	g.gate_name = "tor1"
	g.flag = "tor_offen:testraum:tor1"
	g.position = Vector2(600, 200)
	for n in [a, b, g]:
		w.world.add_child(n)
	w.sibling.mode = "stay"
	w.sibling.stay_x = 400.0
	w.sibling.position = Vector2(400, 199)
	await _frames(6)
	assert_true(g.is_open, "beide Platten belegt")
	w.player.position = Vector2(700, 199)
	await _frames(6)
	assert_false(a.active)
	assert_true(g.is_open, "Tor bleibt offen, wenn man die Platte verlässt")
	assert_true(GameState.get_flag("tor_offen:testraum:tor1"), "gemerkt für später")
	w.world.queue_free()


func test_gate_open_from_flag() -> void:
	GameState.reset()
	GameState.set_flag("tor_offen:testraum:tor1")
	var g := Gate.new()
	g.gate_name = "tor1"
	g.flag = "tor_offen:testraum:tor1"
	var root := Node2D.new()
	root.add_child(g)
	tree.root.add_child(root)
	await _frames(2)
	assert_true(g.is_open)
	root.queue_free()
	GameState.reset()


func _pit_world() -> Dictionary:
	GameState.reset()
	RoomManager.room_dir = "res://tests/rooms"
	var world := Node2D.new()
	tree.root.add_child(world)
	var p: Player = load("res://world/player.tscn").instantiate()
	p.test_control = true
	RoomManager.attach(world, p)
	RoomManager.go_to("t_pit", "", "start", Vector2i(4, 14))
	var s := Sibling.new()
	s.player = p
	world.add_child(s)
	return {"world": world, "player": p, "sibling": s}


func _in_spikes(s: Sibling) -> bool:
	var feet := Vector2i(floori(s.position.x / 16.0), floori((s.position.y - 1) / 16.0))
	return RoomManager.current_def.tile_at(feet) == RoomBuilder.HAZARD


func test_sibling_jumps_over_spike_pit() -> void:
	var w := _pit_world()
	# Abstand 144 px (< 160): kein Hinterherbeamen, das Geschwister muss selbst laufen
	w.sibling.position = RoomBuilder.cell_to_pos(Vector2i(5, 14))
	w.player.position = RoomBuilder.cell_to_pos(Vector2i(14, 14))
	var touched := false
	for i in 150:
		await tree.physics_frame
		touched = touched or _in_spikes(w.sibling)
	assert_false(touched, "nie in den Stacheln")
	assert_true(w.sibling.position.x > 12 * 16, "über die Grube hinweg: %s" % w.sibling.position.x)
	w.world.queue_free()
	RoomManager.room_dir = "res://data/rooms"


func test_sibling_does_not_wait_inside_pit() -> void:
	var w := _pit_world()
	# Spieler steht direkt hinter der Grube: der Platz 24 px hinter ihm läge in den Stacheln
	w.player.position = RoomBuilder.cell_to_pos(Vector2i(12, 14))
	w.player.facing = 1
	w.sibling.position = RoomBuilder.cell_to_pos(Vector2i(6, 14))
	for i in 120:
		await tree.physics_frame
	assert_false(_in_spikes(w.sibling), "wartet neben der Grube, nicht darin")
	w.world.queue_free()
	RoomManager.room_dir = "res://data/rooms"


func test_sibling_rescued_from_spikes() -> void:
	var w := _pit_world()
	w.player.position = RoomBuilder.cell_to_pos(Vector2i(16, 14))
	w.sibling.position = RoomBuilder.cell_to_pos(Vector2i(10, 15))
	for i in 4:
		await tree.physics_frame
	assert_false(_in_spikes(w.sibling), "sofort aus den Stacheln geholt")
	w.world.queue_free()
	RoomManager.room_dir = "res://data/rooms"
