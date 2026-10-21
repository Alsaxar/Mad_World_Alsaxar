class_name BuildingDB
extends RefCounted

const RES_NAMES := {"gold": "золото", "wood": "дерево", "ore": "руда"}

const BUILDINGS := {
	"town_hall": {"name": "Ратуша", "cost": {"gold": 70, "wood": 60}},
	"barracks": {"name": "Казармы", "cost": {"gold": 60, "wood": 30}},
	"portal": {"name": "Портал", "cost": {"gold": 100, "wood": 50, "ore": 30}},
	"infirmary": {"name": "Лазарет", "cost": {"gold": 60, "wood": 40}},
	"gold_mine": {"name": "Золотой рудник", "cost": {"wood": 50}, "income": {"gold": 20}},
	"sawmill": {"name": "Лесопилка", "cost": {"gold": 40}, "income": {"wood": 15}},
	"ore_mine": {"name": "Шахта руды", "cost": {"gold": 40, "wood": 20}, "income": {"ore": 10}},
	"warehouse":{"name":"Склад", "cost": {"gold": 80, "wood": 60}, "capacity_per_level": 500},
}

const SPECIAL_SLOTS := ["town_hall","barracks", "portal", "infirmary", "warehouse"]
const RESOURCE_TYPES := ["gold_mine", "sawmill", "ore_mine"]
#const RESOURCE_SLOT_COUNT := 12

const TIME_SCALE := 0.2  # для тестов 0.2, нормально - 1

# Время постройки первого уровня, секунды (потом поменять на минуты и часы)
const BUILD_TIMES := {
	"town_hall": 60, "barracks": 45, "portal": 90, "infirmary": 45,
	"warehouse": 40, "gold_mine": 30, "sawmill": 30, "ore_mine": 30,
}

static func format_cost(cost: Dictionary) -> String:
	var parts: PackedStringArray = []
	for res in cost:
		if int(cost[res]) > 0:
			parts.append("%s %d" % [RES_NAMES[res], int(cost[res])])
	return ", ".join(parts) if not parts.is_empty() else "—"

static func income_of(type: String, level: int) -> Dictionary:
	var result := {}
	var income: Dictionary = BUILDINGS[type].get("income", {})
	for res in income:
		result[res] = int(income[res]) * level
	return result

static func build_time(type: String, target_level: int) -> int:
	var base := int(BUILD_TIMES.get(type, 30))
	return maxi(roundi(base * target_level * TIME_SCALE), 1)

static func format_time(total_seconds: int) -> String:
	var total := maxi(total_seconds, 0)
	var hours := floori(total / 3600.0)
	var minutes := floori((total % 3600) / 60.0)
	var seconds := total % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, seconds]
	return "%02d:%02d" % [minutes, seconds]
