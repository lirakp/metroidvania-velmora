class_name Door
extends Area2D
## Durchgang in den Hintergrund (Haustür, Öffnung in der Wand): [W]/↑ betritt den Raum dahinter.

var door_id := ""
var target := ""  # "<raum>:<tür-id>"
var _inside := false
var _hint: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(20, 40)
	s.shape = r
	s.position = Vector2(0, -20)
	add_child(s)
	_hint = Label.new()
	_hint.text = "[W]"
	_hint.position = Vector2(-8, -60)
	_hint.visible = false
	BattleScene._style_label(_hint, Color("d9a441"))
	add_child(_hint)
	body_entered.connect(func(b): if b is Player: _inside = true; _hint.visible = true)
	body_exited.connect(func(b): if b is Player: _inside = false; _hint.visible = false)


func _process(_d: float) -> void:
	if _inside and Input.is_action_just_pressed("interagieren"):
		try_enter()


## Wechselt in den Zielraum, wenn nichts dagegen spricht (Pause, Kampf, gerade erst angekommen).
func try_enter() -> bool:
	if get_tree().paused or BattleLauncher.busy or RoomManager.doors_blocked():
		return false
	var to := target.split(":")
	if to.size() != 2:
		return false
	RoomManager.enter_door.call_deferred(to[0], to[1])
	return true
