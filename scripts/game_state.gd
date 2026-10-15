extends Node

signal resources_changed
signal stamina_changed

const MAX_STAMINA := 100.0
const START_CELL := Vector2i(2, 2)  # клетка замка на карте

const RECRUIT_COST := 30  # золота за одного бойца

var gold := 100
var wood := 50
var ore := 20
var stamina := MAX_STAMINA
var army := 10

var hero_cell := START_CELL
var used_points := {}  # точки, уже использованные сегодня
var battle_poi := ""   # какая точка запустила бой

var current_scene := "res://scenes/base.tscn"  # где игрок остановился

func add_resources(g := 0, w := 0, o := 0) -> void:
	gold += g
	wood += w
	ore += o
	resources_changed.emit()

func spend_stamina(amount: float) -> void:
	stamina = max(stamina - amount, 0.0)
	stamina_changed.emit()

func restore_stamina() -> void:
	stamina = MAX_STAMINA
	stamina_changed.emit()

func add_stamina(amount: float) -> void:
	stamina = min(stamina + amount, MAX_STAMINA)
	stamina_changed.emit()

func reset() -> void:
	gold = 100
	wood = 50
	ore = 20
	army = 10
	new_day()
	resources_changed.emit()

func new_day() -> void:
	restore_stamina()
	used_points.clear()
	hero_cell = START_CELL

func can_recruit(count: int) -> bool:
	return gold >= RECRUIT_COST * count

func recruit(count: int) -> void:
	if not can_recruit(count):
		return
	gold -= RECRUIT_COST * count
	army += count
	resources_changed.emit()

func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"wood": wood,
		"ore": ore,
		"stamina": stamina,
		"army": army,
		"hero_cell": [hero_cell.x, hero_cell.y],
		"used_points": used_points,
		"current_scene": current_scene,
	}

func load_from_dict(data: Dictionary) -> void:
	gold = int(data.get("gold", 100))
	wood = int(data.get("wood", 50))
	ore = int(data.get("ore", 20))
	stamina = float(data.get("stamina", MAX_STAMINA))
	army = int(data.get("army", 10))
	var cell: Array = data.get("hero_cell", [START_CELL.x, START_CELL.y])
	hero_cell = Vector2i(int(cell[0]), int(cell[1]))
	used_points = data.get("used_points", {})
	current_scene = str(data.get("current_scene", "res://scenes/base.tscn"))
	resources_changed.emit()
	stamina_changed.emit()
