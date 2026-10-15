class_name Hero
extends Node2D

signal step_finished
signal path_finished

const SPEED := 300.0

var _path := PackedVector2Array()
var _index := 0

func follow_path(path: PackedVector2Array) -> void:
	_path = path
	_index = 0

func _process(delta: float) -> void:
	if _index >= _path.size():
		return
	var target := _path[_index]
	position = position.move_toward(target, SPEED * delta)
	if position.is_equal_approx(target):
		if _index > 0:
			step_finished.emit()  # дошёл до очередной клетки
		_index += 1
		if _index >= _path.size():
			path_finished.emit()  # маршрут закончен

func is_moving() -> bool:
	return _index < _path.size()

func stop() -> void:
	_path = PackedVector2Array()
	_index = 0
