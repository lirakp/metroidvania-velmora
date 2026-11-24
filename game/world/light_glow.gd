class_name LightGlow
extends Sprite2D
## Kalter roter Lichtschein (Dungeon-Kristalle) als Punktraster. Warme Lichter kommen als Lamp aus dem Grafik-Repo.

const SIZES := [16, 24, 32, 48]

var warm := true
var radius := 32


static func create(p_warm: bool, p_radius: int) -> LightGlow:
	var l := LightGlow.new()
	l.warm = p_warm
	var best: int = SIZES[0]
	for s in SIZES:
		if absi(s - p_radius) < absi(best - p_radius):
			best = s
	l.radius = best
	l.texture = load("res://art/light/kalt_%d.png" % best)
	return l


func _ready() -> void:
	z_index = 3
	var tw := create_tween().set_loops()
	var low := 0.7 if warm else 0.55
	tw.tween_property(self, "modulate:a", low, randf_range(0.4, 0.9))
	tw.tween_property(self, "modulate:a", 1.0, randf_range(0.4, 0.9))
