extends Control

@onready var continue_button: Button = $Center/Menu/ContinueButton
@onready var new_game_button: Button = $Center/Menu/NewGameButton
@onready var quit_button: Button = $Center/Menu/QuitButton

# Вызывается Godot при добавлении узла в сцену. Получает ссылки на узлы и подключает сигналы; подготовленные данные используются обработчиками и интерфейсом.
func _ready() -> void:
	continue_button.disabled = not SaveManager.has_save()
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(get_tree().quit)
	quit_button.visible = not OS.has_feature("mobile")

# Загружает сохранение через SaveManager и открывает сохранённую сцену.
func _on_continue_pressed() -> void:
	if SaveManager.load_game():
		SceneManager.change_scene(GameState.current_scene)
	else:
		continue_button.disabled = true

# Сбрасывает GameState и открывает стартовую сцену новой игры.
func _on_new_game_pressed() -> void:
	GameState.reset()
	SceneManager.change_scene("res://scenes/base.tscn")
