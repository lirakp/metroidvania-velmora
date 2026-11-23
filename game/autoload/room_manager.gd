extends Node
## Lädt immer genau einen Raum, wechselt über Ausgänge, setzt die Einweg-Schwelle der Dungeons durch.

signal room_changed(def: RoomDef)

var room_dir := "res://data/rooms"
var world_root: Node2D
var player: Player
var current: Node2D
var current_def: RoomDef
var camera: Camera2D
var _cache := {}
var _entry_pos := Vector2.ZERO


func attach(root: Node2D, p: Player) -> void:
	world_root = root
	player = p
	_cache.clear()
	current = null
	current_def = null
	if p.get_parent() == null:
		root.add_child(p)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	p.add_child(camera)


func def_of(id: String) -> RoomDef:
	if not _cache.has(id):
		_cache[id] = RoomDef.load_file("%s/%s.room" % [room_dir, id])
	return _cache[id]


## Wechselt in room_id. exit_id = Ausgang im Zielraum, an dem der Spieler erscheint; "" = Spawn „start“.
func go_to(room_id: String, exit_id: String, spawn := "start", at_cell := Vector2i(-1, -1)) -> void:
	var def := def_of(room_id)
	if def.error != "":
		push_error(def.error)
		return
	var from_def := current_def
	if current:
		current.free()
	if from_def and not from_def.one_way_dungeon and def.one_way_dungeon:
		GameState.set_flag("dungeon_locked:" + def.area)
	current_def = def
	current = RoomBuilder.build(def)
	world_root.add_child(current)
	world_root.move_child(current, 0)
	EntityFactory.populate(current, def)
	refresh_locks()
	var cell: Vector2i = def.arrival_cell(exit_id) if exit_id != "" else def.spawns.get(spawn, def.spawns.get("start", Vector2i(1, 1)))
	if at_cell.x >= 0:
		cell = at_cell
	player.position = RoomBuilder.cell_to_pos(cell)
	player.velocity = Vector2.ZERO
	_entry_pos = player.position
	GameState.discovered_rooms[room_id] = true
	GameState.room_id = room_id
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = def.size.x * RoomBuilder.TILE
	camera.limit_bottom = def.size.y * RoomBuilder.TILE
	camera.reset_smoothing()
	room_changed.emit(def)


## Setzt Tor-Kacheln an gesperrten Ausgängen bzw. entfernt sie wieder.
func refresh_locks() -> void:
	if current == null or current_def == null:
		return
	var tiles: TileMapLayer = current.get_node("Tiles")
	for e in current_def.exits:
		if exit_locked(current_def, e):
			tiles.set_cell(e.pos, 0, Vector2i(9, 0))
			tiles.set_cell(e.pos - Vector2i(0, 1), 0, Vector2i(9, 0))
		else:
			tiles.erase_cell(e.pos)
			tiles.erase_cell(e.pos - Vector2i(0, 1))


func exit_locked(def: RoomDef, e: Dictionary) -> bool:
	var target := def_of(e.target_room)
	if def.one_way_dungeon and not target.one_way_dungeon:
		return GameState.get_flag("dungeon_locked:" + def.area) == true and GameState.get_flag("dungeon_cleared:" + def.area) != true
	if not def.one_way_dungeon and target.one_way_dungeon:
		return GameState.get_flag("dungeon_cleared:" + target.area) == true and not GameState.has_ability("zeitsplitter")
	return false


## Prüft, ob der Spieler den Raum über eine Kante verlassen hat.
func check_exits() -> void:
	if current_def == null or player == null:
		return
	var cell := Vector2i(floori(player.position.x / RoomBuilder.TILE), floori((player.position.y - 1) / RoomBuilder.TILE))
	var edge := ""
	if cell.x < 0:
		edge = "L"
	elif cell.x >= current_def.size.x:
		edge = "R"
	elif cell.y < 0:
		edge = "T"
	elif cell.y >= current_def.size.y:
		edge = "B"
	if edge == "":
		return
	var best: Dictionary = {}
	var best_d := INF
	for e in current_def.exits:
		if e.edge != edge or exit_locked(current_def, e):
			continue
		var d := float(abs(e.pos.y - cell.y)) if edge in ["L", "R"] else float(abs(e.pos.x - cell.x))
		if d < best_d:
			best_d = d
			best = e
	if best.is_empty():
		player.position = player.position.clamp(Vector2(4, 4), Vector2(current_def.size) * RoomBuilder.TILE - Vector2(4, 1))
		return
	go_to.call_deferred(best.target_room, best.target_exit_id)


func _physics_process(_delta: float) -> void:
	if get_tree().paused or player == null or not is_instance_valid(player) or current_def == null:
		return
	check_exits()
	var feet := Vector2i(floori(player.position.x / RoomBuilder.TILE), floori((player.position.y - 1) / RoomBuilder.TILE))
	if current_def.tile_at(feet) == RoomBuilder.HAZARD:
		player.position = _entry_pos
		player.velocity = Vector2.ZERO
		for h in GameState.party():
			GameState.hp[h] = maxi(1, int(GameState.hp.get(h, DB.hero(h).hp)) - 5)
		ChoiceMenu.toast(player, "Die Stacheln reißen euch zurück. (−5 LP)")
