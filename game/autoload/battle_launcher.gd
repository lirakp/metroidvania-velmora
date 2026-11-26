extends Node
## Startet Kämpfe aus der Welt heraus (Autoload „BattleLauncher“).
## Der Kampfplatz liegt als eigene Ebene über dem pausierten Raum.

signal battle_ended(outcome: String)
signal boss_defeated(area: String)
## Nach jedem Sieg: IDs der besiegten Gegner (für Jagd-Aufträge).
signal enemies_defeated(ids: Array)

const GRACE := 1.0

var test_mode := false
var busy := false
var last_opening := ""
var last_enemy_ids: Array = []
var _enemy: FieldEnemy
var _grace_until := 0.0
var _layer: CanvasLayer
var _scene: BattleScene


func reset_for_test() -> void:
	test_mode = true
	busy = false
	last_opening = ""
	last_enemy_ids = []
	_grace_until = 0.0


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func start(enemy: FieldEnemy, opening: String) -> bool:
	if busy or _now() < _grace_until or not is_instance_valid(enemy) or get_tree().paused:
		return false
	busy = true
	_enemy = enemy
	last_opening = opening
	last_enemy_ids = enemy.enemy_ids
	if test_mode:
		return true
	_layer = CanvasLayer.new()
	_layer.layer = 10
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var scene: BattleScene = load("res://battle/battle_scene.tscn").instantiate()
	scene.process_mode = Node.PROCESS_MODE_ALWAYS
	_layer.add_child(scene)
	get_tree().root.add_child(_layer)
	var biome := "kornfeld"
	var room := enemy.get_parent()
	if room and room.has_meta("room_def"):
		biome = room.get_meta("room_def").biome
	scene.setup(GameState.party(), enemy.enemy_ids, opening, biome, GameState.party_equipment())
	for h in scene.state.heroes:
		if GameState.hp.has(h.id):
			h.hp = clampi(int(GameState.hp[h.id]), 1, h.max_hp)
	scene._refresh()
	_scene = scene
	scene.battle_finished.connect(finish)
	GameState.pause_push()
	return true


func finish(outcome: String, result: BattleResult) -> void:
	busy = false
	_grace_until = _now() + GRACE
	if not test_mode:
		GameState.pause_pop()
		if is_instance_valid(_layer):
			_layer.queue_free()
	if outcome != "niederlage" and is_instance_valid(_scene):
		for h in _scene.state.heroes:
			GameState.hp[h.id] = maxi(1, h.hp)
	match outcome:
		"sieg":
			if is_instance_valid(_enemy) and _enemy.is_boss:
				var area := ""
				var room := _enemy.get_parent()
				if room and room.has_meta("room_def"):
					area = room.get_meta("room_def").area
				GameState.clear_dungeon(area)
				RoomManager.refresh_locks()
				boss_defeated.emit(area)
			if is_instance_valid(_enemy):
				GameState.set_flag("defeated:%s:%d" % [_enemy.room_id, _enemy.index])
				_enemy.queue_free()
			GameState.gold += result.silver
			GameState.xp += result.xp
			for d in result.drops:
				GameState.add_item(d)
			Quests.on_defeated(last_enemy_ids)
			enemies_defeated.emit(last_enemy_ids.duplicate())
		"niederlage":
			if GameState.has_method("on_death"):
				GameState.on_death()
	battle_ended.emit(outcome)
