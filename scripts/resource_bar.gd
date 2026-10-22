extends PanelContainer

#var gold_icon := ColorRect #yellow=gold
#var wood_icon := ColorRect #brown=wood
#var ore_icon := ColorRect #grey=ore
#var army_icon := ColorRect #black=army

@onready var gold_label: Label = $Row/GoldLabel
@onready var wood_label: Label = $Row/WoodLabel
@onready var ore_label: Label = $Row/OreLabel

@onready var army_label: Label = $Row/ArmyLabel

# Вызывается Godot при добавлении узла в сцену. Получает ссылки на узлы и подключает сигналы; подготовленные данные используются обработчиками и интерфейсом.
func _ready() -> void:
	GameState.resources_changed.connect(_update)
	#gold_icon.color = Color(1.0, 0.82, 0.0)
	#wood_icon.color = Color(0.5,0.3,0.1)
	#ore_icon.color = Color(0.6,0.6,0.7)
	_update()

# Читает текущие ресурсы из GameState и обновляет подписи панели ресурсов.
func _update() -> void:
	gold_label.text = "%d / %d" % [
		GameState.gold,
		GameState.resource_capacity("gold")
	]
	wood_label.text = "%d / %d" % [
		GameState.wood,
		GameState.resource_capacity("wood")
	]
	ore_label.text = "%d / %d" % [
		GameState.ore,
		GameState.resource_capacity("ore")
	]
	army_label.text = "%d" % GameState.army
