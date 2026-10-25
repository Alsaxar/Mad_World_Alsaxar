class_name ArmySlot
extends PanelContainer

@onready var name_label: Label = $VBoxContainer/ArmyName
@onready var stats_label: Label = $VBoxContainer/ArmyStats
@onready var tags_label: Label = $VBoxContainer/ArmyTags
@onready var slider: HSlider = $VBoxContainer/ArmySlider
@onready var info_label: Label = $VBoxContainer/ArmyInfo
@onready var timer_label: Label = $VBoxContainer/ArmyTimer
@onready var pick_button: Button = $VBoxContainer/ArmyPickButton

var unit_id := ""

func setup(id: String) -> void:
	unit_id = id

func _ready() -> void:
	name_label.text = str(ArmyDB.UNITS[unit_id]["name"])
	stats_label.text = ArmyDB.stats_text(unit_id)
	tags_label.text = "Особенности: %s" % ArmyDB.tags_text(unit_id)
	slider.step = 1
	slider.value_changed.connect(_on_slider_changed)
	pick_button.pressed.connect(_on_pick_pressed)
	GameState.units_changed.connect(_refresh)
	GameState.resources_changed.connect(_refresh)
	GameState.second_tick.connect(_refresh)
	_refresh()

func _owned() -> int:
	return int(GameState.units.get(unit_id, 0))

func _refresh() -> void:
	if GameState.training.has(unit_id):
		var order: Dictionary = GameState.training[unit_id]
		slider.editable = false
		pick_button.disabled = true
		pick_button.text = "Идёт найм"
		info_label.text = "В отряде: %d · Нанимается: %d" % [_owned(), int(order["count"])]
		timer_label.text = "Осталось: %s" % BuildingDB.format_time(GameState.training_time_left(unit_id))
		return

	var max_count := GameState.max_hire(unit_id)
	slider.max_value = maxi(max_count, 1)
	slider.editable = max_count > 0
	pick_button.disabled = max_count <= 0
	_update_texts(max_count)

func _update_texts(max_count: int) -> void:
	var count := int(slider.value)
	info_label.text = "В отряде: %d\nЦена за %d: %s" % [_owned(), count,
			BuildingDB.format_cost(GameState.unit_total_cost(unit_id, count))]
	timer_label.text = "Время найма: %s" % BuildingDB.format_time(ArmyDB.train_time(unit_id, count))
	pick_button.text = "Нанять %d" % count if max_count > 0 else "Не хватает ресурсов"

func _on_slider_changed(_value: float) -> void:
	if not GameState.training.has(unit_id):
		_update_texts(GameState.max_hire(unit_id))

func _on_pick_pressed() -> void:
	GameState.start_hire(unit_id, int(slider.value))
	SaveManager.save_game()
	_refresh()
