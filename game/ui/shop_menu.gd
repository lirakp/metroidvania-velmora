class_name ShopMenu
extends CanvasLayer
## Ladenfenster: Kopf (Kaufen / Verkaufen / Backen lassen / Zurück), dann Warenliste mit Icon, Name, Preis, Bestand.
## Bleibt nach einem Kauf offen; [Esc] geht eine Ebene zurück.

signal closed

const ROW_H := 18
const VISIBLE_ROWS := 7

var shop_id := ""
var _level := "kopf"  # kopf | kaufen | verkaufen
var _index := 0
var _scroll := 0
var _message := ""
var _box: Control
var _busy := false  # während die Anlege-Abfrage offen ist


static func open(parent: Node, p_shop: String) -> ShopMenu:
	var m := ShopMenu.new()
	m.shop_id = p_shop
	parent.get_tree().root.add_child(m)
	return m


## Waren der Liste: kaufen = Angebot des Ladens, verkaufen = eigener Bestand, den der Laden ankauft.
static func rows(p_shop: String, mode: String) -> Array:
	var out := []
	var ids: Array = []
	if mode == "kaufen":
		ids = Shop.data(p_shop).sells
	else:
		var seen := {}
		for id in GameState.items.keys() + GameState.inventory:
			if not seen.has(id) and Shop.buys(p_shop, id) and Shop.owned(id) > 0:
				seen[id] = true
				ids.append(id)
		ids.sort()
	for id in ids:
		var price := Shop.price_buy(id) if mode == "kaufen" else Shop.price_sell(p_shop, id)
		out.append({"id": id, "name": Shop._name(id), "price": price, "count": Shop.owned(id)})
	return out


func heads() -> Array:
	var out := []
	if not Shop.data(shop_id).sells.is_empty():
		out.append("Kaufen")
	out.append("Verkaufen")
	if Shop.data(shop_id).get("bake", false):
		out.append("Backen lassen")
	out.append("Zurück")
	return out


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.pause_push()
	var frame := UiArt.frame("holz", Vector2(300, 196))
	frame.position = Vector2(90, 36)
	add_child(frame)
	_box = Control.new()
	_box.position = frame.position + Vector2(12, 8)
	add_child(_box)
	_message = Shop.data(shop_id).gruss
	_redraw()


func close() -> void:
	if is_queued_for_deletion():
		return
	GameState.pause_pop()
	closed.emit()
	queue_free()


func _label(text: String, pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	BattleScene._style_label(l, color)
	_box.add_child(l)
	return l


func _entries() -> Array:
	if _level == "kopf":
		return heads()
	return rows(shop_id, _level)


func _redraw() -> void:
	for c in _box.get_children():
		c.queue_free()
	var d := Shop.data(shop_id)
	_label(d.name, Vector2.ZERO, Color("d9a441"))
	_label(GameState.money_text(GameState.gold), Vector2(190, 0), Color("f0d9a0"))
	var msg := _label(_message, Vector2(0, 14), Color("d6d9de"))
	msg.size = Vector2(276, 24)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	var hint := {"kopf": "[Leertaste] wählen · [Esc] schließen", "kaufen": "[Leertaste] kaufen · [Esc] zurück",
		"verkaufen": "[Leertaste] verkaufen · [Esc] zurück"}
	_label(hint[_level], Vector2(0, 168), Color("8b93a3"))
	var y := 44
	var entries := _entries()
	if _level == "kopf":
		for i in entries.size():
			_label(("> " if i == _index else "  ") + entries[i], Vector2(0, y), Color("f0d9a0") if i == _index else Color("d6d9de"))
			y += 12
		return
	if entries.is_empty():
		_label("  (nichts)", Vector2(0, y), Color("525a6b"))
		return
	_scroll = clampi(_scroll, maxi(0, _index - VISIBLE_ROWS + 1), _index)
	for i in range(_scroll, mini(entries.size(), _scroll + VISIBLE_ROWS)):
		var r: Dictionary = entries[i]
		var col := Color("f0d9a0") if i == _index else Color("d6d9de")
		var icon := TextureRect.new()
		icon.texture = CosyArt.item_icon(r.id)
		icon.position = Vector2(12, y)
		_box.add_child(icon)
		_label("> " if i == _index else "  ", Vector2(0, y + 3), col)
		_label(r.name, Vector2(32, y + 3), col)
		_label("%d S" % r.price, Vector2(186, y + 3), col)
		_label("×%d" % r.count, Vector2(238, y + 3), col)
		y += ROW_H


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	var n := _entries().size()
	if event.is_action_pressed("ui_down") and n > 0:
		_index = posmod(_index + 1, n)
	elif event.is_action_pressed("ui_up") and n > 0:
		_index = posmod(_index - 1, n)
	elif event.is_action_pressed("ui_accept"):
		_accept()
	elif event.is_action_pressed("ui_cancel"):
		if _level == "kopf":
			close()
			get_viewport().set_input_as_handled()
			return
		_level = "kopf"
		_index = 0
	else:
		return
	get_viewport().set_input_as_handled()
	if not is_queued_for_deletion():
		_redraw()


func _accept() -> void:
	if _level == "kopf":
		match heads()[_index]:
			"Kaufen":
				_level = "kaufen"
			"Verkaufen":
				_level = "verkaufen"
			"Backen lassen":
				_message = Shop.bake()
				return
			"Zurück":
				close()
				return
		_index = 0
		_scroll = 0
		return
	var entries := _entries()
	if entries.is_empty():
		return
	var id: String = entries[_index].id
	_message = Shop.buy(shop_id, id) if _level == "kaufen" else Shop.sell(shop_id, id)
	_index = clampi(_index, 0, maxi(0, _entries().size() - 1))
	if _level == "kaufen" and DB.equip.has(id) and _message.begins_with("Gekauft"):
		_offer_equip(id)


## Gekaufte Ausrüstung gleich anlegen lassen (gleiche Abfrage wie bei gefundener Ausrüstung).
func _offer_equip(id: String) -> void:
	_busy = true
	_redraw()
	await Pickup._offer_equip(get_tree().root, id)
	_busy = false
	if not is_queued_for_deletion():
		_redraw()
