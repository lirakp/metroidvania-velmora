extends Node
## Globaler Spielzustand (Autoload „GameState“). Geld zählt in Silber (100 Silber = 1 Gold).

const START_SILVER := 25

var hero_id := "warschick"
var companion_id := "lira"
var gold := START_SILVER
var xp := 0
var abilities: Dictionary = {}
var flags: Dictionary = {}
var inventory: Array = []
var equipped: Dictionary = {}
var discovered_rooms: Dictionary = {}
var owned_maps: Dictionary = {}
var room_id := ""
var hp: Dictionary = {}
var plaketten := Plaketten.new()

const GUILD_ROOM := "kornburg_gilde"
const DEATH_TAX := 0.10


func _init() -> void:
	InputSetup.ensure()


func reset() -> void:
	hero_id = "warschick"
	companion_id = "lira"
	gold = START_SILVER
	xp = 0
	abilities = {}
	flags = {}
	inventory = []
	equipped = {}
	discovered_rooms = {}
	owned_maps = {}
	room_id = ""
	hp = {}
	plaketten = Plaketten.new()


func choose_hero(id: String) -> void:
	hero_id = id
	companion_id = "lira" if id == "warschick" else "warschick"


func has_ability(n: String) -> bool:
	return abilities.get(n, false)


func set_flag(k: String, v: Variant = true) -> void:
	flags[k] = v


func get_flag(k: String) -> Variant:
	return flags.get(k, null)


func clear_dungeon(area: String) -> void:
	set_flag("dungeon_cleared:" + area)
	flags.erase("dungeon_locked:" + area)


## Legt einen Gegenstand an (ersetzt den im selben Platz).
func equip(hid: String, item: String) -> void:
	var h: Dictionary = DB.hero(hid)
	var current: Array = equipped.get(hid, [h.weapon, h.armor]).duplicate()
	var slot: String = DB.equipment(item).slot
	current = current.filter(func(e): return DB.equipment(e).slot != slot)
	current.append(item)
	equipped[hid] = current


func buy_map(area: String, price: int) -> bool:
	if gold < price:
		return false
	gold -= price
	owned_maps[area] = true
	return true


func party() -> Array:
	if get_flag("solo_mode"):
		return [hero_id]
	return [hero_id, companion_id]


func party_equipment() -> Dictionary:
	return equipped


## Silber als Text, z. B. „1 Gold 25 Silber“.
static func money_text(silver: int) -> String:
	if silver >= 100:
		return "%d Gold %d Silber" % [silver / 100, silver % 100]
	return "%d Silber" % silver


func to_dict() -> Dictionary:
	return {
		"hero_id": hero_id, "companion_id": companion_id, "gold": gold, "xp": xp,
		"abilities": abilities, "flags": flags, "inventory": inventory, "equipped": equipped,
		"discovered_rooms": discovered_rooms, "owned_maps": owned_maps, "room_id": room_id,
		"plaketten": plaketten.to_dict(),
	}


func from_dict(d: Dictionary) -> void:
	reset()
	hero_id = d.get("hero_id", hero_id)
	companion_id = d.get("companion_id", companion_id)
	gold = int(d.get("gold", gold))
	xp = int(d.get("xp", 0))
	abilities = d.get("abilities", {})
	flags = d.get("flags", {})
	inventory = d.get("inventory", [])
	equipped = d.get("equipped", {})
	discovered_rooms = d.get("discovered_rooms", {})
	owned_maps = d.get("owned_maps", {})
	room_id = d.get("room_id", "")
	plaketten = Plaketten.from_dict(d.get("plaketten", {}))


## Tod: Die Gilde bucht 10 % Blutsteuer. Gibt den Rückkehrpunkt zurück ({room, cell}; cell -1,-1 = Startpunkt des Raums).
func on_death() -> Dictionary:
	gold -= int(floor(gold * DEATH_TAX))
	hp.clear()
	var rp := plaketten.respawn_point()
	if not rp.is_empty():
		var def: RoomDef = RoomManager.def_of(rp.room)
		if def.error != "" or (def.one_way_dungeon and get_flag("dungeon_cleared:" + def.area) == true):
			rp = {}
	if rp.is_empty():
		rp = {"room": GUILD_ROOM, "cell": Vector2i(-1, -1)}
	if RoomManager.world_root != null and is_instance_valid(RoomManager.world_root):
		RoomManager.go_to.call_deferred(rp.room, "", "start", rp.cell)
	return rp
