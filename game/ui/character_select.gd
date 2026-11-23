class_name CharacterSelect
extends Node2D
## Figurenwahl: Warschick oder Lira. Die andere Figur begleitet euch.

signal chosen(hero_id: String)

const HEROES := ["warschick", "lira"]

var _index := 0
var _sprites: Array[AnimatedSprite2D] = []
var _info: Label


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("0b0c10")
	bg.size = Vector2(480, 270)
	add_child(bg)
	var t := Label.new()
	t.text = "Wen spielt ihr?"
	t.position = Vector2(180, 30)
	BattleScene._style_label(t, Color("d9a441"), 16)
	add_child(t)
	for i in HEROES.size():
		var sp := AnimatedSprite2D.new()
		sp.sprite_frames = Player.make_frames("res://art/chars/%s.png" % HEROES[i])
		sp.play("idle")
		sp.scale = Vector2(3, 3)
		sp.position = Vector2(170 + i * 140, 120)
		add_child(sp)
		_sprites.append(sp)
		var n := Label.new()
		n.text = DB.hero(HEROES[i]).name
		n.position = Vector2(150 + i * 140, 175)
		BattleScene._style_label(n, Color("d6d9de"), 8)
		add_child(n)
	_info = Label.new()
	_info.position = Vector2(60, 200)
	_info.size = Vector2(360, 50)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	BattleScene._style_label(_info, Color("b3b9c4"), 8)
	add_child(_info)
	_draw()


func _draw() -> void:
	for i in _sprites.size():
		_sprites[i].modulate = Color(1, 1, 1) if i == _index else Color(0.4, 0.4, 0.45)
	var me: Dictionary = DB.hero(HEROES[_index])
	var other: Dictionary = DB.hero(HEROES[1 - _index])
	var style := {"glutpirscher": "Glutpirscher-Stil, Kurzschwert", "hydroforelle": "Hydroforellen-Stil, Stab"}
	_info.text = "%s – Halbelf, %s. %d LP, Mana C %d / S %d.\n%s begleitet euch.\n[←/→] wählen   [Enter] bestätigen" % [me.name, style.get(me.style, ""), me.hp, me.mana_c, me.mana_s, other.name]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		_index = 1 - _index
		_draw()
	elif event.is_action_pressed("ui_accept"):
		chosen.emit(HEROES[_index])
