class_name MapView
extends CanvasLayer
## Kartenansicht: nur mit gekaufter/gefundener Gebietskarte. Besuchte Räume gefüllt, aktueller Raum markiert.

const CELL := Vector2(24, 14)

var area := ""
var _layout := {}
var _canvas: Control


static func toggle(parent: Node) -> void:
	for n in parent.get_tree().root.get_children():
		if n is MapView:
			n.close()
			return
	var m := MapView.new()
	m.area = RoomManager.current_def.area if RoomManager.current_def else ""
	parent.get_tree().root.add_child(m)


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.pause_push()
	if GameState.owned_maps.has(area):
		_layout = WorldMap.layout(area, RoomManager.room_dir)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.06, 0.92)
	bg.size = Vector2(480, 270)
	add_child(bg)
	_canvas = Control.new()
	_canvas.size = Vector2(480, 270)
	_canvas.draw.connect(_draw_map)
	add_child(_canvas)
	var title := Label.new()
	title.position = Vector2(8, 4)
	title.text = "Karte: %s" % AREA_NAMES.get(area, area.capitalize())
	BattleScene._style_label(title, Color("d9a441"))
	add_child(title)
	var hint := Label.new()
	hint.position = Vector2(8, 254)
	hint.text = "[M] schließen   ■ besucht   □ unbekannt   ◆ Plakette"
	BattleScene._style_label(hint, Color("8b93a3"))
	add_child(hint)


const AREA_NAMES := {"kornburg": "Kornburg", "blutdungeon": "Blut-Dungeon der Mühle"}


func _draw_map() -> void:
	if _layout.is_empty():
		_canvas.draw_string(ThemeDB.fallback_font, Vector2(150, 135), "Keine Karte von diesem Gebiet.", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("b3b9c4"))
		return
	var minp := Vector2i(999, 999)
	var maxp := Vector2i(-999, -999)
	for r in _layout.values():
		minp = Vector2i(mini(minp.x, r.position.x), mini(minp.y, r.position.y))
		maxp = Vector2i(maxi(maxp.x, r.end.x), maxi(maxp.y, r.end.y))
	var total := Vector2(maxp - minp) * CELL
	var origin := (Vector2(480, 270) - total) / 2.0
	for id in _layout:
		var r: Rect2i = _layout[id]
		var rect := Rect2(origin + Vector2(r.position - minp) * CELL, Vector2(r.size) * CELL).grow(-1)
		if GameState.discovered_rooms.has(id):
			_canvas.draw_rect(rect, Color("3a4a63"))
		_canvas.draw_rect(rect, Color("8b93a3"), false, 1.0)
		if id == GameState.room_id:
			_canvas.draw_circle(rect.get_center(), 3, Color("a3202b"))
		for p in GameState.plaketten.placed:
			if p.room == id:
				_canvas.draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(4, 4)), Color("d9a441"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("karte") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	if is_queued_for_deletion():
		return
	GameState.pause_pop()
	queue_free()
