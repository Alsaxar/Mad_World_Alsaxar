class_name PathPreview
extends Node2D

const COLOR_OK := Color(1.0, 0.9, 0.2)
const COLOR_FAR := Color(1.0, 0.3, 0.3, 0.8)

var _reachable := PackedVector2Array()
var _unreachable := PackedVector2Array()
var _end := Vector2.ZERO
var _end_color := COLOR_OK
var _active := false

func show_path(path: PackedVector2Array, steps: int) -> void:
	# steps: на сколько шагов хватает выносливости
	_reachable = path.slice(0, steps + 1)
	_unreachable = path.slice(steps) if steps < path.size() - 1 else PackedVector2Array()
	_end = path[path.size() - 1]
	_end_color = COLOR_OK if _unreachable.is_empty() else COLOR_FAR
	_active = true
	queue_redraw()

func clear() -> void:
	_active = false
	queue_redraw()

func _draw() -> void:
	if not _active:
		return
	if _reachable.size() >= 2:
		draw_polyline(_reachable, COLOR_OK, 8.0)
	if _unreachable.size() >= 2:
		draw_polyline(_unreachable, COLOR_FAR, 8.0)
	draw_circle(_end, 16.0, _end_color)
