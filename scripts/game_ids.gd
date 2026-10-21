
class_name GameIds
extends RefCounted

# Фиксированные слоты домашнего экрана.
const SLOT_TOWN_HALL: StringName = &"town_hall"
const SLOT_BARRACKS: StringName = &"barracks"
const SLOT_PORTAL: StringName = &"portal"
const SLOT_INFIRMARY: StringName = &"infirmary"

# Типы зданий.
const BUILDING_TOWN_HALL: StringName = &"town_hall"
const BUILDING_BARRACKS: StringName = &"barracks"
const BUILDING_PORTAL: StringName = &"portal"
const BUILDING_INFIRMARY: StringName = &"infirmary"
const BUILDING_WAREHOUSE: StringName = &"warehouse"
const BUILDING_GOLD_MINE: StringName = &"gold_mine"
const BUILDING_SAWMILL: StringName = &"sawmill"
const BUILDING_ORE_MINE: StringName = &"ore_mine"

# Типы объектов глобальной карты.
const POI_GOLD_MINE: StringName = &"gold_mine"
const POI_BANDIT_CAMP: StringName = &"bandit_camp"
const POI_ALTAR: StringName = &"altar"

# Уникальные экземпляры уже размещённых объектов карты.
const POI_MINE_001: StringName = &"poi_gold_mine_001"
const POI_BANDIT_CAMP_001: StringName = &"poi_bandit_camp_001"
const POI_ALTAR_001: StringName = &"poi_altar_001"

const RESOURCE_SLOT_COUNT: int = 12 #Здесь задается количество ресурсных точек.

static func resource_slot_id(index: int) -> StringName:
	return StringName("resource_slot_%03d" % (index + 1))
