class_name Door
extends Area2D
## Durchgang in den Hintergrund (Haustür, Öffnung in der Wand, Portal): [W]/↑ betritt den Raum dahinter.
## Portale (props art=portal) zeigen die Portal-Animation aus dem Grafik-Repo und achten auf die Einweg-Schwelle.

var door_id := ""
var target := ""  # "<raum>:<tür-id>"
var props: Dictionary = {}
var portal_sprite: AnimatedSprite2D
var _inside := false
var _hint: Label
var _sealed := false

const PORTAL_ANIMS := ["oeffnen", "offen", "durchgang", "schliessen"]


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(20, 40)
	s.shape = r
	s.position = Vector2(0, -20)
	add_child(s)
	_hint = Label.new()
	_hint.text = "[W]"
	_hint.position = Vector2(-8, -60)
	_hint.visible = false
	BattleScene._style_label(_hint, Color("d9a441"))
	add_child(_hint)
	if is_portal():
		_build_portal()
	body_entered.connect(func(b): if b is Player: _inside = true; _hint.visible = true)
	body_exited.connect(func(b): if b is Player: _inside = false; _hint.visible = false)


func _process(_d: float) -> void:
	if _inside and Input.is_action_just_pressed("interagieren"):
		try_enter()


func is_portal() -> bool:
	return props.get("art", "") == "portal"


func _build_portal() -> void:
	var m := CosyArt.meta("objects/portal/portal.json")
	var farbe: String = props.get("farbe", "rot")
	var tex: Texture2D = load(CosyArt.BASE + "objects/portal/" + m.farben[farbe])
	var w := int(m.zelle[0])
	var h := int(m.zelle[1])
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for row in m.zeilen.size():
		var anim: String = m.zeilen[row]
		sf.add_animation(anim)
		sf.set_animation_speed(anim, float(m.fps[anim]))
		sf.set_animation_loop(anim, anim == "offen")
		for f in int(m.frames[anim]):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(f * w, row * h, w, h)
			sf.add_frame(anim, at)
	portal_sprite = AnimatedSprite2D.new()
	portal_sprite.sprite_frames = sf
	portal_sprite.centered = false
	portal_sprite.position = -Vector2(m.bodenpunkt[0], m.bodenpunkt[1])
	portal_sprite.animation_finished.connect(_on_portal_anim_finished)
	add_child(portal_sprite)
	refresh_state()


## Portal offen oder versiegelt (Einweg-Schwelle, gelöster Dungeon).
func refresh_state() -> void:
	if not is_portal():
		return
	var room := RoomManager.current_def
	var to := target.split(":")
	_sealed = room != null and to.size() == 2 and RoomManager.passage_locked(room, to[0])
	_hint.text = "versiegelt" if _sealed else "[W]"
	if _sealed:
		portal_sprite.play("schliessen")
	else:
		portal_sprite.play("oeffnen")


func _on_portal_anim_finished() -> void:
	if portal_sprite.animation == "oeffnen":
		portal_sprite.play("offen")
	elif portal_sprite.animation == "schliessen":
		portal_sprite.visible = false


## Wechselt in den Zielraum, wenn nichts dagegen spricht (Pause, Kampf, gerade erst angekommen, versiegelt).
func try_enter() -> bool:
	if get_tree().paused or BattleLauncher.busy or RoomManager.doors_blocked():
		return false
	var to := target.split(":")
	if to.size() != 2:
		return false
	if is_portal():
		refresh_state()
		if _sealed:
			return false
		portal_sprite.visible = true
		portal_sprite.play("durchgang")
		var t := float(portal_sprite.sprite_frames.get_frame_count("durchgang")) / portal_sprite.sprite_frames.get_animation_speed("durchgang")
		RoomManager.block_doors(t + 0.5)
		get_tree().create_timer(t + 0.05).timeout.connect(func(): RoomManager.enter_door(to[0], to[1]))
		return true
	var bld := _building()
	if bld:
		RoomManager.block_doors(bld.door_open_time() + 0.5)
		bld.open_door()
		get_tree().create_timer(bld.door_open_time() + 0.05).timeout.connect(func(): RoomManager.enter_door(to[0], to[1]))
	else:
		RoomManager.enter_door.call_deferred(to[0], to[1])
	return true


## Gebäude, dessen Tür an dieser Stelle liegt (Ursprung = Türmitte unten).
func _building() -> Building:
	for n in get_parent().get_children():
		if n is Building and n.position.distance_to(position) < 4.0:
			return n
	return null
