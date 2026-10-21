extends Node

signal resources_changed
signal stamina_changed

signal buildings_changed

signal second_tick
signal building_completed(slot: String)

const MAX_STAMINA := 100.0
const BASE_RESOURCE_CAPACITY := 500
const START_CELL := Vector2i(2, 2)  # клетка замка на карте

const RECRUIT_COST := 30  # золота за одного бойца

const SUMMON_COST := {"gold": 100, "ore": 10}  # цена призыва одного бойца
const HEAL_COST := 10                          # золота за лечение одного бойца

const GOLD_PER_HOUR := 1000.0
const WOOD_PER_HOUR := 2000.0
const ORE_PER_HOUR := 1500.0

const SECONDS_PER_HOUR := 3600.0
const RESOURCE_UPDATE_INTERVAL := 1.0

const WAREHOUSE_UPGRADE_BASE_COST := {
	"gold": 100,
	"wood": 100,
	"ore": 25
}


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

# Время последнего расчёта производства.
var last_resource_update_unix: int = 0

# Дробные остатки производства, чтобы не терять доход
# при расчёте каждую секунду.
var resource_remainders := {
	"gold": 0.0,
	"wood": 0.0,
	"ore": 0.0,
}

var resource_update_timer := 0.0

func _ready() -> void:
	last_resource_update_unix = int(
		Time.get_unix_time_from_system()
	)


func _process(delta: float) -> void:
	resource_update_timer += delta

	if resource_update_timer < RESOURCE_UPDATE_INTERVAL:
		return

	resource_update_timer = 0.0
	update_resource_income()
	resource_update_timer = 0.0
	update_resource_income()
	process_timers()
	second_tick.emit()


func hourly_income() -> Dictionary:
	var total := {
		"gold": 0.0,
		"wood": 0.0,
		"ore": 0.0,
	}

	for slot in buildings:
		var building: Dictionary = buildings[slot]
		var level := int(building.get("level", 1))

		match str(building.get("type", "")):
			"gold_mine":
				total["gold"] += GOLD_PER_HOUR * level
			"sawmill":
				total["wood"] += WOOD_PER_HOUR * level
			"ore_mine":
				total["ore"] += ORE_PER_HOUR * level

	return total


func update_resource_income(now_unix: int = -1) -> void:
	if now_unix < 0:
		now_unix = int(Time.get_unix_time_from_system())

	if last_resource_update_unix <= 0:
		last_resource_update_unix = now_unix
		return

	var elapsed := maxi(
		now_unix - last_resource_update_unix,
		0
	)

	if elapsed == 0:
		return

	# Сначала фиксируем время расчёта, чтобы один и тот же
	# промежуток времени не был начислен повторно.
	last_resource_update_unix = now_unix

	var income := hourly_income()
	var gold_total: float = (
		float(resource_remainders["gold"])
		+ float(income["gold"]) * elapsed / SECONDS_PER_HOUR
	)
	var wood_total: float = (
		float(resource_remainders["wood"])
		+ float(income["wood"]) * elapsed / SECONDS_PER_HOUR
	)
	var ore_total: float = (
		float(resource_remainders["ore"])
		+ float(income["ore"]) * elapsed / SECONDS_PER_HOUR
	)

	var gold_add := floori(gold_total)
	var wood_add := floori(wood_total)
	var ore_add := floori(ore_total)

	resource_remainders["gold"] = gold_total - gold_add
	resource_remainders["wood"] = wood_total - wood_add
	resource_remainders["ore"] = ore_total - ore_add

	# Если ресурс достиг лимита, не копим производство
	# сверх вместимости.
	if gold >= resource_capacity("gold"):
		gold_add = 0
		resource_remainders["gold"] = 0.0
	if wood >= resource_capacity("wood"):
		wood_add = 0
		resource_remainders["wood"] = 0.0
	if ore >= resource_capacity("ore"):
		ore_add = 0
		resource_remainders["ore"] = 0.0

	if gold_add > 0 or wood_add > 0 or ore_add > 0:
		add_resources(gold_add, wood_add, ore_add)

func resource_capacity(resource: String) -> int:
	var capacity := BASE_RESOURCE_CAPACITY

	if has_building("warehouse"):
		var level := building_level("warehouse")
		capacity = (
			int(BuildingDB.BUILDINGS["warehouse"]["capacity_per_level"])
			* level
		)

	return capacity


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
	last_resource_update_unix = int(
		Time.get_unix_time_from_system()
	)

	resource_remainders = {
		"gold": 0.0,
		"wood": 0.0,
		"ore": 0.0,
	}

	resource_update_timer = 0.0
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
		"last_resource_update_unix": last_resource_update_unix,
		"resource_remainders": resource_remainders,
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
	var saved_buildings: Dictionary = data.get("buildings", {})
	buildings = _migrate_legacy_ids(saved_buildings, true)
	
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

	
	

	var saved_points: Dictionary = data.get("used_points", {})
	used_points = _migrate_legacy_ids(saved_points, false)

	current_scene = str(
		data.get("current_scene", "res://scenes/base.tscn")
	)
	battle_poi = str(data.get("battle_poi", ""))

	var now_unix := int(Time.get_unix_time_from_system())

	var saved_time := int(
		data.get("last_resource_update_unix", now_unix)
	)

	last_resource_update_unix = saved_time

	var saved_remainders: Dictionary = data.get(
		"resource_remainders",
		{}
	)

	resource_remainders = {
		"gold": float(saved_remainders.get("gold", 0.0)),
		"wood": float(saved_remainders.get("wood", 0.0)),
		"ore": float(saved_remainders.get("ore", 0.0)),
	}

	update_resource_income(now_unix)
	process_timers(now_unix)  # достраиваем то, что завершилось, пока игра была закрыта

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
	# true только для достроенного здания (уровень 1 и выше)
	return buildings.has(slot) and int(buildings[slot].get("level", 1)) >= 1

#func building_level(slot: String) -> int:
	#return int(buildings[slot].get("level", 1))

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
	buildings[slot] = {
		"type": type,
		"level": 0,  # 0 = ещё строится
		"target_level": 1,
		"finish_at": unix_now() + BuildingDB.build_time(type, 1),
	}
	_pay(cost)  # внутри сигнал resources_changed, здание уже записано
	buildings_changed.emit()

# Оставил в качестве примера для самого себя

#func warehouse_upgrade_cost() -> Dictionary:
	#if not has_building("warehouse"):
		#return {}
#
	#var level := building_level("warehouse")
#
	#return {
		#"gold": WAREHOUSE_UPGRADE_BASE_COST["gold"] * level,
		#"wood": WAREHOUSE_UPGRADE_BASE_COST["wood"] * level,
		#"ore": WAREHOUSE_UPGRADE_BASE_COST["ore"] * level
	#}


#func can_upgrade_warehouse() -> bool:
	#if not has_building("warehouse"):
		#return false
#
	#return can_afford(warehouse_upgrade_cost())


#func upgrade_warehouse() -> void:
	#if not can_upgrade_warehouse():
		#return
#
	#var cost := warehouse_upgrade_cost()
	#var building: Dictionary = buildings["warehouse"]
#
	#building["level"] = int(building.get("level", 1)) + 1
	#buildings["warehouse"] = building
#
	#_pay(cost)
#
	## После повышения лимита уведомляем интерфейс ресурсов.
	#resources_changed.emit()
	#buildings_changed.emit()

func daily_income() -> Dictionary:
	var total := {"gold": 0, "wood": 0, "ore": 0}
	for slot in buildings:
		var building: Dictionary = buildings[slot]
		var income := BuildingDB.income_of(building["type"], int(building.get("level", 1)))
		for res in income:
			total[res] += income[res]
	return total

#func end_day() -> void:
	## возвращение в замок: доход от зданий + новый день
	#var income := daily_income()
	#add_resources(income["gold"], income["wood"], income["ore"])
	#new_day()

func end_day() -> void:
	update_resource_income()
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

func unix_now() -> int:
	return int(Time.get_unix_time_from_system())

func is_under_construction(slot: String) -> bool:
	return buildings.has(slot) and int(buildings[slot].get("finish_at", 0)) > 0

func time_left(slot: String) -> int:
	if not is_under_construction(slot):
		return 0
	return maxi(int(buildings[slot]["finish_at"]) - unix_now(), 0)

func process_timers(now: int = -1) -> void:
	if now < 0:
		now = unix_now()
	var finished: Array = []
	for slot in buildings:
		var building: Dictionary = buildings[slot]
		var finish_at := int(building.get("finish_at", 0))
		if finish_at > 0 and now >= finish_at:
			building["level"] = int(building.get("target_level", 1))
			building["finish_at"] = 0
			finished.append(slot)
	for slot in finished:
		building_completed.emit(slot)
	if not finished.is_empty():
		buildings_changed.emit()

# ─── Улучшение зданий ───────────────────────────────────────────
# Базовая стоимость берётся из BuildingDB.BUILDINGS[id]["cost"] (или "upgrade_cost")
# Цена уровня N (N >= 2): базовая_цена * 2^(N-2)
# Уровень 1 = только что построено.

func building_level(id: String) -> int:
	if not buildings.has(id):
		return 0
	var b: Dictionary = buildings[id]
	return int(b.get("level", 1))

func upgrade_cost(slot: String) -> Dictionary:
	if not has_building(slot):
			return {}
	var type: String = buildings[slot]["type"]
	var base: Dictionary = BuildingDB.BUILDINGS[type].get("cost", {})
	var level := building_level(slot)
	var multiplier := pow(2.0, level - 1)
	var result := {}
	for key in base.keys():
		result[key] = int(round(base[key] * multiplier))
	return result


func can_upgrade(slot: String) -> bool:
	if not has_building(slot):
		return false
	return can_afford(upgrade_cost(slot))

func upgrade_building(slot: String) -> void:
	if not can_upgrade(slot):
		return
	var cost := upgrade_cost(slot)
	var building: Dictionary = buildings[slot]
	building["level"] = int(building.get("level", 1)) + 1
	buildings[slot] = building
	_pay(cost)
	resources_changed.emit()
	buildings_changed.emit()

# Вспомогательные (если их ещё нет):
func _can_afford(cost: Dictionary) -> bool:
	return gold >= int(cost.get("gold", 0)) \
		and wood >= int(cost.get("wood", 0)) \
		and ore >= int(cost.get("ore", 0))

func _spend(cost: Dictionary) -> void:
	gold -= int(cost.get("gold", 0))
	wood -= int(cost.get("wood", 0))
	ore -= int(cost.get("ore", 0))
	resources_changed.emit()
