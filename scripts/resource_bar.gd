extends PanelContainer

@onready var gold_label: Label = $Row/GoldLabel
@onready var wood_label: Label = $Row/WoodLabel
@onready var ore_label: Label = $Row/OreLabel

@onready var army_label: Label = $Row/ArmyLabel

func _ready() -> void:
	GameState.resources_changed.connect(_update)
	_update()

func _update() -> void:
	gold_label.text = "Золото: %d / %d" % [
		GameState.gold,
		GameState.resource_capacity("gold")
	]
	wood_label.text = "Дерево: %d / %d" % [
		GameState.wood,
		GameState.resource_capacity("wood")
	]
	ore_label.text = "Руда: %d / %d" % [
		GameState.ore,
		GameState.resource_capacity("ore")
	]
	army_label.text = "Отряд: %d" % GameState.army
