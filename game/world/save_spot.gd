class_name SaveSpot
extends Area2D
## Gildenhalle oder Rastort: Plakette ablegen, speichern, rasten. Nur hier kann gespeichert werden.

const KEYS := ["plakette", "speichern", "rasten", "zurueck"]

var room_id := ""
var cell := Vector2i.ZERO
var kind := "rastort"
var _player_inside := false
var _blocked_until := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(24, 24)
	s.shape = r
	s.position = Vector2(0, -12)
	add_child(s)
	body_entered.connect(func(b): if b is Player: _player_inside = true)
	body_exited.connect(func(b): if b is Player: _player_inside = false)


func options() -> Array:
	var here: bool = GameState.plaketten.respawn_point().get("room", "") == room_id or GameState.plaketten.placed.any(func(p): return p.room == room_id)
	var first := "Plakette liegt hier" if here else "Plakette ablegen (%d übrig)" % GameState.plaketten.spare
	return [first, "Speichern", "Rasten", "Zurück"]


func choose(key: String) -> void:
	match key:
		"plakette":
			if GameState.plaketten.place(room_id, cell):
				_msg("Eure Seelenplakette ruht nun hier.")
			else:
				_msg("Keine Plakette übrig.")
		"speichern":
			GameState.plaketten.use(room_id)
			_msg("Gespeichert." if SaveSystem.save(GameState.to_dict()) else "Speichern fehlgeschlagen!")
		"rasten":
			GameState.hp.clear()
			_msg("Ihr rastet. Wunden und Mana sind erneuert.")


func _msg(t: String) -> void:
	if is_inside_tree():
		ChoiceMenu.toast(self, t)


func _process(_d: float) -> void:
	if _player_inside and not get_tree().paused and Time.get_ticks_msec() / 1000.0 >= _blocked_until and Input.is_action_just_pressed("interagieren"):
		var title := "Gildenhalle" if kind == "gilde" else "Rastort"
		var m := ChoiceMenu.open(self, title, options())
		m.chosen.connect(func(i):
			_blocked_until = Time.get_ticks_msec() / 1000.0 + 0.35
			choose(KEYS[i]))
