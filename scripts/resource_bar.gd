extends PanelContainer

@onready var gold_label: Label = $Row/GoldLabel
@onready var wood_label: Label = $Row/WoodLabel
@onready var ore_label: Label = $Row/OreLabel

@onready var army_label: Label = $Row/ArmyLabel

func _ready() -> void:
	GameState.resources_changed.connect(_update)
	_update()

func _update() -> void:
	gold_label.text = "Золото: %d" % GameState.gold
	wood_label.text = "Дерево: %d" % GameState.wood
	ore_label.text = "Руда: %d" % GameState.ore
	army_label.text = "Отряд: %d" % GameState.army
