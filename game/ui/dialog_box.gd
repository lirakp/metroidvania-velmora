class_name DialogBox
extends CanvasLayer
## Zeigt Dialogzeilen aus res://data/dialog.json. {held}/{geschwister} werden ersetzt. Pausiert das Spiel.

signal finished

static var _cache: Dictionary = {}

var lines: Array = []
var _i := 0
var _closed := false
var _speaker: Label
var _text: Label


static func all_dialogs() -> Dictionary:
	if _cache.is_empty():
		_cache = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialog.json"))
	return _cache


static func _fill(s: String) -> String:
	return s.replace("{held}", DB.hero(GameState.hero_id).name).replace("{geschwister}", DB.hero(GameState.companion_id).name)


static func lines_for(id: String) -> Array:
	var out := []
	for l in all_dialogs().get(id, []):
		out.append({"speaker": _fill(l.speaker), "text": _fill(l.text)})
	return out


static func show_dialog(parent: Node, id: String) -> DialogBox:
	var box := DialogBox.new()
	box.lines = lines_for(id)
	parent.get_tree().root.add_child(box)
	return box


func _ready() -> void:
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	if lines.is_empty():
		_closed = true
		finished.emit.call_deferred()
		queue_free()
		return
	GameState.pause_push()
	var panel := ColorRect.new()
	panel.color = Color("0b0c10")
	panel.position = Vector2(20, 196)
	panel.size = Vector2(440, 64)
	add_child(panel)
	var frame := ReferenceRect.new()
	frame.border_color = Color("4f141c")
	frame.editor_only = false
	frame.position = panel.position
	frame.size = panel.size
	add_child(frame)
	_speaker = Label.new()
	_speaker.position = Vector2(28, 198)
	BattleScene._style_label(_speaker, Color("d9a441"))
	add_child(_speaker)
	var more := Label.new()
	more.text = "[Leertaste]"
	more.position = Vector2(404, 248)
	BattleScene._style_label(more, Color("6b7384"))
	add_child(more)
	_text = Label.new()
	_text.position = Vector2(28, 210)
	_text.size = Vector2(424, 46)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	BattleScene._style_label(_text, Color("d6d9de"))
	add_child(_text)
	_show()


func _show() -> void:
	_speaker.text = lines[_i].speaker
	_text.text = lines[_i].text


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("springen") or event.is_action_pressed("schlagen"):
		get_viewport().set_input_as_handled()
		_i += 1
		if _i >= lines.size():
			_close()
		else:
			_show()


func _close() -> void:
	if _closed:
		return
	_closed = true
	GameState.pause_pop()
	finished.emit()
	queue_free()
