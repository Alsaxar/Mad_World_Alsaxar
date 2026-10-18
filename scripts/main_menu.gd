extends Control

@onready var continue_button: Button = $Center/Menu/ContinueButton
@onready var new_game_button: Button = $Center/Menu/NewGameButton
@onready var quit_button: Button = $Center/Menu/QuitButton

func _ready() -> void:
	continue_button.disabled = not SaveManager.has_save()
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(get_tree().quit)
	quit_button.visible = not OS.has_feature("mobile")

func _on_continue_pressed() -> void:
	if SaveManager.load_game():
		SceneManager.change_scene(GameState.current_scene)
	else:
		continue_button.disabled = true

func _on_new_game_pressed() -> void:
	GameState.reset()
	SceneManager.change_scene("res://scenes/base.tscn")
