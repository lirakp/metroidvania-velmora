class_name QuestBoard
extends Area2D
## Auftragsbrett in der Gildenhalle (Grafik welt/dorf/gildenbrett.png). [W] öffnet die Aufträge.

const COOLDOWN := 0.35

var _inside := false
var _hint: Label
var _blocked_until := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(32, 32)
	s.shape = r
	s.position = Vector2(0, -16)
	add_child(s)
	var info: Dictionary = CosyArt.meta("welt/welt.json").dorf.gildenbrett
	var tex: Texture2D = load(CosyArt.BASE + "welt/dorf/gildenbrett.png")
	var w := int(info.bild[0])
	var h := int(info.bild[1])
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", 6.0)
	for i in int(info.bilder):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * w, 0, w, h)
		sf.add_frame("default", at)
	var sp := AnimatedSprite2D.new()
	sp.sprite_frames = sf
	sp.centered = false
	sp.scale = Vector2(2, 2)
	sp.position = Vector2(-w, -2 * h)
	sp.play("default")
	add_child(sp)
	_hint = Label.new()
	_hint.text = "[W]"
	_hint.position = Vector2(-8, -2 * h - 12)
	_hint.visible = false
	BattleScene._style_label(_hint, Color("d9a441"))
	add_child(_hint)
	body_entered.connect(func(b): if b is Player: _inside = true; _hint.visible = true)
	body_exited.connect(func(b): if b is Player: _inside = false; _hint.visible = false)


func _process(_d: float) -> void:
	if _inside and not get_tree().paused and Time.get_ticks_msec() / 1000.0 >= _blocked_until \
			and Input.is_action_just_pressed("interagieren"):
		_blocked_until = Time.get_ticks_msec() / 1000.0 + COOLDOWN
		await QuestMenu.open(self)
		_blocked_until = Time.get_ticks_msec() / 1000.0 + COOLDOWN
