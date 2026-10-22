extends Control

const SLOT_SCENE := preload("res://scenes/ui/building_slot.tscn")

@onready var map_button: Button = $Layout/MapButton
#@onready var special_box: VBoxContainer = $Layout/Scroll/BaseWorld/Content/SpecialBuildings
#@onready var resource_grid: GridContainer = $Layout/Scroll/BaseWorld/Content/ResourceGrid
@onready var income_label: Label = $Layout/Scroll/BaseWorld/Content/IncomeLabel
@onready var building_layer: Control = $Layout/Scroll/BaseWorld/BuildingLayer
@onready var building_positions: Control = $Layout/Scroll/BaseWorld/BuildingPositions

# Вызывается Godot при добавлении узла в сцену. Получает ссылки на узлы и подключает сигналы; подготовленные данные используются обработчиками и интерфейсом.
func _ready() -> void:
	map_button.pressed.connect(_on_map_button_pressed)
	GameState.buildings_changed.connect(_update_income)
	_create_slots()
	_update_income()

		#_add_slot(special_box, id, BuildingDB.BUILDINGS[id]["name"], [id])
	#for i in BuildingDB.RESOURCE_SLOT_COUNT:
		#_add_slot(resource_grid, "res_%d" % i, "Слот %d" % (i + 1), BuildingDB.RESOURCE_TYPES)


# Создаёт слоты по данным BuildingDB и GameIds. Созданные элементы добавляются в контейнеры и показывают состояние GameState.
func _create_slots() -> void:
	for id: String in BuildingDB.SPECIAL_SLOTS:
		_add_slot(
			id,
			BuildingDB.BUILDINGS[id]["name"],
			[id]
		)

	for i in range(GameIds.RESOURCE_SLOT_COUNT):
		var slot_id := String(GameIds.resource_slot_id(i))
		var title := "Слот %d" % (i + 1)
		_add_slot(
			slot_id,
			title,
			BuildingDB.RESOURCE_TYPES
		)


# Создаёт сцену слота и передаёт ей идентификатор, заголовок и допустимые типы. Новый элемент добавляется в контейнер интерфейса.
func _add_slot(id: String, title: String, types: Array) -> void:
	var marker := building_positions.get_node_or_null(id) as Control
	
	

	if marker == null:
		push_error("Не найден маркер здания '%s' в BuildingPositions." % id)
		return
	
	var slot: BuildingSlot = SLOT_SCENE.instantiate()
	slot.setup(id, title, types)
	#parent.add_child(slot)  # _ready слота вызывается именно здесь
	# Слой не является Container, поэтому слот можно позиционировать вручную.
	building_layer.add_child(slot)
	slot.position = marker.position

	# Задаём видимый размер слота независимо от контейнеров.
	slot.custom_minimum_size = Vector2(320, 220)
	slot.size = Vector2(320, 220)

# Получает доход из GameState и форматирует его через BuildingDB. Результат выводится в подпись дохода.
func _update_income() -> void:
	income_label.text = "Доход за день: %s" % BuildingDB.format_cost(GameState.daily_income())

# Обрабатывает нажатие кнопки карты и передаёт SceneManager путь глобальной карты.
func _on_map_button_pressed() -> void:
	SceneManager.change_scene("res://scenes/world_map.tscn")
