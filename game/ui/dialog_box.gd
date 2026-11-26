class_name DialogBox
extends CanvasLayer
## Zeigt Dialogzeilen aus res://data/dialog.json. {held}/{geschwister} werden ersetzt. Pausiert das Spiel.

signal finished

static var _cache: Dictionary = {}

var lines: Array = []
var _i := 0
var portrait: AnimatedSprite2D

const TEXT_X := 76
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
	return show_lines(parent, lines_for(id))


## Zeigt frei zusammengestellte Zeilen [{speaker, text}] (z. B. Auftragstexte).
static func show_lines(parent: Node, p_lines: Array) -> DialogBox:
	var box := DialogBox.new()
	box.lines = p_lines
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
	var frame := UiArt.frame("holz", Vector2(448, 70))
	frame.position = Vector2(16, 192)
	add_child(frame)
	portrait = AnimatedSprite2D.new()
	portrait.centered = false
	portrait.position = Vector2(26, 207)
	add_child(portrait)
	_speaker = Label.new()
	_speaker.position = Vector2(TEXT_X, 198)
	BattleScene._style_label(_speaker, Color("d9a441"))
	add_child(_speaker)
	var more := Label.new()
	more.text = "[Leertaste]"
	more.position = Vector2(400, 248)
	BattleScene._style_label(more, Color("6b7384"))
	add_child(more)
	_text = Label.new()
	_text.position = Vector2(TEXT_X, 210)
	_text.size = Vector2(450 - TEXT_X, 46)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	BattleScene._style_label(_text, Color("d6d9de"))
	add_child(_text)
	_show()


func _show() -> void:
	_speaker.text = lines[_i].speaker
	_text.text = lines[_i].text
	var sheet := portrait_sheet(lines[_i].speaker)
	portrait.visible = sheet != ""
	if sheet != "":
		portrait.sprite_frames = UiArt.portrait_frames(sheet)
		portrait.play("spricht")
		get_tree().create_timer(minf(2.5, 0.05 * lines[_i].text.length())).timeout.connect(func():
			if is_instance_valid(portrait):
				portrait.play("still"))


## Porträt-Sheet zum Sprecher ("" = kein Porträt, z. B. bei Hinweisen).
static func portrait_sheet(speaker: String) -> String:
	for id in DB.heroes:
		if DB.hero(id).name == speaker:
			return DB.hero(id).cosy
	if speaker.begins_with("Gildenmeisterin"):
		return CosyArt.NPC_SHEETS.gildenmeisterin
	if speaker.begins_with("Kartograf"):
		return CosyArt.NPC_SHEETS.kartograf
	return ""


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
