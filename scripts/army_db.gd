class_name ArmyDB
extends RefCounted

const MAX_HIRE_BATCH := 50  # максимум бойцов в одном заказе
const TIME_SCALE := 1.0     # для тестов можно 0.2

const TAG_NAMES := {
	GameIds.ARMY_FLY: "Летающий",
	GameIds.ARMY_GROUND: "Наземный",
	GameIds.ARMY_HEAVY: "Тяжёлый",
	GameIds.ARMY_LIGHT: "Лёгкий",
	GameIds.ARMY_SMALL: "Малый",
	GameIds.ARMY_MEDIUM_SIZE: "Средний",
	GameIds.ARMY_MASSIVE: "Огромный",
}

# Ключи совпадают со значениями GameIds.ARMY_*. Все числа тестовые.
const UNITS := {
	"swordman": {
		"name": "Мечник",
		"building": "barracks",
		"min_level": 1,
		"tags": [GameIds.ARMY_GROUND, GameIds.ARMY_HEAVY, GameIds.ARMY_SMALL],
		"attack": 6,
		"defense": 6,
		"health": 24,
		"speed": 4,
		"stamina": 10,
		"cost": {"gold": 30},
		"train_time": 6,
	},
	"bowman": {
		"name": "Лучник",
		"building": "barracks",
		"min_level": 1,
		"tags": [GameIds.ARMY_GROUND, GameIds.ARMY_LIGHT, GameIds.ARMY_SMALL],
		"attack": 8,
		"defense": 2,
		"health": 14,
		"speed": 4,
		"stamina": 8,
		"cost": {"gold": 25, "wood": 10},
		"train_time": 6,
	},
	"cavalryman": {
		"name": "Всадник",
		"building": "barracks",
		"min_level": 2,
		"tags": [GameIds.ARMY_GROUND, GameIds.ARMY_LIGHT, GameIds.ARMY_MEDIUM_SIZE],
		"attack": 9,
		"defense": 5,
		"health": 30,
		"speed": 9,
		"stamina": 14,
		"cost": {"gold": 60, "wood": 20},
		"train_time": 10,
	},
	"griffin": {
		"name": "Грифон",
		"building": "portal",
		"min_level": 1,
		"tags": [GameIds.ARMY_FLY, GameIds.ARMY_HEAVY, GameIds.ARMY_MEDIUM_SIZE],
		"attack": 12,
		"defense": 6,
		"health": 40,
		"speed": 8,
		"stamina": 18,
		"cost": {"gold": 100, "ore": 10},
		"train_time": 20,
	},
	"ice_phoenix": {
		"name": "Ледяной феникс",
		"building": "portal",
		"min_level": 3,
		"tags": [GameIds.ARMY_FLY, GameIds.ARMY_LIGHT, GameIds.ARMY_MASSIVE],
		"attack": 16,
		"defense": 4,
		"health": 36,
		"speed": 10,
		"stamina": 16,
		"cost": {"gold": 150, "wood": 30, "ore": 20},
		"train_time": 30,
	},
	"ent": {
		"name": "Энт",
		"building": "portal",
		"min_level": 2,
		"tags": [GameIds.ARMY_GROUND, GameIds.ARMY_HEAVY, GameIds.ARMY_MEDIUM_SIZE],
		"attack": 14,
		"defense": 14,
		"health": 80,
		"speed": 3,
		"stamina": 24,
		"cost": {"gold": 120, "wood": 60},
		"train_time": 40,
	},
}

static func units_for_building(building: String) -> Array:
	var result: Array = []
	for id in UNITS:
		if UNITS[id]["building"] == building:
			result.append(id)
	return result

static func train_time(unit_id: String, count: int) -> int:
	return maxi(roundi(int(UNITS[unit_id]["train_time"]) * count * TIME_SCALE), 1)

static func has_tag(unit_id: String, tag: StringName) -> bool:
	return tag in UNITS[unit_id]["tags"]

static func tags_text(unit_id: String) -> String:
	var parts: PackedStringArray = []
	for tag in UNITS[unit_id]["tags"]:
		parts.append(str(TAG_NAMES.get(tag, tag)))
	return ", ".join(parts)

static func stats_text(unit_id: String) -> String:
	var u: Dictionary = UNITS[unit_id]
	return "Атака %d · Защита %d · Здоровье %d\nСкорость %d · Выносливость %d" % [
		u["attack"], u["defense"], u["health"], u["speed"], u["stamina"]]
