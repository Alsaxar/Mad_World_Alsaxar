extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1

const BASE_SCENE := "res://scenes/base.tscn"
const MAP_SCENE := "res://scenes/world_map.tscn"
const BATTLE_SCENE := "res://scenes/battle.tscn"

# Проверяет наличие файла сохранения. Ответ используется меню для доступности продолжения игры.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# Получает состояние GameState и путь текущей сцены, затем записывает их в файл. Файл используется при следующей загрузке.
func save_game(scene_path := "") -> void:
	if scene_path.is_empty():
		var current := get_tree().current_scene
		if current == null:
			return
		scene_path = current.scene_file_path

	# запоминаем только «безопасные» сцены; бой при загрузке заменяется картой
	if scene_path == BASE_SCENE or scene_path == MAP_SCENE:
		GameState.current_scene = scene_path
	elif scene_path != BATTLE_SCENE:
		return  # в главном меню сохранять нечего

	var data := GameState.to_dict()
	data["version"] = SAVE_VERSION
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Не удалось сохранить: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

# Читает файл сохранения и восстанавливает GameState и путь сцены. Возвращает результат загрузки меню и системе переходов.
func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Файл сохранения повреждён")
		return false
	GameState.load_from_dict(data)
	# защита от подставленного пути: возвращаться можно только на базу или карту
	if GameState.current_scene != BASE_SCENE and GameState.current_scene != MAP_SCENE:
		GameState.current_scene = BASE_SCENE
	return true

# Обрабатывает системное уведомление Godot и при необходимости сохраняет игру.
func _notification(what: int) -> void:
	# закрытие окна, кнопка «Назад» на Android, сворачивание приложения на телефоне
	if what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_WM_GO_BACK_REQUEST \
			or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()
