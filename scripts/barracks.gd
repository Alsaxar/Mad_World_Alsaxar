extends Control

const ARMY_SLOT_SCENE := preload("res://scenes/army_slot.tscn")

@onready var card_list: VBoxContainer = $ContentArmy/ScrollArmy/CardList
@onready var back_button: Button = $ContentArmy/UI/Base_Button
@onready var title_label: Label = $ContentArmy/UI/Top/MessageLabel

func _ready() -> void:
	title_label.text = str(BuildingDB.BUILDINGS[GameState.open_building]["name"])
	back_button.pressed.connect(_on_back_pressed)
	GameState.buildings_changed.connect(_rebuild_cards)
	_rebuild_cards()

# Показываем карточки только тех войск, которые игроку уже доступны
func _rebuild_cards() -> void:
	for child in card_list.get_children():
		child.queue_free()
	for unit_id: String in ArmyDB.units_for_building(GameState.open_building):
		if GameState.is_unit_available(unit_id):
			var card: ArmySlot = ARMY_SLOT_SCENE.instantiate()
			card.setup(unit_id)
			card_list.add_child(card)

func _on_back_pressed() -> void:
	SceneManager.change_scene("res://scenes/base.tscn")
