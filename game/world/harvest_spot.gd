class_name HarvestSpot
extends Area2D
## Sammelstelle (Grafik welt/sammeln): davorstellen und [W] drücken erntet.
## Danach bleibt sie leer, bis beim Rasten der Merker gelöscht wird; beim nächsten Besuch wächst sie sichtbar nach.

const COOLDOWN := 0.35

var kind := ""
var amount := 1
var flag := ""
var sprite: AnimatedSprite2D
var _inside := false
var _hint: Label
var _blocked_until := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(24, 28)
	s.shape = r
	s.position = Vector2(0, -14)
	add_child(s)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = CosyArt.harvest_frames(kind)
	sprite.offset = CosyArt.harvest_offset()
	add_child(sprite)
	var info: Dictionary = CosyArt.meta("welt/sammeln/sammeln.json").items.get(kind, {})
	if info.get("leuchtet", false):
		var l := Stimmung.light("lampe")
		l.texture_scale *= 0.35
		l.energy *= 0.6
		l.position = Vector2(0, -10)
		add_child(l)
	_hint = Label.new()
	_hint.text = "[W]"
	_hint.position = Vector2(-8, -44)
	_hint.visible = false
	BattleScene._style_label(_hint, Color("d9a441"))
	add_child(_hint)
	var seen := _seen_flag()
	if GameState.get_flag(flag):
		sprite.play("leer")
		GameState.set_flag(seen)
	elif GameState.get_flag(seen):
		GameState.flags.erase(seen)
		sprite.play("nachwachsen")
		sprite.animation_finished.connect(func(): sprite.play("idle"), CONNECT_ONE_SHOT)
	else:
		sprite.play("idle")
	body_entered.connect(func(b): if b is Player: _inside = true; _update_hint())
	body_exited.connect(func(b): if b is Player: _inside = false; _update_hint())


func _seen_flag() -> String:
	return flag.replace("geerntet:", "gesehen_leer:")


func _update_hint() -> void:
	_hint.visible = _inside and not GameState.get_flag(flag)


func can_interact() -> bool:
	return not get_tree().paused and Time.get_ticks_msec() / 1000.0 >= _blocked_until


func _process(_d: float) -> void:
	if _inside and can_interact() and Input.is_action_just_pressed("interagieren"):
		_blocked_until = Time.get_ticks_msec() / 1000.0 + COOLDOWN
		harvest()


## Erntet einmal: Vorrat + amount, Merker setzen, Ernte-Animation. false, wenn schon leer.
func harvest() -> bool:
	if GameState.get_flag(flag):
		return false
	GameState.set_flag(flag)
	GameState.add_item(kind, amount)
	sprite.play("ernten")
	sprite.animation_finished.connect(func(): sprite.play("leer"), CONNECT_ONE_SHOT)
	_update_hint()
	if is_inside_tree() and DB.items.has(kind):
		ChoiceMenu.toast(self, "+%d %s" % [amount, DB.item(kind).name])
	return true
