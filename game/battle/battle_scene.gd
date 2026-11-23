class_name BattleScene
extends Node2D
## Eigener Kampfplatz: Helden links, Gegner rechts, Zugleiste oben, Menü unten.

signal battle_finished(outcome: String, result: BattleResult)

const ACTION_DELAY := 0.6
const MENU := ["Angriff", "Technik", "Zauber", "Gegenstand", "Verteidigen", "Fliehen"]

var state: BattleState
var background := "kornfeld"
var in_dungeon := false
var auto := false

var _ui: CanvasLayer
var _log_label: Label
var _turn_bar: HBoxContainer
var _menu_box: GridContainer
var _status_box: VBoxContainer
var _sprites := {}
var _wait := 0.0
var _finished := false
var _mode := "idle"  # idle | menu | spells | target
var _menu_index := 0
var _spell_index := 0
var _target_index := 0
var _pending: Dictionary = {}
var _log: Array[String] = []


func setup(hero_ids: Array, enemy_ids: Array, opening: String, p_background: String, equipment := {}) -> void:
	background = p_background
	in_dungeon = p_background.begins_with("dungeon")
	state = BattleState.new()
	for h in hero_ids:
		state.heroes.append(Combatant.from_hero(h, equipment.get(h, [])))
	for e in enemy_ids:
		state.enemies.append(Combatant.from_enemy(e))
	state.start(opening)
	_build()
	match opening:
		"erstschlag":
			_push_log(["Erstschlag! Die Gegner sind benommen."])
		"ueberfall":
			_push_log(["Überfall! Die Gegner handeln zuerst."])
		_:
			_push_log(["Der Kampf beginnt."])


func auto_play_for_test() -> void:
	auto = true


func can_flee() -> bool:
	return not in_dungeon and not state.enemies.any(func(e): return e.is_boss)


func spell_entries(c: Combatant) -> Array:
	var out := []
	for sid in c.spells:
		var sp: Dictionary = DB.spell(sid)
		var cost := ""
		match sp.flow:
			"C":
				cost = "%d C" % sp.cost
			"S":
				cost = "%d S" % sp.cost
			_:
				cost = "%d C + %d S" % [BattleState.split_cost(sp.cost), BattleState.split_cost(sp.cost)]
		out.append({"id": sid, "label": "%s (%s)" % [sp.name, cost], "enabled": state.can_cast(c, sid), "target": sp.target})
	return out


# ---------------------------------------------------------------- Aufbau
func _build() -> void:
	for ch in get_children():
		ch.queue_free()
	add_child(Backdrop.make(background))
	var ground := ColorRect.new()
	ground.color = Color("14161d")
	ground.position = Vector2(0, 196)
	ground.size = Vector2(480, 74)
	add_child(ground)
	for i in state.heroes.size():
		_add_sprite(state.heroes[i], Vector2(110 - i * 40, 194), Player.FRAME.x, Player.FRAME.y)
	for i in state.enemies.size():
		var e := state.enemies[i]
		var s := 64 if e.is_boss else 32
		_add_sprite(e, Vector2(330 + i * 44, 194), s, s)
	_ui = CanvasLayer.new()
	_ui.layer = 11
	add_child(_ui)
	_turn_bar = HBoxContainer.new()
	_turn_bar.position = Vector2(8, 6)
	_turn_bar.add_theme_constant_override("separation", 3)
	_ui.add_child(_turn_bar)
	var panel := ColorRect.new()
	panel.color = Color("0b0c10")
	panel.position = Vector2(0, 204)
	panel.size = Vector2(480, 66)
	_ui.add_child(panel)
	_status_box = VBoxContainer.new()
	_status_box.position = Vector2(6, 206)
	_status_box.add_theme_constant_override("separation", 1)
	_ui.add_child(_status_box)
	_menu_box = GridContainer.new()
	_menu_box.position = Vector2(184, 207)
	_menu_box.add_theme_constant_override("v_separation", -2)
	_menu_box.add_theme_constant_override("h_separation", 6)
	_ui.add_child(_menu_box)
	_log_label = Label.new()
	_log_label.position = Vector2(330, 206)
	_log_label.custom_minimum_size = Vector2(146, 60)
	_log_label.size = Vector2(146, 60)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(_log_label, Color("b3b9c4"))
	_ui.add_child(_log_label)
	_refresh()


func _add_sprite(c: Combatant, feet: Vector2, w: int, h: int) -> void:
	var sp := Sprite2D.new()
	var folder := "chars" if c.is_hero else "enemies"
	sp.texture = load("res://art/%s/%s.png" % [folder, c.art])
	sp.region_enabled = true
	sp.region_rect = Rect2(0, 0, w, h)
	sp.centered = false
	sp.position = feet - Vector2(w / 2.0, h)
	sp.flip_h = not c.is_hero and false
	add_child(sp)
	_sprites[c] = sp


static func _style_label(l: Label, color: Color, size := 8) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)


func _bar(parent: Node, value: int, maxv: int, color: Color, width := 60) -> void:
	var back := ColorRect.new()
	back.color = Color("272b36")
	back.custom_minimum_size = Vector2(width, 3)
	var fill := ColorRect.new()
	fill.color = color
	fill.size = Vector2(width * clampf(float(value) / maxf(1, maxv), 0, 1), 3)
	back.add_child(fill)
	parent.add_child(back)


func _refresh() -> void:
	for ch in _status_box.get_children():
		ch.queue_free()
	for h in state.heroes:
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = "%s %d/%d" % [h.name, h.hp, h.max_hp]
		l.custom_minimum_size = Vector2(110, 0)
		_style_label(l, Color("d6d9de") if h.is_alive() else Color("525a6b"))
		row.add_child(l)
		var bars := VBoxContainer.new()
		bars.add_theme_constant_override("separation", 1)
		_bar(bars, h.hp, h.max_hp, Color("a3202b"))
		_bar(bars, h.mana_c, h.max_mana_c, Color("52678a"))
		_bar(bars, h.mana_s, h.max_mana_s, Color("b3b9c4"))
		row.add_child(bars)
		_status_box.add_child(row)
	for ch in _turn_bar.get_children():
		ch.queue_free()
	var order := state.turn_order()
	for i in mini(6, order.size()):
		var c: Combatant = order[i]
		var tile := ColorRect.new()
		tile.custom_minimum_size = Vector2(36, 12)
		tile.color = Color("4f141c") if not c.is_hero else Color("3a4a63")
		var l := Label.new()
		l.text = c.name.substr(0, 6)
		_style_label(l, Color("f0d9a0") if i == 0 else Color("d6d9de"))
		l.position = Vector2(2, -1)
		tile.add_child(l)
		_turn_bar.add_child(tile)
	for c in _sprites:
		_sprites[c].modulate = Color(1, 1, 1, 1) if c.is_alive() else Color(1, 1, 1, 0.15)
	_log_label.text = "\n".join(_log.slice(maxi(0, _log.size() - 3)))
	_draw_menu()


func _draw_menu() -> void:
	for ch in _menu_box.get_children():
		ch.queue_free()
	var entries: Array = []
	_menu_box.columns = 2 if _mode == "menu" else 1
	match _mode:
		"menu":
			for i in MENU.size():
				entries.append({"label": MENU[i], "enabled": _menu_enabled(i)})
			_add_entries(entries, _menu_index)
		"spells":
			_add_entries(spell_entries(_actor()), _spell_index)
		"target":
			var targets := _targets()
			for t in targets:
				entries.append({"label": "%s (%d LP)" % [t.name, t.hp], "enabled": true})
			_add_entries(entries, _target_index)


func _add_entries(entries: Array, selected: int) -> void:
	for i in entries.size():
		var l := Label.new()
		l.text = ("> " if i == selected else "  ") + entries[i].label
		var col := Color("f0d9a0") if i == selected else Color("d6d9de")
		if not entries[i].enabled:
			col = Color("525a6b")
		_style_label(l, col)
		_menu_box.add_child(l)


func _menu_enabled(i: int) -> bool:
	match MENU[i]:
		"Gegenstand":
			return false
		"Fliehen":
			return can_flee()
	return true


# ---------------------------------------------------------------- Ablauf
func _actor() -> Combatant:
	return state.current_actor()


func _targets() -> Array:
	if _pending.get("target_kind", "enemy") == "ally":
		return state.heroes.filter(func(h): return h.is_alive())
	return state.enemies.filter(func(e): return e.is_alive())


func _push_log(lines: Array) -> void:
	for l in lines:
		_log.append(l)


func _process(delta: float) -> void:
	if state == null or _finished:
		return
	if _wait > 0.0 and not auto:
		_wait -= delta
		return
	var o := state.outcome()
	if o != "laeuft":
		_finish(o)
		return
	var c := _actor()
	if c == null:
		return
	if not c.is_hero:
		_push_log(state.step())
		_wait = ACTION_DELAY
		_refresh()
	elif auto:
		_push_log(state.submit({"action": "attack", "target": _targets()[0]}))
		_refresh()
	elif _mode == "idle":
		_mode = "menu"
		_menu_index = 0
		_refresh()


func _finish(o: String) -> void:
	_finished = true
	var r := state.result() if o == "sieg" else BattleResult.new()
	if o == "sieg":
		_push_log(["Sieg! %d Silber erbeutet." % r.silver])
	elif o == "niederlage":
		_push_log(["Eure Plaketten werden schwarz ..."])
	_mode = "idle"
	_refresh()
	if not auto:
		await get_tree().create_timer(1.2).timeout
	battle_finished.emit(o, r)


func _unhandled_input(event: InputEvent) -> void:
	if _mode == "idle" or _finished or auto:
		return
	var count := 0
	match _mode:
		"menu":
			count = MENU.size()
		"spells":
			count = _actor().spells.size()
		"target":
			count = _targets().size()
	if event.is_action_pressed("ui_down"):
		_move(1, count)
	elif event.is_action_pressed("ui_up"):
		_move(-1, count)
	elif event.is_action_pressed("ui_accept"):
		_accept()
	elif event.is_action_pressed("ui_cancel"):
		_mode = "menu"
		_refresh()
	else:
		return
	get_viewport().set_input_as_handled()


func _move(d: int, count: int) -> void:
	match _mode:
		"menu":
			_menu_index = posmod(_menu_index + d, count)
		"spells":
			_spell_index = posmod(_spell_index + d, count)
		"target":
			_target_index = posmod(_target_index + d, count)
	_refresh()


func _accept() -> void:
	match _mode:
		"menu":
			if not _menu_enabled(_menu_index):
				return
			match MENU[_menu_index]:
				"Angriff":
					_pending = {"action": "attack", "target_kind": "enemy"}
					_to_target()
				"Technik":
					_pending = {"action": "technik", "target_kind": "enemy"}
					_to_target()
				"Zauber":
					_mode = "spells"
					_spell_index = 0
					_refresh()
				"Verteidigen":
					_do({"action": "defend"})
				"Fliehen":
					_push_log(["Ihr flieht."])
					_finished = true
					battle_finished.emit("flucht", BattleResult.new())
		"spells":
			var e: Dictionary = spell_entries(_actor())[_spell_index]
			if not e.enabled:
				return
			_pending = {"action": "cast", "spell": e.id, "target_kind": e.target}
			_to_target()
		"target":
			var a := _pending.duplicate()
			a.target = _targets()[_target_index]
			_do(a)


func _to_target() -> void:
	_mode = "target"
	_target_index = 0
	_refresh()


func _do(action: Dictionary) -> void:
	_mode = "idle"
	_push_log(state.submit(action))
	_wait = ACTION_DELAY
	_refresh()


func _ready() -> void:
	if state == null and get_tree().current_scene == self:
		setup(["warschick", "lira"], ["goblin", "gruenschleim"], "erstschlag", "kornfeld")
