class_name Npc
extends Area2D
## Figur in der Welt: Kartograf (verkauft Gebietskarten) oder Gesprächspartner (Dialog).
## Mit props.arbeit=<job> ein Dorfbewohner, der vor seinem Haus arbeitet.

var npc_id := ""
var props: Dictionary = {}
var _inside := false
var _hint: Label
var _blocked_until := 0.0
var _hint_y := -52.0

const COOLDOWN := 0.35


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(28, 28)
	s.shape = r
	s.position = Vector2(0, -14)
	add_child(s)
	var sheet: String = CosyArt.NPC_SHEETS.get(props.get("art", npc_id), "")
	if props.has("arbeit"):
		var work := CosyArt.work_sprite(props.arbeit)
		# Versetzt starten, damit nicht alle im Gleichtakt arbeiten
		work.frame = absi(npc_id.hash()) % 8
		add_child(work)
		_hint_y = -64.0
	elif sheet != "":
		var sp := CosyArt.character_sprite(sheet)
		sp.flip_h = true
		add_child(sp)
	_hint = Label.new()
	_hint.text = "[W]"
	_hint.position = Vector2(-8, _hint_y)
	_hint.visible = false
	BattleScene._style_label(_hint, Color("d9a441"))
	add_child(_hint)
	body_entered.connect(func(b): if b is Player: _inside = true; _hint.visible = true)
	body_exited.connect(func(b): if b is Player: _inside = false; _hint.visible = false)


func _process(_d: float) -> void:
	if _inside and can_interact() and Input.is_action_just_pressed("interagieren"):
		interact()


## Nach dem Schließen eines Dialogs kurz gesperrt, damit derselbe Tastendruck ihn nicht neu öffnet.
func can_interact() -> bool:
	return not get_tree().paused and Time.get_ticks_msec() / 1000.0 >= _blocked_until


func _block() -> void:
	_blocked_until = Time.get_ticks_msec() / 1000.0 + COOLDOWN


func interact() -> void:
	if npc_id == "kartograf":
		var area: String = props.get("area", "")
		var price := int(props.get("price", "40"))
		if GameState.owned_maps.has(area):
			ChoiceMenu.toast(self, "„Ihr habt die Karte schon. Ich verkaufe nichts zweimal.“")
			return
		var m := ChoiceMenu.open(self, "Karte von %s – %d Silber kaufen?" % [MapView.AREA_NAMES.get(area, area), price], ["Kaufen", "Nein"])
		m.chosen.connect(func(i):
			_block()
			if i == 0:
				if GameState.buy_map(area, price):
					ChoiceMenu.toast(self, "Karte gekauft. [M] öffnet sie.")
				else:
					ChoiceMenu.toast(self, "„Kein Silber, keine Karte.“"))
	elif props.has("dialog"):
		var box := DialogBox.show_dialog(self, props.dialog)
		box.finished.connect(_block)
