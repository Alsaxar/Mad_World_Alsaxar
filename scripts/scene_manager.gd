extends CanvasLayer

var _fade: ColorRect
var _busy := false

# Вызывается Godot при добавлении узла в сцену. Получает ссылки на узлы и подключает сигналы; подготовленные данные используются обработчиками и интерфейсом.
func _ready() -> void:
	layer = 100  # поверх всего
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)

# Получает путь сцены и передаёт его механизму смены сцен Godot.
func change_scene(path: String) -> void:
	if _busy:
		return  # защита от двойного нажатия
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP  # блокирует касания во время перехода

	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, 0.25)
	await tween.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame  # ждём, пока новая сцена загрузится
	SaveManager.save_game(path)     # автосохранение при входе в сцену

	tween = create_tween()
	tween.tween_property(_fade, "modulate:a", 0.0, 0.25)
	await tween.finished

	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
