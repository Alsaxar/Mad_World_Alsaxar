extends Node2D

@export var show_zones := true:
	set(value):
		show_zones = value
		queue_redraw()
@export var level_count := MapMath.DEFAULT_LEVEL_COUNT  # держи равным значению в PoiSpawner

func _draw() -> void:
	if not show_zones:
		return
	var center := MapMath.map_center() * MapMath.CELL
	for level in range(1, level_count + 1):  # от внешнего кольца к центру
		var outer := MapMath.zone_radii(level, level_count).y * MapMath.CELL
		var t := float(level - 1) / maxf(level_count - 1, 1.0)
		draw_colored_polygon(_circle_points(center, outer), Color(0.12 + 0.7 * t, 0.45 - 0.25 * t, 0.15))
		draw_arc(center, outer, 0.0, TAU, 256, Color(0, 0, 0, 0.6), 24.0)

func _circle_points(center: Vector2, radius: float, count := 256) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in count:
		var a := TAU * i / count
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts
