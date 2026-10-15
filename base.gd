extends Control

@onready var map_button: Button = $Layout/MapButton


@onready var recruit_1_button: Button = $Layout/RecruitRow/Recruit1Button
@onready var recruit_5_button: Button = $Layout/RecruitRow/Recruit5Button

func _ready() -> void:
	GameState.new_day()
	map_button.pressed.connect(_on_map_button_pressed)
	recruit_1_button.pressed.connect(_on_recruit_pressed.bind(1))
	recruit_5_button.pressed.connect(_on_recruit_pressed.bind(5))
	GameState.resources_changed.connect(_update_recruit_buttons)
	_update_recruit_buttons()

#func _on_map_button_pressed() -> void:
	#GameState.add_resources(10)
	#get_tree().change_scene_to_file("res://scenes/world_map.tscn")

func _on_map_button_pressed() -> void:
	SceneManager.change_scene("res://scenes/world_map.tscn")

func _on_recruit_pressed(count: int) -> void:
	GameState.recruit(count)
	SaveManager.save_game()

func _update_recruit_buttons() -> void:
	recruit_1_button.text = "Нанять 1\n%d золота" % (GameState.RECRUIT_COST * 1)
	recruit_5_button.text = "Нанять 5\n%d золота" % (GameState.RECRUIT_COST * 5)
	recruit_1_button.disabled = not GameState.can_recruit(1)
	recruit_5_button.disabled = not GameState.can_recruit(5)
