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
const RESOURCE_SLOT_COUNT := 12

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
