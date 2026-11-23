class_name ChoiceMenu
extends CanvasLayer
## Einfaches Auswahlmenü (pausiert das Spiel, solange es offen ist).

signal chosen(index: int)

var title := ""
var options: Array = []
## Index, den Esc auswählt (Standard: letzte Option).
var cancel_index := -1
var _index := 0
var _box: VBoxContainer


static func open(parent: Node, p_title: String, p_options: Array, p_cancel := -1) -> ChoiceMenu:
	var m := ChoiceMenu.new()
	m.title = p_title
	m.options = p_options
	m.cancel_index = p_cancel
	parent.get_tree().root.add_child(m)
	return m


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.pause_push()
	var panel := ColorRect.new()
	panel.color = Color("0b0c10")
	panel.position = Vector2(140, 70)
	panel.size = Vector2(200, 24 + 11 * options.size())
	add_child(panel)
	var frame := ReferenceRect.new()
	frame.border_color = Color("8a6a2a")
	frame.editor_only = false
	frame.position = panel.position
	frame.size = panel.size
	add_child(frame)
	_box = VBoxContainer.new()
	_box.position = panel.position + Vector2(8, 4)
	_box.add_theme_constant_override("separation", -2)
	add_child(_box)
	_draw()


func _draw() -> void:
	for c in _box.get_children():
		c.queue_free()
	var t := Label.new()
	t.text = title
	BattleScene._style_label(t, Color("d9a441"))
	_box.add_child(t)
	for i in options.size():
		var l := Label.new()
		l.text = ("> " if i == _index else "  ") + str(options[i])
		BattleScene._style_label(l, Color("f0d9a0") if i == _index else Color("d6d9de"))
		_box.add_child(l)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		_index = posmod(_index + 1, options.size())
		_draw()
	elif event.is_action_pressed("ui_up"):
		_index = posmod(_index - 1, options.size())
		_draw()
	elif event.is_action_pressed("ui_accept"):
		close(_index)
	elif event.is_action_pressed("ui_cancel"):
		close(cancel_index if cancel_index >= 0 else options.size() - 1)
	else:
		return
	get_viewport().set_input_as_handled()


func close(i: int) -> void:
	if is_queued_for_deletion():
		return
	GameState.pause_pop()
	chosen.emit(i)
	queue_free()


## Kurze Einblendung am oberen Bildrand.
static func toast(parent: Node, text: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 21
	var l := Label.new()
	l.text = text
	l.position = Vector2(8, 24)
	BattleScene._style_label(l, Color("f0d9a0"))
	layer.add_child(l)
	parent.get_tree().root.add_child(layer)
	parent.get_tree().create_timer(2.0).timeout.connect(layer.queue_free)
