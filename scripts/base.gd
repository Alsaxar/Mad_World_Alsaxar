extends Control

const SLOT_SCENE := preload("res://scenes/ui/building_slot.tscn")

@onready var map_button: Button = $Layout/MapButton
@onready var special_box: VBoxContainer = $Layout/Scroll/Content/SpecialBuildings
@onready var resource_grid: GridContainer = $Layout/Scroll/Content/ResourceGrid
@onready var income_label: Label = $Layout/Scroll/Content/IncomeLabel

func _ready() -> void:
	map_button.pressed.connect(_on_map_button_pressed)
	GameState.buildings_changed.connect(_update_income)
	_create_slots()
	_update_income()

#func _create_slots() -> void:
	#for id: String in BuildingDB.SPECIAL_SLOTS:
		#_add_slot(special_box, id, BuildingDB.BUILDINGS[id]["name"], [id])
	#for i in BuildingDB.RESOURCE_SLOT_COUNT:
		#_add_slot(resource_grid, "res_%d" % i, "Слот %d" % (i + 1), BuildingDB.RESOURCE_TYPES)


func _create_slots() -> void:
	for id: String in BuildingDB.SPECIAL_SLOTS:
		_add_slot(
			special_box,
			id,
			BuildingDB.BUILDINGS[id]["name"],
			[id]
		)

	for i in range(GameIds.RESOURCE_SLOT_COUNT):
		var slot_id := String(GameIds.resource_slot_id(i))
		var title := "Слот %d" % (i + 1)
		_add_slot(
			resource_grid,
			slot_id,
			title,
			BuildingDB.RESOURCE_TYPES
		)


func _add_slot(parent: Container, id: String, title: String, types: Array) -> void:
	var slot: BuildingSlot = SLOT_SCENE.instantiate()
	slot.setup(id, title, types)
	parent.add_child(slot)  # _ready слота вызывается именно здесь

func _update_income() -> void:
	income_label.text = "Доход за день: %s" % BuildingDB.format_cost(GameState.daily_income())

func _on_map_button_pressed() -> void:
	SceneManager.change_scene("res://scenes/world_map.tscn")
