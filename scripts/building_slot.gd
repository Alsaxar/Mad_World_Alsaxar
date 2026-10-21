class_name BuildingSlot
extends PanelContainer

@onready var name_label: Label = $Box/NameLabel
@onready var info_label: Label = $Box/InfoLabel
@onready var actions: VBoxContainer = $Box/Actions

var slot_id := ""
var slot_title := ""
var allowed_types: Array = []  # что здесь можно построить

var _last_state := ""

func setup(id: String, title: String, types: Array) -> void:
	slot_id = id
	slot_title = title
	allowed_types = types

func _ready() -> void:
	GameState.buildings_changed.connect(refresh)
	GameState.resources_changed.connect(refresh)
	GameState.second_tick.connect(_update_timer_text)
	refresh()

func _state_key() -> String:
	# всё, от чего зависит вид слота; сами числа ресурсов не входят,
	# входит только «хватает или нет», иначе слот перестраивался бы каждую секунду
	var parts: Array = [str(GameState.buildings.get(slot_id, {})),
			GameState.army, GameState.elite, GameState.wounded]
	for type: String in allowed_types:
		parts.append(GameState.can_afford(BuildingDB.BUILDINGS[type]["cost"]))
	parts.append_array([GameState.can_recruit(1), GameState.can_recruit(5),
			GameState.can_afford(GameState.SUMMON_COST), GameState.can_heal()])
	return str(parts)

func refresh() -> void:
	var key := _state_key()
	if key == _last_state:
		return
	_last_state = key

	for child in actions.get_children():
		child.queue_free()

	if GameState.is_under_construction(slot_id):
		var type: String = GameState.buildings[slot_id]["type"]
		name_label.text = "%s (строится)" % BuildingDB.BUILDINGS[type]["name"]
		_update_timer_text()
	elif GameState.has_building(slot_id):
		var type: String = GameState.buildings[slot_id]["type"]
		var level := GameState.building_level(slot_id)
		name_label.text = "%s (ур. %d)" % [BuildingDB.BUILDINGS[type]["name"], level]
		info_label.text = _info_text(type, level)
		_add_built_actions(type)
	else:
		name_label.text = slot_title
		info_label.text = "Пусто. Что построить?" if allowed_types.size() > 1 else "Не построено"
		for type: String in allowed_types:
			var cost: Dictionary = BuildingDB.BUILDINGS[type]["cost"]
			var text := "Построить: %s\n%s" % [BuildingDB.BUILDINGS[type]["name"], BuildingDB.format_cost(cost)]
			_add_action(text, GameState.build.bind(slot_id, type), GameState.can_afford(cost))

func _update_timer_text() -> void:
	if GameState.is_under_construction(slot_id):
		info_label.text = "Осталось: %s" % BuildingDB.format_time(GameState.time_left(slot_id))

func _info_text(type: String, level: int) -> String:
	match type:
		"barracks":
			return "Отряд: %d" % GameState.army
		"portal":
			return "Призванных стражей: %d" % GameState.elite
		"infirmary":
			return "Раненых: %d" % GameState.wounded
		"town_hall":
			return "Главное здание"
		"warehouse":
			return "Вместимость: %d" % GameState.resource_capacity("gold")
		_:
			return "Доход в день: %s" % BuildingDB.format_cost(BuildingDB.income_of(type, level))

func _add_built_actions(type: String) -> void:
	match type:
		"barracks":
			_add_action("Нанять 1\n%d золота" % GameState.RECRUIT_COST,
					GameState.recruit.bind(1), GameState.can_recruit(1))
			_add_action("Нанять 5\n%d золота" % (GameState.RECRUIT_COST * 5),
					GameState.recruit.bind(5), GameState.can_recruit(5))
		"portal":
			_add_action("Призвать стража\n%s" % BuildingDB.format_cost(GameState.SUMMON_COST),
					GameState.summon_elite, GameState.can_afford(GameState.SUMMON_COST))
		"infirmary":
			_add_action("Вылечить раненых\n%d золота за бойца" % GameState.HEAL_COST,
					GameState.heal_wounded, GameState.can_heal())
		# у ресурсных зданий кнопок пока нет: здесь появится «Улучшить»
	var next_level := GameState.building_level(slot_id) + 1
	var cost := GameState.upgrade_cost(slot_id)
	if not cost.is_empty():
		var text := "Улучшить до ур. %d\n%s" % [next_level, BuildingDB.format_cost(cost)]
		_add_action(text, GameState.upgrade_building.bind(slot_id), GameState.can_upgrade(slot_id))

#func _on_upgrade_pressed() -> void:
	#if GameState.upgrade_building(slot_id):
		#SaveManager.save_game()
		#refresh()
	#else:
		## можно показать сообщение «не хватает ресурсов»
		#pass

func _format_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	if int(cost.get("gold", 0)) > 0: parts.append("%d зол." % cost["gold"])
	if int(cost.get("wood", 0)) > 0: parts.append("%d дер." % cost["wood"])
	if int(cost.get("ore", 0)) > 0:  parts.append("%d руды" % cost["ore"])
	return ", ".join(parts)

func _add_action(text: String, action: Callable, enabled := true) -> void:
	var button := Button.new()
	button.text = text
	button.disabled = not enabled
	button.custom_minimum_size = Vector2(0, 90)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(_on_action_pressed.bind(action))
	actions.add_child(button)

func _on_action_pressed(action: Callable) -> void:
	action.call()
	SaveManager.save_game()
