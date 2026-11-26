class_name CosyArt
extends RefCounted
## Liest die übernommenen Grafiken aus res://art/cosy (unverändert aus lirakp/aniamtion) samt Metadaten.

const BASE := "res://art/cosy/"
const MONSTER_ANIMS := ["idle", "move", "attack", "hurt", "death"]
const MONSTER_FPS := {"idle": 5.0, "move": 8.0, "attack": 10.0, "hurt": 10.0, "death": 8.0}
const HERO_LOOPS := ["stehen", "rennen", "fallen", "dash", "wand_rutschen", "heilen", "scheitel", "sprung_auf"]

static var _json_cache := {}
static var _frames_cache := {}


static func meta(rel: String) -> Dictionary:
	if not _json_cache.has(rel):
		_json_cache[rel] = JSON.parse_string(FileAccess.get_file_as_string(BASE + rel))
	return _json_cache[rel]


static func monster_info(enemy_id: String) -> Dictionary:
	return meta("monster/sprites/monster.json")[DB.enemy(enemy_id).cosy]


static func monster_frames(enemy_id: String) -> SpriteFrames:
	var key := "m:" + enemy_id
	if _frames_cache.has(key):
		return _frames_cache[key]
	var info := monster_info(enemy_id)
	var tex: Texture2D = load(BASE + "monster/sprites/" + info.datei)
	var w := int(info.bild[0])
	var h := int(info.bild[1])
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for row in MONSTER_ANIMS.size():
		var anim: String = MONSTER_ANIMS[row]
		sf.add_animation(anim)
		sf.set_animation_speed(anim, MONSTER_FPS[anim])
		sf.set_animation_loop(anim, anim in ["idle", "move"])
		for f in int(info.animationen[anim]):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(f * w, row * h, w, h)
			sf.add_frame(anim, at)
	_frames_cache[key] = sf
	return sf


## Versatz für ein zentriertes Sprite, damit der Bodenpunkt am Knoten-Ursprung liegt.
static func monster_offset(enemy_id: String) -> Vector2:
	var info := monster_info(enemy_id)
	return Vector2(info.bild[0] / 2.0 - info.bodenpunkt[0], info.bild[1] / 2.0 - info.bodenpunkt[1])


static func monster_size(enemy_id: String) -> Vector2:
	var info := monster_info(enemy_id)
	return Vector2(info.bild[0], info.bild[1])


static func hero_frames(sheet: String) -> SpriteFrames:
	var key := "h:" + sheet
	if _frames_cache.has(key):
		return _frames_cache[key]
	var m := meta("characters/held/held.json")
	var tex: Texture2D = load(BASE + "characters/held/%s.png" % sheet)
	var c := int(m.zelle)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for row in m.zeilen.size():
		var anim: String = m.zeilen[row]
		sf.add_animation(anim)
		sf.set_animation_speed(anim, float(m.fps[anim]))
		sf.set_animation_loop(anim, anim in HERO_LOOPS)
		for f in int(m.frames[anim]):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(f * c, row * c, c, c)
			sf.add_frame(anim, at)
	_frames_cache[key] = sf
	return sf


## Versatz für zentriertes Figuren-Sprite (48er Zelle, Boden bei y=46).
static func hero_offset() -> Vector2:
	var m := meta("characters/held/held.json")
	return Vector2(m.zelle / 2.0 - m.mitte_x, m.zelle / 2.0 - m.boden_y)


## Figuren-Sprite aus einem 48er-Sheet; Füße am Knoten-Ursprung. Blick nach rechts.
static func character_sprite(sheet: String) -> AnimatedSprite2D:
	var sp := AnimatedSprite2D.new()
	sp.sprite_frames = hero_frames(sheet)
	sp.offset = hero_offset()
	sp.play("stehen")
	return sp


## Gegner-Sprite; Bodenpunkt am Knoten-Ursprung. Blick nach rechts.
static func monster_sprite(enemy_id: String) -> AnimatedSprite2D:
	var sp := AnimatedSprite2D.new()
	sp.sprite_frames = monster_frames(enemy_id)
	sp.offset = monster_offset(enemy_id)
	sp.play("idle")
	return sp


const NPC_SHEETS := {"kartograf": "mensch_tunika", "gildenmeisterin": "zwerg_tunika"}


## Arbeitsschleife eines Dorfbewohners (characters/arbeit, 8 Bilder in einer Reihe).
static func work_frames(job: String) -> SpriteFrames:
	var key := "w:" + job
	if _frames_cache.has(key):
		return _frames_cache[key]
	var m := meta("characters/arbeit/arbeit.json")
	var tex: Texture2D = load(BASE + "characters/arbeit/%s.png" % job)
	var w := int(m.zelle[0])
	var h := int(m.zelle[1])
	var sf := SpriteFrames.new()
	sf.rename_animation("default", "arbeit")
	sf.set_animation_speed("arbeit", float(m.fps))
	sf.set_animation_loop("arbeit", true)
	for f in int(m.frames):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(f * w, 0, w, h)
		sf.add_frame("arbeit", at)
	_frames_cache[key] = sf
	return sf


## Dorfbewohner bei der Arbeit: doppelt groß wie die Gebäude (sonst halb so groß wie der Held),
## Füße am Ursprung, Figur etwa mittig darüber.
const WORK_SCALE := 2.0


static func work_sprite(job: String) -> AnimatedSprite2D:
	var m := meta("characters/arbeit/arbeit.json")
	var sp := AnimatedSprite2D.new()
	sp.sprite_frames = work_frames(job)
	sp.centered = false
	sp.scale = Vector2(WORK_SCALE, WORK_SCALE)
	sp.position = Vector2(-float(m.figur_offset[0]) - 6.0, -float(m.zelle[1])) * WORK_SCALE
	sp.play("arbeit")
	return sp


## 16×16-Icon eines Gegenstands (Vorrat oder Ausrüstung). Quelle steht im Feld „icon“:
## "sammeln:<name>" (welt/sammeln/icons_sammeln.png) oder "icons:<gruppe>:<name>" (icons/<gruppe>.png).
static func item_icon(id: String) -> AtlasTexture:
	var key := "i:" + id
	if _frames_cache.has(key):
		return _frames_cache[key]
	var src := ""
	if DB.items.has(id):
		src = DB.item(id).get("icon", "")
	elif DB.equip.has(id):
		src = DB.equip[id].get("icon", "")
	var parts := src.split(":")
	var at := AtlasTexture.new()
	var index := -1
	if parts.size() == 2 and parts[0] == "sammeln":
		at.atlas = load(BASE + "welt/sammeln/icons_sammeln.png")
		index = int(meta("welt/sammeln/sammeln.json").items[parts[1]].icon_index)
	elif parts.size() == 3 and parts[0] == "icons":
		at.atlas = load(BASE + "icons/%s.png" % parts[1])
		index = (meta("icons/icons.json").gruppen[parts[1]] as Array).find(parts[2])
	if index < 0:
		push_warning("Icon fehlt: " + id)
		return null
	var size := int(meta("icons/icons.json").groesse)
	at.region = Rect2(index * size, 0, size, size)
	_frames_cache[key] = at
	return at
