class_name Hud
extends CanvasLayer
## Anzeige oben links: LP beider Geschwister, Silber, Plaketten.

var _label: Label
var _t := 0.0


func _ready() -> void:
	layer = 5
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.06, 0.7)
	bg.position = Vector2(2, 2)
	bg.size = Vector2(250, 12)
	add_child(bg)
	_label = Label.new()
	_label.position = Vector2(6, 1)
	BattleScene._style_label(_label, Color("d6d9de"))
	add_child(_label)
	refresh()


func refresh() -> void:
	var parts := []
	for h in GameState.party():
		var d: Dictionary = DB.hero(h)
		parts.append("%s %d/%d" % [d.name, int(GameState.hp.get(h, d.hp)), d.hp])
	parts.append(GameState.money_text(GameState.gold))
	parts.append("Plaketten %d gesetzt / %d übrig" % [GameState.plaketten.placed.size(), GameState.plaketten.spare])
	_label.text = "  ·  ".join(parts)


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.25:
		_t = 0.0
		refresh()
