extends TestCase

var tree: SceneTree = Engine.get_main_loop()


func _setup() -> Node2D:
	GameState.reset()
	RoomManager.room_dir = "res://tests/rooms"
	var world := Node2D.new()
	tree.root.add_child(world)
	var p: Player = load("res://world/player.tscn").instantiate()
	p.test_control = true
	RoomManager.attach(world, p)
	return world


func test_go_to_places_player_at_counter_exit() -> void:
	var w := _setup()
	RoomManager.go_to("t_a", "")
	assert_eq(RoomManager.current_def.id, "t_a")
	assert_eq(RoomManager.player.position, RoomBuilder.cell_to_pos(Vector2i(0, 14)))
	RoomManager.go_to("t_b", "L1")
	assert_eq(RoomManager.current_def.id, "t_b")
	assert_eq(RoomManager.player.position, RoomBuilder.cell_to_pos(Vector2i(1, 14)))
	assert_eq(w.get_children().filter(func(n): return n.name.begins_with("Room_")).size(), 1)
	w.queue_free()


func test_discovered_marked() -> void:
	var w := _setup()
	RoomManager.go_to("t_a", "")
	assert_true(GameState.discovered_rooms.has("t_a"))
	assert_false(GameState.discovered_rooms.has("t_b"))
	w.queue_free()


func test_walking_off_edge_changes_room() -> void:
	var w := _setup()
	RoomManager.go_to("t_a", "")
	RoomManager.player.position = Vector2(30 * 16 + 4, 15 * 16)
	RoomManager.check_exits()
	await tree.process_frame
	assert_eq(RoomManager.current_def.id, "t_b")
	w.queue_free()


func test_dungeon_locks_exit() -> void:
	var w := _setup()
	RoomManager.go_to("t_a", "")
	RoomManager.go_to("t_b", "L1")
	assert_true(GameState.get_flag("dungeon_locked:td"))
	assert_true(RoomManager.exit_locked(RoomManager.current_def, RoomManager.current_def.exit_by_id("L1")))
	assert_false(RoomManager.exit_locked(RoomManager.current_def, RoomManager.current_def.exit_by_id("R2")))
	w.queue_free()


func test_dungeon_unlocks_after_clear() -> void:
	var w := _setup()
	RoomManager.go_to("t_a", "")
	RoomManager.go_to("t_b", "L1")
	GameState.clear_dungeon("td")
	assert_false(RoomManager.exit_locked(RoomManager.current_def, RoomManager.current_def.exit_by_id("L1")))
	w.queue_free()


func test_cleared_dungeon_closed_without_zeitsplitter() -> void:
	var w := _setup()
	GameState.clear_dungeon("td")
	RoomManager.go_to("t_a", "")
	var e := RoomManager.current_def.exit_by_id("R1")
	assert_true(RoomManager.exit_locked(RoomManager.current_def, e))
	GameState.abilities["zeitsplitter"] = true
	assert_false(RoomManager.exit_locked(RoomManager.current_def, e))
	w.queue_free()


func test_state_roundtrip() -> void:
	GameState.reset()
	GameState.gold = 77
	GameState.set_flag("x", 3)
	GameState.discovered_rooms["a"] = true
	var d := GameState.to_dict()
	GameState.reset()
	GameState.from_dict(JSON.parse_string(JSON.stringify(d)))
	assert_eq(GameState.gold, 77)
	assert_eq(GameState.get_flag("x"), 3)
	assert_true(GameState.discovered_rooms.has("a"))


func test_enter_door_places_player() -> void:
	var w := _setup()
	RoomManager.go_to("t_a", "")
	RoomManager.enter_door("t_i", "aussen")
	assert_eq(RoomManager.current_def.id, "t_i")
	assert_eq(RoomManager.player.position, RoomBuilder.cell_to_pos(Vector2i(5, 14)))
	RoomManager.enter_door("t_a", "haus")
	assert_eq(RoomManager.current_def.id, "t_a")
	assert_eq(RoomManager.player.position, RoomBuilder.cell_to_pos(Vector2i(10, 14)))
	w.queue_free()


func test_door_node_built_and_blocked_while_paused() -> void:
	var w := _setup()
	RoomManager.go_to("t_a", "")
	var doors := RoomManager.current.get_children().filter(func(n): return n is Door)
	assert_eq(doors.size(), 1)
	GameState.pause_push()
	assert_false(doors[0].try_enter())
	GameState.pause_reset()
	RoomManager.block_doors(0.0)
	assert_true(doors[0].try_enter())
	await tree.process_frame
	assert_eq(RoomManager.current_def.id, "t_i")
	w.queue_free()


func test_door_blocked_right_after_arrival() -> void:
	var w := _setup()
	RoomManager.go_to("t_a", "")
	RoomManager.enter_door("t_i", "aussen")
	var doors := RoomManager.current.get_children().filter(func(n): return n is Door)
	assert_false(doors[0].try_enter(), "gleicher Tastendruck darf nicht sofort zurückführen")
	w.queue_free()
