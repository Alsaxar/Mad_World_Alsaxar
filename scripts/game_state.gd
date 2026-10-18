extends Node

signal resources_changed
signal stamina_changed

signal buildings_changed

const MAX_STAMINA := 100.0
const BASE_RESOURCE_CAPACITY := 500
const START_CELL := Vector2i(2, 2)  # клетка замка на карте

const RECRUIT_COST := 30  # золота за одного бойца

const SUMMON_COST := {"gold": 100, "ore": 10}  # цена призыва одного бойца
const HEAL_COST := 10                          # золота за лечение одного бойца

var gold := 100
var wood := 50
var ore := 20
var stamina := MAX_STAMINA
var army := 10

var elite := 0       # особые войска из портала
var wounded := 0     # раненые в лазарете
var buildings := {}  # слот -> {"type": ..., "level": ...}

var hero_cell := START_CELL
var used_points := {}  # точки, уже использованные сегодня
var battle_poi := ""   # какая точка запустила бой

var current_scene := "res://scenes/base.tscn"  # где игрок остановился

func resource_capacity(resource: String) -> int:
	return BASE_RESOURCE_CAPACITY


func add_resources(g := 0, w := 0, o := 0) -> void:
	gold = clampi(gold + g, 0, resource_capacity("gold"))
	wood = clampi(wood + w, 0, resource_capacity("wood"))
	ore = clampi(ore + o, 0, resource_capacity("ore"))
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
	elite = 0
	wounded = 0
	buildings.clear()
	new_day()
	resources_changed.emit()

func new_day() -> void:
	restore_stamina()
	used_points.clear()
	hero_cell = START_CELL

#func can_recruit(count: int) -> bool:
	#return gold >= RECRUIT_COST * count

func can_recruit(count: int) -> bool:
	return has_building("barracks") and gold >= RECRUIT_COST * count

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
		"elite": elite,
		"wounded": wounded,
		"buildings": buildings,
		"hero_cell": [hero_cell.x, hero_cell.y],
		"used_points": used_points,
		"current_scene": current_scene,
	}

#func load_from_dict(data: Dictionary) -> void:
	#gold = int(data.get("gold", 100))
	#wood = int(data.get("wood", 50))
	#ore = int(data.get("ore", 20))
	#stamina = float(data.get("stamina", MAX_STAMINA))
	#army = int(data.get("army", 10))
	#var cell: Array = data.get("hero_cell", [START_CELL.x, START_CELL.y])
	#hero_cell = Vector2i(int(cell[0]), int(cell[1]))
	#used_points = data.get("used_points", {})
	#current_scene = str(data.get("current_scene", "res://scenes/base.tscn"))
	#resources_changed.emit()
	#stamina_changed.emit()
	#buildings_changed.emit()

func load_from_dict(data: Dictionary) -> void:
	gold = clampi(int(data.get("gold", 100)), 0, resource_capacity("gold"))
	wood = clampi(int(data.get("wood", 50)), 0, resource_capacity("wood"))
	ore = clampi(int(data.get("ore", 20)), 0, resource_capacity("ore"))
	stamina = clampf(
		float(data.get("stamina", MAX_STAMINA)),
		0.0,
		MAX_STAMINA
	)
	army = int(data.get("army", 10))
	elite = int(data.get("elite", 0))
	wounded = int(data.get("wounded", 0))

	var cell: Array = data.get(
		"hero_cell",
		[START_CELL.x, START_CELL.y]
	)
	if cell.size() >= 2:
		hero_cell = Vector2i(int(cell[0]), int(cell[1]))
	else:
		hero_cell = START_CELL

	var saved_buildings: Dictionary = data.get("buildings", {})
	buildings = _migrate_legacy_ids(saved_buildings, true)

	var saved_points: Dictionary = data.get("used_points", {})
	used_points = _migrate_legacy_ids(saved_points, false)

	current_scene = str(
		data.get("current_scene", "res://scenes/base.tscn")
	)
	battle_poi = str(data.get("battle_poi", ""))

	resources_changed.emit()
	stamina_changed.emit()
	buildings_changed.emit()


func _migrate_legacy_ids(
	source: Dictionary,
	is_buildings: bool
) -> Dictionary:
	var migrated: Dictionary = {}

	# Сначала переносим старые ключи в новый формат.
	for key in source:
		var old_id := str(key)
		var new_id := old_id

		if is_buildings and old_id.begins_with("res_"):
			var index_text := old_id.trim_prefix("res_")
			if index_text.is_valid_int():
				var index := int(index_text)
				if index >= 0 and index < GameIds.RESOURCE_SLOT_COUNT:
					new_id = str(GameIds.resource_slot_id(index))

		elif not is_buildings:
			match old_id:
				"Mine":
					new_id = "poi_gold_mine_001"
				"BanditCamp":
					new_id = "poi_bandit_camp_001"
				"LightAltar":
					new_id = "poi_altar_001"

		migrated[new_id] = source[key]

	# Если в сохранении уже есть новый ключ, он имеет приоритет.
	for key in source:
		var old_id := str(key)
		if is_buildings and old_id.begins_with("res_"):
			continue
		if not is_buildings and old_id in [
			"Mine", "BanditCamp", "LightAltar"
		]:
			continue
		migrated[old_id] = source[key]

	return migrated

func has_building(slot: String) -> bool:
	return buildings.has(slot)

func building_level(slot: String) -> int:
	return int(buildings[slot].get("level", 1))

func can_afford(cost: Dictionary) -> bool:
	return gold >= int(cost.get("gold", 0)) \
			and wood >= int(cost.get("wood", 0)) \
			and ore >= int(cost.get("ore", 0))

func _pay(cost: Dictionary) -> void:
	add_resources(-int(cost.get("gold", 0)), -int(cost.get("wood", 0)), -int(cost.get("ore", 0)))

func build(slot: String, type: String) -> void:
	if buildings.has(slot):
		return
	var cost: Dictionary = BuildingDB.BUILDINGS[type]["cost"]
	if not can_afford(cost):
		return
	buildings[slot] = {"type": type, "level": 1}
	_pay(cost)  # внутри сигнал resources_changed, здание уже записано
	buildings_changed.emit()

func daily_income() -> Dictionary:
	var total := {"gold": 0, "wood": 0, "ore": 0}
	for slot in buildings:
		var building: Dictionary = buildings[slot]
		var income := BuildingDB.income_of(building["type"], int(building.get("level", 1)))
		for res in income:
			total[res] += income[res]
	return total

func end_day() -> void:
	# возвращение в замок: доход от зданий + новый день
	var income := daily_income()
	add_resources(income["gold"], income["wood"], income["ore"])
	new_day()

func summon_elite() -> void:
	if not has_building("portal") or not can_afford(SUMMON_COST):
		return
	elite += 1
	_pay(SUMMON_COST)  # сигнал обновит интерфейс уже с новым числом

func can_heal() -> bool:
	return has_building("infirmary") and wounded > 0 and gold >= HEAL_COST

func heal_wounded() -> void:
	var count := mini(wounded, floori(gold / float(HEAL_COST)))
	if not has_building("infirmary") or count <= 0:
		return
	wounded -= count
	army += count
	gold -= count * HEAL_COST
	resources_changed.emit()

func register_casualties(count: int) -> int:
	# половина погибших (с округлением вверх) попадает в лазарет, если он построен
	if count <= 0 or not has_building("infirmary"):
		return 0
	var hurt := ceili(count / 2.0)
	wounded += hurt
	return hurt
