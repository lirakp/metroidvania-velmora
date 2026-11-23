class_name TitleMenu
extends Node2D
## Titelbildschirm: Neues Spiel · Fortsetzen · Beenden.

signal new_game
signal continue_game

const OPTIONS := ["Neues Spiel", "Fortsetzen", "Beenden"]

var _index := 0
var _labels: Array[Label] = []
var _can_continue := false


func _ready() -> void:
	_can_continue = SaveSystem.exists()
	var bg := Sprite2D.new()
	bg.texture = load("res://art/bg/stadt.png")
	bg.centered = false
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.size = Vector2(480, 270)
	add_child(shade)
	var t := Label.new()
	t.text = "BLUTMOND"
	t.position = Vector2(40, 60)
	BattleScene._style_label(t, Color("a3202b"), 32)
	add_child(t)
	var sub := Label.new()
	sub.text = "Ein Metroidvania aus Velmora"
	sub.position = Vector2(42, 100)
	BattleScene._style_label(sub, Color("b3b9c4"), 8)
	add_child(sub)
	for i in OPTIONS.size():
		var l := Label.new()
		l.position = Vector2(44, 140 + i * 14)
		add_child(l)
		_labels.append(l)
	var age := Label.new()
	age.text = "Ab 18 Jahren · Prototyp"
	age.position = Vector2(42, 250)
	BattleScene._style_label(age, Color("6b7384"), 8)
	add_child(age)
	_draw_options()


func _enabled(i: int) -> bool:
	return i != 1 or _can_continue


func _draw_options() -> void:
	for i in OPTIONS.size():
		_labels[i].text = ("> " if i == _index else "  ") + OPTIONS[i]
		var c := Color("f0d9a0") if i == _index else Color("d6d9de")
		if not _enabled(i):
			c = Color("525a6b")
		BattleScene._style_label(_labels[i], c, 8)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		_index = posmod(_index + 1, OPTIONS.size())
	elif event.is_action_pressed("ui_up"):
		_index = posmod(_index - 1, OPTIONS.size())
	elif event.is_action_pressed("ui_accept"):
		if not _enabled(_index):
			return
		match _index:
			0:
				new_game.emit()
			1:
				continue_game.emit()
			2:
				get_tree().quit()
		return
	else:
		return
	_draw_options()
